ALTER DATABASE DEFAULT CHARACTER SET UTF8MB4;
ALTER DATABASE DEFAULT COLLATE UTF8MB4_UNICODE_CI;

/* USER */
CREATE TABLE IF NOT EXISTS `users` (
    `identifier` VARCHAR(60) NOT NULL,
    `cid` VARCHAR(60) NOT NULL,
    `accounts` LONGTEXT NULL DEFAULT NULL,
    `group` VARCHAR(50) NULL DEFAULT "user",
    `job` VARCHAR(20) NULL DEFAULT "unemployed",
    `job_grade` INT NULL DEFAULT 0,
    `job_duty` TINYINT(1) NULL DEFAULT 0,
    `inventory` LONGTEXT NULL DEFAULT NULL,
    `loadout` LONGTEXT NULL DEFAULT NULL,
    `skin` LONGTEXT NULL DEFAULT NULL,
    `metadata` LONGTEXT NULL DEFAULT NULL,
    `position` LONGTEXT NULL DEFAULT NULL,

    PRIMARY KEY (`identifier`),
    UNIQUE INDEX `cid` (`cid`),
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `users` table which causes "CREATE TABLE IF NOT EXISTS `users`" not to execute and apply the needed changes...
*/
ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `job_duty` TINYINT(1) NULL DEFAULT 0 AFTER `job_grade`,
    ADD COLUMN IF NOT EXISTS `skin` LONGTEXT NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `cid` VARCHAR(60) NOT NULL AFTER `identifier`,
    ADD UNIQUE INDEX IF NOT EXISTS `cid` (`cid`);


/* ITEM */
CREATE TABLE IF NOT EXISTS `items` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `weight` INT NOT NULL DEFAULT 1,
    `rare` TINYINT NOT NULL DEFAULT 0,
    `can_remove` TINYINT NOT NULL DEFAULT 1,

    PRIMARY KEY (`name`)
) ENGINE=InnoDB;


/* JOB */
CREATE TABLE IF NOT EXISTS `jobs` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT "CIV",
    `default_duty` TINYINT(1) NOT NULL DEFAULT 0,

    PRIMARY KEY (`name`)
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `jobs` table which causes "CREATE TABLE IF NOT EXISTS `jobs`" not to execute and apply the needed changes...
*/
ALTER TABLE `jobs`
    ADD COLUMN IF NOT EXISTS `type` VARCHAR(50) NOT NULL DEFAULT "CIV",
    ADD COLUMN IF NOT EXISTS `default_duty` TINYINT(1) NOT NULL DEFAULT 0;

INSERT IGNORE INTO `jobs` (`name`, `label`, `type`, `default_duty`) VALUES ("unemployed", "Unemployed", "CIV", 0);


CREATE TABLE IF NOT EXISTS `job_grades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `job_name` VARCHAR(50) DEFAULT NULL,
    `grade` INT NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `salary` INT NOT NULL DEFAULT 0,
    `offduty_salary` INT NOT NULL DEFAULT 0,
    `skin_male` LONGTEXT NOT NULL DEFAULT "{}",
    `skin_female` LONGTEXT NOT NULL DEFAULT "{}",

    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_job_name_grade` (`job_name`, `grade`)
) ENGINE=InnoDB;

ALTER TABLE `job_grades`
    ADD UNIQUE KEY IF NOT EXISTS `unique_job_name_grade` (`job_name`, `grade`);

/*
for anyone who is migrating from ESX Legacy and already have `job_grades` table which causes "CREATE TABLE IF NOT EXISTS `job_grades`" not to execute and apply the needed changes...
*/
ALTER TABLE `job_grades`
    ADD COLUMN IF NOT EXISTS `offduty_salary` INT NOT NULL DEFAULT 0;

INSERT IGNORE INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `offduty_salary`, `skin_male`, `skin_female`) VALUES (1, "unemployed", 0, "unemployed", "Unemployed", 0, 200, "{}", "{}");


/* GROUP */
CREATE TABLE IF NOT EXISTS `groups` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,

    PRIMARY KEY (`name`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `group_grades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `group_name` VARCHAR(50) DEFAULT NULL,
    `grade` INT NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `is_boss` TINYINT(1) NOT NULL DEFAULT 0,

    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_group_name_grade` (`group_name`, `grade`)
) ENGINE=InnoDB;

ALTER TABLE `group_grades`
    ADD UNIQUE KEY IF NOT EXISTS `unique_group_name_grade` (`group_name`, `grade`);


