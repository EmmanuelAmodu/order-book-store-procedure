USE `trading-desk`;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS wallets (
	id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    asset_name VARCHAR(10) NOT NULL,
    balance DECIMAL(18,8) NOT NULL,
    UNIQUE KEY (user_id, asset_name),
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pairs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    base_asset_name VARCHAR(10) NOT NULL,
    quote_asset_name VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_base_quote (base_asset_name, quote_asset_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    pair_id INT,
    type ENUM('ASK', 'BID') NOT NULL,
    status ENUM('PENDING', 'PARTIALLY_FILLED', 'FILLED', 'CANCELLED') NOT NULL,
    price DECIMAL(18,8) NOT NULL,
    amount DECIMAL(18,8) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_pair_type_status_created_at (pair_id, type, status, created_at),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (pair_id) REFERENCES pairs(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    match_id INT NOT NULL,
    amount DECIMAL(18,8) NOT NULL,
    price DECIMAL(18,8) NOT NULL,
    status ENUM('PENDING', 'PARTIALLY_FILLED', 'FILLED', 'CANCELLED') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (match_id) REFERENCES orders(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    wallet_id INT NOT NULL,
    amount DECIMAL(18,8) NOT NULL,
    type ENUM('RESERVE', 'TRADE') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES wallets(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    update_time_notification_sent TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

