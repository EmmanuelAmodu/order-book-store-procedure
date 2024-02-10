DELIMITER //

CREATE PROCEDURE CancelOrderAndUpdateWallet(
    IN p_order_id INT
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_pair_id INT;
    DECLARE v_amount DECIMAL(18,8);
    DECLARE v_price DECIMAL(18,8);
    DECLARE v_type ENUM('ASK', 'BID');
    DECLARE v_status ENUM('PENDING', 'PARTIALLY_FILLED', 'FILLED', 'CANCELLED');
    DECLARE v_base_asset_name VARCHAR(10);
    DECLARE v_quote_asset_name VARCHAR(10);
    DECLARE v_refund_amount DECIMAL(18,8);

    -- Start transaction
    START TRANSACTION;

    -- Check the current status of the order and retrieve its details
    SELECT user_id, pair_id, type, amount, price, status INTO v_user_id, v_pair_id, v_type, v_amount, v_price, v_status
    FROM orders WHERE id = p_order_id FOR UPDATE;

    -- Retrieve asset names based on pair_id
    SELECT base_asset_name, quote_asset_name INTO v_base_asset_name, v_quote_asset_name
    FROM pairs WHERE id = v_pair_id;

    -- Proceed only if the order is 'PENDING' or 'PARTIALLY_FILLED'
    IF v_status IN ('PENDING', 'PARTIALLY_FILLED') THEN
        -- Determine refund amount and asset name based on order type
        IF v_type = 'BID' THEN
            -- For BID orders, calculate refund in quote asset
            SET v_refund_amount = v_amount * v_price; -- Quote currency amount to refund
            UPDATE wallets
            SET balance = balance + v_refund_amount
            WHERE user_id = v_user_id AND asset_name = v_quote_asset_name;
        ELSE
            -- For ASK orders, refund the remaining base asset amount
            SET v_refund_amount = v_amount; -- Base currency amount to refund
            UPDATE wallets
            SET balance = balance + v_refund_amount
            WHERE user_id = v_user_id AND asset_name = v_base_asset_name;
        END IF;

        -- Mark the order as 'CANCELLED'
        UPDATE orders SET status = 'CANCELLED' WHERE id = p_order_id;
    ELSE
        -- If the order is already 'FILLED' or 'CANCELLED', cannot cancel
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order cannot be cancelled as it is already filled or previously cancelled.';
        LEAVE PROCEDURE;
    END IF;

    -- Commit transaction
    COMMIT;
END //

DELIMITER ;