CREATE TABLE IF NOT EXISTS `user_groups` (
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,

    UNIQUE KEY `unique_identifier_name` (`identifier`, `name`),
    KEY `FK_user_groups_users` (`identifier`),
    CONSTRAINT `FK_user_groups_users` FOREIGN KEY (`identifier`) REFERENCES `users` (`identifier`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

ALTER TABLE `user_groups`
    ADD UNIQUE KEY IF NOT EXISTS `unique_identifier_name` (`identifier`, `name`);

-- insert data for existing rows from users table into user_groups table (after applying backup or for those who migrate from ESX Legacy)
INSERT INTO `user_groups` (`identifier`, `name`, `grade`) SELECT `identifier`, `group`, 0 FROM `users` ON DUPLICATE KEY UPDATE `grade` = 0;


/* VEHICLE */
CREATE TABLE IF NOT EXISTS `owned_vehicles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(60) NULL DEFAULT NULL,
    `plate` CHAR(8) NOT NULL DEFAULT "",
    `vin` CHAR(17) NULL DEFAULT NULL,
    `type` VARCHAR(20) NOT NULL DEFAULT "car",
    `job` VARCHAR(50) NULL DEFAULT NULL,
    `model` VARCHAR(20) NULL DEFAULT NULL,
    `class` TINYINT NULL DEFAULT NULL,
    `stored` TINYINT(1) NULL DEFAULT NULL,
    `vehicle` LONGTEXT NULL DEFAULT NULL,
    `metadata` LONGTEXT NULL DEFAULT NULL,

    PRIMARY KEY (`id`),
    UNIQUE INDEX `plate` (`plate`),
    UNIQUE INDEX `vin` (`vin`),
    INDEX `FK_owned_vehicles_users` (`owner`),
    CONSTRAINT `FK_owned_vehicles_users` FOREIGN KEY (`owner`) REFERENCES `users` (`identifier`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `owned_vehicles` table which causes "CREATE TABLE IF NOT EXISTS `owned_vehicles`" not to execute and apply the needed changes...
*/
ALTER TABLE `owned_vehicles`
    MODIFY COLUMN IF EXISTS `id` INT NOT NULL AUTO_INCREMENT,
    ADD COLUMN IF NOT EXISTS `id` INT NOT NULL AUTO_INCREMENT FIRST,

    MODIFY COLUMN IF EXISTS `owner` VARCHAR(60) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `owner` VARCHAR(60) NULL DEFAULT NULL AFTER `id`,

    MODIFY COLUMN IF EXISTS `plate` CHAR(8) NOT NULL DEFAULT "",
    ADD COLUMN IF NOT EXISTS `plate` CHAR(8) NOT NULL DEFAULT "" AFTER `owner`,

    MODIFY COLUMN IF EXISTS `vin` CHAR(17) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `vin` CHAR(17) NULL DEFAULT NULL AFTER `plate`,

    MODIFY COLUMN IF EXISTS `type` VARCHAR(20) NOT NULL DEFAULT "car",
    ADD COLUMN IF NOT EXISTS `type` VARCHAR(20) NOT NULL DEFAULT "car" AFTER `vin`,

    MODIFY COLUMN IF EXISTS `job` VARCHAR(50) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `job` VARCHAR(50) NULL DEFAULT NULL AFTER `type`,

    MODIFY COLUMN IF EXISTS `model` VARCHAR(20) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `model` VARCHAR(20) NULL DEFAULT NULL AFTER `job`,

    MODIFY COLUMN IF EXISTS `class` TINYINT NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `class` TINYINT NULL DEFAULT NULL AFTER `model`,

    MODIFY COLUMN IF EXISTS `stored` TINYINT(1) NULL DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `stored` TINYINT(1) NULL DEFAULT NULL AFTER `class`,

    MODIFY COLUMN IF EXISTS `vehicle` LONGTEXT NULL DEFAULT "{}",
    ADD COLUMN IF NOT EXISTS `vehicle` LONGTEXT NULL DEFAULT "{}" AFTER `stored`,

    MODIFY COLUMN IF EXISTS `metadata` LONGTEXT NULL DEFAULT "{}",
    ADD COLUMN IF NOT EXISTS `metadata` LONGTEXT NULL DEFAULT "{}" AFTER `metadata`,

    DROP PRIMARY KEY,
    DROP FOREIGN KEY IF EXISTS `FK_owned_vehicles_users`,
    DROP FOREIGN KEY IF EXISTS `FK_owned_vehicles_groups`,

    ADD PRIMARY KEY (`id`),
    ADD UNIQUE INDEX IF NOT EXISTS `plate` (`plate`),
    ADD UNIQUE INDEX IF NOT EXISTS `vin` (`vin`),

    ADD INDEX IF NOT EXISTS `owner` (`owner`);