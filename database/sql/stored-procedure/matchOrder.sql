DELIMITER //

CREATE PROCEDURE matchOrders(
    IN p_order_id INT,
    IN p_type ENUM('ASK', 'BID'),
    IN p_pair_id VARCHAR(15),
    IN p_price DECIMAL(18,8),
    IN p_amount DECIMAL(18,8),
    OUT matched_amount DECIMAL(18,8),
    OUT executed_value DECIMAL(18,8)
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_user_id INT;
    DECLARE v_amount DECIMAL(18,8);
    DECLARE v_price DECIMAL(18,8);
    DECLARE done INT DEFAULT FALSE;

    -- Initialize output variables
    SET matched_amount = 0;
    SET executed_value = 0;

    -- Cursor to find matching orders based on FIFO
    DECLARE match_cursor CURSOR FOR
        SELECT id, user_id, amount, price FROM orders
        WHERE pair_id = p_pair_id
          AND type != p_type
          AND (status = 'PARTIALLY_FILLED' OR status = 'PENDING')
          AND ((p_type = 'ASK' AND price <= p_price) OR (p_type = 'BID' AND price >= p_price))
        ORDER BY created_at ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN match_cursor;

    match_loop: LOOP
        FETCH match_cursor INTO v_order_id, v_user_id, v_amount, v_price;
        IF done THEN
            LEAVE match_loop;
        END IF;

        SELECT amount INTO v_amount FROM orders WHERE id = v_order_id FOR UPDATE;
        -- Calculate matched amount and executed value for each order
        IF v_amount <= p_amount THEN
            -- Full match
            SET matched_amount = matched_amount + v_amount;
            SET executed_value = executed_value + (v_amount * v_price);
            SET p_amount = p_amount - v_amount;

            -- Update the matched order as FILLED
            UPDATE orders SET status = 'FILLED', amount = 0 WHERE id = v_order_id;
            INSERT INTO matches (order_id, match_id, amount, price, status) VALUES (v_order_id, p_order_id, v_amount, v_price, 'FILLED');
        ELSE
            -- Partial match
            SET matched_amount = matched_amount + p_amount;
            SET executed_value = executed_value + (p_amount * v_price);

            -- Update the matched order with the remaining amount
            UPDATE orders SET amount = amount - p_amount, status = 'PARTIALLY_FILLED' WHERE id = v_order_id;
            INSERT INTO matches (order_id, match_id, amount, price, status) VALUES (v_order_id, p_order_id, p_amount, v_price, 'PARTIALLY_FILLED');
            SET p_amount = 0;
        END IF;

        -- Check if the incoming order is fully matched
        IF p_amount = 0 THEN
            LEAVE match_loop;
        END IF;
    END LOOP;

    CLOSE match_cursor;
END //

DELIMITER ;
