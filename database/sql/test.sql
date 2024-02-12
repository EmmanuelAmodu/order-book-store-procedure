-- Create users
INSERT INTO users () VALUES (); -- user 1
INSERT INTO users () VALUES (); -- user 2
INSERT INTO users () VALUES (); -- user 3
INSERT INTO users () VALUES (); -- user 4
INSERT INTO users () VALUES (); -- user 5
INSERT INTO users () VALUES (); -- user 6
INSERT INTO users () VALUES (); -- user 7
INSERT INTO users () VALUES (); -- user 8
INSERT INTO users () VALUES (); -- user 9
INSERT INTO users () VALUES (); -- user 10

-- Create pairs
INSERT INTO pairs (base_asset_name, quote_asset_name) VALUES ('BTC', 'USDT');
-- INSERT INTO pairs (base_asset_name, quote_asset_name) VALUES ('ETH', 'USDT');

-- Create wallets
INSERT INTO wallets (user_id, asset_name, balance) VALUES (1, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (1, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (3, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (3, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (4, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (4, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (5, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (5, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (6, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (6, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (7, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (7, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (8, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (8, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (9, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (9, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (10, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (10, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (2, 'BTC', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (2, 'USDT', 1000000);

-- INSERT INTO wallets (user_id, asset_name, balance) VALUES (1, 'ETH', 100);
-- INSERT INTO wallets (user_id, asset_name, balance) VALUES (2, 'ETH', 0);

CALL CreateOrder(1, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(3, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(4, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(5, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(6, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(7, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(8, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(9, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(10, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(2, 1, 'BID', 40000, 10);

-- CALL CreateOrder(1, 2, 'ASK', 3000, 10);
-- CALL CreateOrder(2, 2, 'BID', 3000, 5);
