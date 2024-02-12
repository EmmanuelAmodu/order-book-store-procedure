-- Create users
INSERT INTO users () VALUES ();
INSERT INTO users () VALUES ();

-- Create pairs
INSERT INTO pairs (base_asset_name, quote_asset_name) VALUES ('BTC', 'USDT');
INSERT INTO pairs (base_asset_name, quote_asset_name) VALUES ('ETH', 'USDT');

-- Create wallets
INSERT INTO wallets (user_id, asset_name, balance) VALUES (1, 'BTC', 10);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (1, 'USDT', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (2, 'BTC', 0);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (2, 'USDT', 100000);

INSERT INTO wallets (user_id, asset_name, balance) VALUES (1, 'ETH', 100);
INSERT INTO wallets (user_id, asset_name, balance) VALUES (2, 'ETH', 0);

CALL CreateOrder(1, 1, 'ASK', 40000, 0.5);
CALL CreateOrder(2, 1, 'BID', 40000, 0.5);

CALL CreateOrder(1, 2, 'ASK', 3000, 10);
CALL CreateOrder(2, 2, 'BID', 3000, 5);
