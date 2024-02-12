USE `spot-trading`;

DELIMITER //

DROP PROCEDURE IF EXISTS CreateOrder;
CREATE PROCEDURE CreateOrder (
    IN p_user_id INT,
    IN p_pair_id INT,
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

    DECLARE v_error_message VARCHAR(255);

    -- Handler for SQL exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END;

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

    -- Insert the new order as PENDING
    INSERT INTO orders (user_id, pair_id, type, status, price, amount)
    VALUES (p_user_id, p_pair_id, p_type, 'PENDING', p_price, p_amount);
    SET v_order_id = LAST_INSERT_ID();

    -- Check if sufficient funds/quantity for order type
    IF p_type = 'BID' THEN
        IF v_quote_balance < v_total_cost THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds for bid order';
        END IF;
        -- Deduct from quote wallet (buying with quote currency)
        UPDATE wallets SET balance = balance - v_total_cost WHERE id = v_quote_wallet_id;
        -- Create Transaction Record for BID
        INSERT INTO transactions (wallet_id, order_id, amount, type) VALUES (v_quote_wallet_id, v_order_id, -v_total_cost, 'RESERVE');
        -- Attempt to match with ASK orders
        CALL MatchOrders(v_base_wallet_id, v_order_id, 'BID', p_pair_id, v_base_asset_name, v_quote_asset_name, p_price, p_amount);
    ELSE
        IF v_base_balance < p_amount THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient quantity for ask order';
        END IF;
        -- Deduct from base wallet (selling base currency)
        UPDATE wallets SET balance = balance - p_amount WHERE id = v_base_wallet_id;
        -- Create Transaction Record for ASK
        INSERT INTO transactions (wallet_id, order_id, amount, type) VALUES (v_base_wallet_id, v_order_id, -p_amount, 'RESERVE');
        -- Attempt to match with ASK orders
        CALL MatchOrders(v_quote_wallet_id, v_order_id, 'ASK', p_pair_id, v_base_asset_name, v_quote_asset_name, p_price, p_amount);
    END IF;

    -- Commit transaction
    COMMIT;
END //

DELIMITER ;
