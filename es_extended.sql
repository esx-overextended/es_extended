CREATE DATABASE IF NOT EXISTS `es_extended`;

ALTER DATABASE `es_extended`
    DEFAULT CHARACTER SET UTF8MB4;
    
ALTER DATABASE `es_extended`
    DEFAULT COLLATE UTF8MB4_UNICODE_CI;


CREATE TABLE IF NOT EXISTS `users` (
    `identifier` VARCHAR(60) NOT NULL,
    `accounts` LONGTEXT NULL DEFAULT NULL,
    `group` VARCHAR(50) NULL DEFAULT 'user',
    `inventory` LONGTEXT NULL DEFAULT NULL,
    `job` VARCHAR(20) NULL DEFAULT 'unemployed',
    `job_grade` INT NULL DEFAULT 0,
    `job_duty` tinyint(1) NULL DEFAULT 0,
    `loadout` LONGTEXT NULL DEFAULT NULL,
    `metadata` LONGTEXT NULL DEFAULT NULL,
    `position` longtext NULL DEFAULT NULL,

    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `users` table which causes 'CREATE TABLE IF NOT EXISTS `users`' not to execute and apply the needed changes...
*/
ALTER TABLE `users`
ADD COLUMN IF NOT EXISTS `job_duty` tinyint(1) NULL DEFAULT 0 AFTER `job_grade`;


CREATE TABLE IF NOT EXISTS `items` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `weight` INT NOT NULL DEFAULT 1,
    `rare` TINYINT NOT NULL DEFAULT 0,
    `can_remove` TINYINT NOT NULL DEFAULT 1,

    PRIMARY KEY (`name`)
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS `jobs` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) DEFAULT NULL,
    `default_duty` tinyint(1) NOT NULL DEFAULT 0,

    PRIMARY KEY (`name`)
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `jobs` table which causes 'CREATE TABLE IF NOT EXISTS `jobs`' not to execute and apply the needed changes...
*/
ALTER TABLE `jobs`
ADD COLUMN IF NOT EXISTS `default_duty` tinyint(1) NOT NULL DEFAULT 0;

INSERT IGNORE INTO `jobs` VALUES ('unemployed', 'Unemployed', 0, 0);


CREATE TABLE IF NOT EXISTS `job_grades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `job_name` VARCHAR(50) DEFAULT NULL,
    `grade` INT NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `salary` INT NOT NULL,
    `skin_male` LONGTEXT NOT NULL,
    `skin_female` LONGTEXT NOT NULL,

    PRIMARY KEY (`id`)
) ENGINE=InnoDB;

INSERT IGNORE INTO `job_grades` VALUES (1, 'unemployed', 0, 'unemployed', 'Unemployed', 200, '{}', '{}');