DELIMITER //

CREATE PROCEDURE createOrder(
    IN p_user_id INT,
    IN p_pair_id VARCHAR(15),
    IN p_type ENUM('ASK', 'BID'),
    IN p_price DECIMAL(18,8),
    IN p_amount DECIMAL(18,8)
)
BEGIN
    -- Variable Declarations
    DECLARE v_base_wallet_id INT;
    DECLARE v_quote_wallet_id INT;
    DECLARE v_base_balance DECIMAL(18,8);
    DECLARE v_quote_balance DECIMAL(18,8);
    DECLARE v_order_id INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_match_id INT;
    DECLARE v_match_amount DECIMAL(18,8);
    DECLARE v_match_price DECIMAL(18,8);
    DECLARE v_match_user_id INT;
    DECLARE v_total_cost DECIMAL(18,8);
    DECLARE v_base_asset_name VARCHAR(10);
    DECLARE v_quote_asset_name VARCHAR(10);

    DECLARE v_executed_amount DECIMAL(18,8) DEFAULT 0;
    DECLARE v_remaining_amount DECIMAL(18,8);
    DECLARE v_transaction_amount DECIMAL(18,8);

    -- Extract asset names from the pair
    SELECT base_asset_name, quote_asset_name INTO v_base_asset_name, v_quote_asset_name
    FROM pairs WHERE id = p_pair_id;

    -- Calculate total cost or value of the order
    SET v_total_cost = p_amount * p_price;

    -- Transaction Start
    START TRANSACTION;

    -- Lock and get base and quote wallet balances
    SELECT id, balance INTO v_base_wallet_id, v_base_balance
    FROM wallets
    WHERE user_id = p_user_id AND asset_name = v_base_asset_name FOR UPDATE;

    SELECT id, balance INTO v_quote_wallet_id, v_quote_balance
    FROM wallets
    WHERE user_id = p_user_id AND asset_name = v_quote_asset_name FOR UPDATE;

    -- Check if sufficient funds/quantity for order type
    IF p_type = 'BID' THEN
        IF v_quote_balance < v_total_cost THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds for bid order';
        END IF;
        -- Deduct from quote wallet (buying with quote currency)
        UPDATE wallets SET balance = balance - v_total_cost WHERE id = v_quote_wallet_id;
        INSERT INTO transactions (wallet_id, amount, type) VALUES (v_quote_wallet_id, -v_total_cost, 'RESERVE');
    ELSE
        IF v_base_balance < p_amount THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient quantity for ask order';
        END IF;
        -- Deduct from base wallet (selling base currency)
        UPDATE wallets SET balance = balance - p_amount WHERE id = v_base_wallet_id;
        INSERT INTO transactions (wallet_id, amount, type) VALUES (v_base_wallet_id, -p_amount, 'RESERVE');
    END IF;

    -- Insert the new order as PENDING
    INSERT INTO orders (user_id, pair_id, type, status, price, amount)
    VALUES (p_user_id, p_pair_id, p_type, 'PENDING', p_price, p_amount);
    SET v_order_id = LAST_INSERT_ID();

    -- Matching Logic
    IF p_type = 'BID' THEN
        -- Attempt to match with ASK orders
        CALL matchOrders(p_order_id, 'ASK', p_pair_id, p_price, p_amount, @matched_amount, @executed_value);
    ELSE
        -- Attempt to match with BID orders
        CALL matchOrders(p_order_id, 'BID', p_pair_id, p_price, p_amount, @matched_amount, @executed_value);
    END IF;

    -- Calculate remaining amount after attempting to match
    SET v_remaining_amount = p_amount - @matched_amount;

    -- Update the order based on the remaining amount
    IF v_remaining_amount > 0 THEN
        UPDATE orders SET amount = v_remaining_amount, status = 'PARTIALLY_FILLED' WHERE id = v_order_id;
    ELSE
        UPDATE orders SET status = 'FILLED' WHERE id = v_order_id;
    END IF;

    -- Update wallet based on executed amount
    IF p_type = 'BID' THEN
        -- For BID orders, update base asset balance (received)
        SET v_transaction_amount = @matched_amount;
        UPDATE wallets SET balance = balance + v_transaction_amount WHERE id = v_base_wallet_id;
        INSERT INTO transactions (wallet_id, amount, type) VALUES (v_base_wallet_id, v_transaction_amount, 'TRADE');
    ELSE
        -- For ASK orders, update quote asset balance (received)
        SET v_transaction_amount = @executed_value;
        UPDATE wallets SET balance = balance + v_transaction_amount WHERE id = v_quote_wallet_id;
        INSERT INTO transactions (wallet_id, amount, type) VALUES (v_quote_wallet_id, v_transaction_amount, 'TRADE');
    END IF;

    -- Commit transaction
    COMMIT;
END //

DELIMITER ;
