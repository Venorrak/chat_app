DROP DATABASE IF EXISTS chat_app;

CREATE DATABASE chat_app;

CREATE USER IF NOT EXISTS 'chat'@'localhost' IDENTIFIED BY 'jsp';
GRANT ALL ON *.* TO 'chat'@'localhost';

USE chat_app;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE users_pfp (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    pfp_url VARCHAR(400) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);