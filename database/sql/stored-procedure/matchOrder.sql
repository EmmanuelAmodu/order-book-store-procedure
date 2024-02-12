USE `spot-trading`;

DELIMITER //

DROP PROCEDURE IF EXISTS MatchOrders;
CREATE PROCEDURE MatchOrders(
    IN p_wallet_id INT,
    IN p_order_id INT,
    IN p_type ENUM('ASK', 'BID'),
    IN p_pair_id INT,
    IN p_base_asset_name VARCHAR(10),
    IN p_quote_asset_name VARCHAR(10),
    IN p_price DECIMAL(18,8),
    IN p_amount DECIMAL(18,8)
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_user_id INT;
    DECLARE v_amount DECIMAL(18,8);
    DECLARE v_price DECIMAL(18,8);
    DECLARE v_wallet_id INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE matched_amount DECIMAL(18,8);
    DECLARE executed_value DECIMAL(18,8);
    
    -- Cursor declaration
    DECLARE match_cursor CURSOR FOR
        SELECT id FROM orders
        WHERE pair_id = p_pair_id
          AND id <> p_order_id
          AND type != p_type
          AND (status = 'PARTIALLY_FILLED' OR status = 'PENDING')
          AND ((p_type = 'ASK' AND price <= p_price) OR (p_type = 'BID' AND price >= p_price))
        ORDER BY created_at ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN match_cursor;

    match_loop: LOOP
        FETCH match_cursor INTO v_order_id;
        IF done THEN
            LEAVE match_loop;
        END IF;

        SELECT user_id, amount, price INTO v_user_id, v_amount, v_price FROM orders WHERE id = v_order_id FOR UPDATE;

        -- Initialize output variables
        SET matched_amount = 0;
        SET executed_value = 0;

        -- Calculate matched amount and executed value for each order
        IF v_amount <= p_amount THEN
            -- Full match
            SET matched_amount = v_amount;
            SET executed_value = v_amount * v_price;
            SET p_amount = p_amount - v_amount;
        ELSE
            -- Partial match
            SET matched_amount = p_amount;
            SET executed_value = p_amount * v_price;
            SET p_amount = 0;
        END IF;

        -- Update the matched order as FILLED or PARTIALLY_FILLED
        UPDATE orders SET status = IF(v_amount <= p_amount, 'FILLED', 'PARTIALLY_FILLED'), amount = amount - matched_amount WHERE id = v_order_id;
        INSERT INTO matches (order_id, match_id, amount, price, status) VALUES (p_order_id, v_order_id, matched_amount, v_price, IF(v_amount <= p_amount, 'FILLED', 'PARTIALLY_FILLED'));

        IF p_type = 'ASK' THEN
            -- For BID orders, the creator buys the base asset, Credit the creator's base asset wallet
            -- CALL UpdateWalletBalanceOnMatch(p_order_id, v_order_id, v_user_id, 'BID', matched_amount, executed_value, p, v_quote_asset_name);
            SELECT id INTO v_wallet_id FROM wallets WHERE user_id = v_user_id AND asset_name = p_base_asset_name;

            -- Log debug info
            INSERT INTO logs (message) VALUES (CONCAT(
                'Matched ASK order: ', v_order_id,
                ' with BID order: ', p_order_id,
                ' for amount: ', matched_amount,
                ' for v_amount: ', v_amount,
                ' executed price: ', executed_value,
                ' at price: ', v_price));

            -- Log Transaction for Buyer (Receiving Quote Asset)
            UPDATE wallets SET balance = balance + matched_amount WHERE id = v_wallet_id; 
            INSERT INTO transactions (wallet_id, order_id, amount, type)
            VALUES (v_wallet_id, v_order_id, matched_amount, 'TRADE');

            -- Log transaction for seller (Receiving Base Asset)
            UPDATE wallets SET balance = balance + executed_value WHERE id = p_wallet_id;
            INSERT INTO transactions (wallet_id, order_id, amount, type)
            VALUES (p_wallet_id, v_order_id, executed_value, 'TRADE');
        ELSE
            -- For ASK orders, the creator sells the base asset, Credit the buyer's base asset wallet
            -- CALL UpdateWalletBalanceOnMatch(p_order_id, v_order_id, v_user_id, 'ASK', matched_amount, executed_value, p, v_quote_asset_name);
            SELECT id INTO v_wallet_id FROM wallets WHERE user_id = v_user_id AND asset_name = p_quote_asset_name;

            -- Log debug info
            INSERT INTO logs (message) VALUES (CONCAT(
                'Matched BID order: ', v_order_id,
                ' with ASK order: ', p_order_id,
                ' for amount: ', matched_amount,
                ' for v_amount: ', v_amount,
                ' for executed_value: ', executed_value,
                ' at price: ', v_price));
            
            -- Log Transaction for Buyer (Receiving Base Asset)
            UPDATE wallets SET balance = balance + executed_value WHERE id = v_wallet_id;
            INSERT INTO transactions (wallet_id, order_id, amount, type)
            VALUES (v_wallet_id, v_order_id, executed_value, 'TRADE');

            -- Log transaction for seller (Receiving Quote Asset)
            UPDATE wallets SET balance = balance + matched_amount WHERE id = p_wallet_id;
            INSERT INTO transactions (wallet_id, order_id, amount, type)
            VALUES (p_wallet_id, v_order_id, matched_amount, 'TRADE');
        END IF;

        -- Check if the incoming order is fully matched
        IF p_amount = 0 THEN
            LEAVE match_loop;
        END IF;
    END LOOP;

    CLOSE match_cursor;

    IF matched_amount > 0 THEN
        IF p_amount > 0 THEN
            -- No more matching orders, update the current order as PARTIALLY_FILLED
            UPDATE orders SET amount = p_amount, status = 'PARTIALLY_FILLED' WHERE id = p_order_id;
        ELSE
            -- Update the current order as FILLED
            UPDATE orders SET amount = p_amount, status = 'FILLED' WHERE id = p_order_id;
        END IF;
    END IF;
    
END //

DELIMITER ;
