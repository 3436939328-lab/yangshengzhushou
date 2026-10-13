package org.example.springbootdemo.rewards;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class RewardsSchemaInitializer implements CommandLineRunner {
    private final JdbcTemplate jdbc;

    public RewardsSchemaInitializer(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void run(String... args) {
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS reward_account (
                    user_id BIGINT PRIMARY KEY,
                    balance INT NOT NULL DEFAULT 0,
                    reserved INT NOT NULL DEFAULT 0
                ) ENGINE=InnoDB
                """);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS reward_ledger (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT NOT NULL,
                    delta INT NOT NULL,
                    entry_type VARCHAR(32) NOT NULL,
                    reference_id VARCHAR(100) NOT NULL,
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, entry_type, reference_id)
                ) ENGINE=InnoDB
                """);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS reward_chat (
                    user_id BIGINT NOT NULL,
                    request_id VARCHAR(100) NOT NULL,
                    payload_hash VARCHAR(64) NOT NULL,
                    status VARCHAR(20) NOT NULL,
                    reply_json TEXT,
                    error_message VARCHAR(255),
                    expires_at TIMESTAMP NOT NULL,
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY(user_id, request_id)
                ) ENGINE=InnoDB
                """);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS reward_product (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(100) NOT NULL,
                    description VARCHAR(1000) NOT NULL,
                    image_url VARCHAR(1000) NOT NULL,
                    points INT NOT NULL,
                    stock INT NOT NULL,
                    active BOOLEAN NOT NULL
                ) ENGINE=InnoDB
                """);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS reward_order (
                    id VARCHAR(36) PRIMARY KEY,
                    user_id BIGINT NOT NULL,
                    request_id VARCHAR(100) NOT NULL,
                    product_id BIGINT NOT NULL,
                    product_name VARCHAR(100) NOT NULL,
                    points INT NOT NULL,
                    recipient VARCHAR(80) NOT NULL,
                    phone VARCHAR(32) NOT NULL,
                    address VARCHAR(500) NOT NULL,
                    status VARCHAR(20) NOT NULL,
                    carrier VARCHAR(100),
                    tracking_number VARCHAR(100),
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, request_id)
                ) ENGINE=InnoDB
                """);
    }
}
