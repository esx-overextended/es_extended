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
    `is_boss` tinyint(1) NOT NULL DEFAULT 0,

    PRIMARY KEY (`id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `user_groups` (
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,

    KEY `FK_user_groups_users` (`identifier`),
    CONSTRAINT `FK_user_groups_users` FOREIGN KEY (`identifier`) REFERENCES `users` (`identifier`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


DELIMITER //
DROP TRIGGER IF EXISTS insert_user_groups;

CREATE TRIGGER insert_user_groups
AFTER INSERT ON `users` FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `user_groups`.`identifier` = NEW.identifier AND `user_groups`.`name` = NEW.group
    ) THEN
        INSERT INTO `user_groups` (`identifier`, `name`, `grade`) VALUES (NEW.identifier, NEW.group, 0);
    END IF;
END //

DROP TRIGGER IF EXISTS update_user_groups;

CREATE TRIGGER update_user_groups
AFTER UPDATE ON `users` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `identifier` = NEW.identifier AND `name` = OLD.group
    ) THEN
        UPDATE `user_groups`
        SET `name` = NEW.group, `grade` = 0
        WHERE `identifier` = NEW.identifier AND `name` = OLD.group;
    ELSEIF NOT EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `user_groups`.`identifier` = NEW.identifier AND `user_groups`.`name` = NEW.group
    ) THEN
        INSERT INTO `user_groups` (`identifier`, `name`, `grade`) VALUES (NEW.identifier, NEW.group, 0);
    END IF;
END //
DELIMITER ;

-- insert data for existing rows from users table into user_groups table (after applying backup or for those who migrate from ESX Legacy)
INSERT IGNORE INTO `user_groups` (`identifier`, `name`, `grade`) SELECT `identifier`, `group`, 0 FROM `users`
WHERE NOT EXISTS (
    SELECT 1
    FROM `user_groups`
    WHERE `user_groups`.`identifier` = `users`.`identifier` AND `user_groups`.`name` = `users`.`group`
);


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
    `label` VARCHAR(50) NOT NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT 'CIV',
    `default_duty` tinyint(1) NOT NULL DEFAULT 0,

    PRIMARY KEY (`name`)
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `jobs` table which causes 'CREATE TABLE IF NOT EXISTS `jobs`' not to execute and apply the needed changes...
*/
ALTER TABLE `jobs`
ADD COLUMN IF NOT EXISTS `type` VARCHAR(50) NOT NULL DEFAULT 'CIV',
ADD COLUMN IF NOT EXISTS `default_duty` tinyint(1) NOT NULL DEFAULT 0;

INSERT IGNORE INTO `jobs` (`name`, `label`, `type`, `default_duty`) VALUES ('unemployed', 'Unemployed', 'CIV', 0);


CREATE TABLE IF NOT EXISTS `job_grades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `job_name` VARCHAR(50) DEFAULT NULL,
    `grade` INT NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(50) NOT NULL,
    `salary` INT NOT NULL DEFAULT 0,
    `offduty_salary` INT NOT NULL DEFAULT 0,
    `skin_male` LONGTEXT NOT NULL DEFAULT '{}',
    `skin_female` LONGTEXT NOT NULL DEFAULT '{}',

    PRIMARY KEY (`id`)
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `job_grades` table which causes 'CREATE TABLE IF NOT EXISTS `job_grades`' not to execute and apply the needed changes...
*/
ALTER TABLE `job_grades`
ADD COLUMN IF NOT EXISTS `offduty_salary` INT NOT NULL DEFAULT 0;

INSERT IGNORE INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `offduty_salary`, `skin_male`, `skin_female`) VALUES (1, 'unemployed', 0, 'unemployed', 'Unemployed', 0, 200, '{}', '{}');