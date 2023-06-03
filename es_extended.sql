CREATE DATABASE IF NOT EXISTS `es_extended`;

ALTER DATABASE `es_extended` DEFAULT CHARACTER SET UTF8MB4;
    
ALTER DATABASE `es_extended` DEFAULT COLLATE UTF8MB4_UNICODE_CI;


/* USER */
CREATE TABLE IF NOT EXISTS `users` (
    `identifier` VARCHAR(60) NOT NULL,
    `accounts` LONGTEXT NULL DEFAULT NULL,
    `group` VARCHAR(50) NULL DEFAULT "user",
    `inventory` LONGTEXT NULL DEFAULT NULL,
    `job` VARCHAR(20) NULL DEFAULT "unemployed",
    `job_grade` INT NULL DEFAULT 0,
    `job_duty` TINYINT(1) NULL DEFAULT 0,
    `loadout` LONGTEXT NULL DEFAULT NULL,
    `metadata` LONGTEXT NULL DEFAULT NULL,
    `position` LONGTEXT NULL DEFAULT NULL,

    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB;

/*
for anyone who is migrating from ESX Legacy and already have `users` table which causes "CREATE TABLE IF NOT EXISTS `users`" not to execute and apply the needed changes...
*/
ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `job_duty` TINYINT(1) NULL DEFAULT 0 AFTER `job_grade`;


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


DELIMITER //
DROP TRIGGER IF EXISTS insert_user_groups;

CREATE TRIGGER insert_user_groups
AFTER INSERT ON `users` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `identifier` = NEW.identifier AND `name` = NEW.group
    ) THEN
        UPDATE `user_groups` SET `grade` = 0 WHERE `identifier` = NEW.identifier AND `name` = NEW.group;
    ELSE
        INSERT INTO `user_groups` (`identifier`, `name`, `grade`) VALUES (NEW.identifier, NEW.group, 0);
    END IF;

    /*IF EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `identifier` = NEW.identifier AND `name` = NEW.job
    ) THEN
        UPDATE `user_groups` SET `grade` = NEW.job_grade WHERE `identifier` = NEW.identifier AND `name` = NEW.job;
    ELSE
        INSERT INTO `user_groups` (`identifier`, `name`, `grade`) VALUES (NEW.identifier, NEW.job, NEW.job_grade);
    END IF;*/
END //

DROP TRIGGER IF EXISTS update_user_groups;

CREATE TRIGGER update_user_groups
AFTER UPDATE ON `users` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `identifier` = OLD.identifier AND `name` = OLD.group
    ) THEN
        UPDATE `user_groups` SET `identifier` = NEW.identifier, `name` = NEW.group, `grade` = 0 WHERE `identifier` = OLD.identifier AND `name` = OLD.group;
    ELSE
        IF EXISTS (
            SELECT 1
            FROM `user_groups`
            WHERE `identifier` = NEW.identifier AND `name` = NEW.group
        ) THEN
            UPDATE `user_groups` SET `identifier` = NEW.identifier, `name` = NEW.group, `grade` = 0 WHERE `identifier` = NEW.identifier AND `name` = NEW.group;
        ELSE
            INSERT INTO `user_groups` (`identifier`, `name`, `grade`) VALUES (NEW.identifier, NEW.group, 0);
        END IF;
    END IF;

    /*IF EXISTS (
        SELECT 1
        FROM `user_groups`
        WHERE `identifier` = OLD.identifier AND `name` = OLD.job
    ) THEN
        UPDATE `user_groups` SET `identifier` = NEW.identifier, `name` = NEW.job, `grade` = NEW.job_grade WHERE `identifier` = OLD.identifier AND `name` = OLD.job;
    ELSE
        IF EXISTS (
            SELECT 1
            FROM `user_groups`
            WHERE `identifier` = NEW.identifier AND `name` = NEW.job
        ) THEN
            UPDATE `user_groups` SET `identifier` = NEW.identifier, `name` = NEW.job, `grade` = NEW.job_grade WHERE `identifier` = NEW.identifier AND `name` = NEW.job;
        ELSE
            INSERT INTO `user_groups` (`identifier`, `name`, `grade`) VALUES (NEW.identifier, NEW.job, NEW.job_grade);
        END IF;
    END IF;*/
END //
DELIMITER ;

-- insert data for existing rows from users table into user_groups table (after applying backup or for those who migrate from ESX Legacy)
INSERT INTO `user_groups` (`identifier`, `name`, `grade`) SELECT `identifier`, `group`, 0 FROM `users` ON DUPLICATE KEY UPDATE `grade` = 0;

/*
-- insert data for existing rows from users table into user_groups table (after applying backup or for those who migrate from ESX Legacy)
INSERT INTO `user_groups` (`identifier`, `name`, `grade`) SELECT `identifier`, `job`, `job_grade` AS `grade` FROM `users` ON DUPLICATE KEY UPDATE `grade` = VALUES(`grade`);


DELIMITER //
DROP TRIGGER IF EXISTS insert_groups;

CREATE TRIGGER insert_groups
AFTER INSERT ON `jobs` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `groups`
        WHERE `name` = NEW.name
    ) THEN
        UPDATE `groups` SET `label` = NEW.label WHERE `name` = NEW.name;
    ELSE
        INSERT INTO `groups` (`name`, `label`) VALUES (NEW.name, NEW.label);
    END IF;
END //

DROP TRIGGER IF EXISTS update_groups;

CREATE TRIGGER update_groups
AFTER UPDATE ON `jobs` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `groups`
        WHERE `name` = OLD.name
    ) THEN
        UPDATE `groups` SET `name` = NEW.name, `label` = NEW.label WHERE `name` = OLD.name;
    ELSE
        IF EXISTS (
            SELECT 1
            FROM `groups`
            WHERE `name` = NEW.name
        ) THEN
            UPDATE `groups` SET `name` = NEW.name, `label` = NEW.label WHERE `name` = NEW.name;
        ELSE
            INSERT INTO `groups` (`name`, `label`) VALUES (NEW.name, NEW.label);
        END IF;
    END IF;
END //

DROP TRIGGER IF EXISTS delete_groups;

CREATE TRIGGER delete_groups
AFTER DELETE ON `jobs` FOR EACH ROW
BEGIN
    DELETE FROM `groups` WHERE `name` = OLD.name;
END //
DELIMITER ;

DELIMITER //
DROP TRIGGER IF EXISTS insert_group_grades;

CREATE TRIGGER insert_group_grades
AFTER INSERT ON `job_grades` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `group_grades`
        WHERE `group_name` = NEW.job_name AND `grade` = NEW.grade
    ) THEN
        UPDATE `group_grades` SET `label` = NEW.label, `is_boss` = IF(NEW.name = "boss", 1, 0) WHERE `group_name` = NEW.job_name AND `grade` = NEW.grade;
    ELSE
        INSERT INTO `group_grades` (`group_name`, `grade`, `label`, `is_boss`) VALUES (NEW.job_name, NEW.grade, NEW.label, IF(NEW.name = "boss", 1, 0));
    END IF;
END //

DROP TRIGGER IF EXISTS update_group_grades;

CREATE TRIGGER update_group_grades
AFTER UPDATE ON `job_grades` FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM `group_grades`
        WHERE `group_name` = OLD.job_name AND `grade` = OLD.grade
    ) THEN
        UPDATE `group_grades` SET `group_name` = NEW.job_name, `grade` = NEW.grade, `label` = NEW.label, `is_boss` = IF(NEW.name = "boss", 1, 0) WHERE `group_name` = OLD.job_name AND `grade` = OLD.grade;
    ELSE
        IF EXISTS (
            SELECT 1
            FROM `group_grades`
            WHERE `group_name` = NEW.job_name AND `grade` = NEW.grade
        ) THEN
            UPDATE `group_grades` SET `group_name` = NEW.job_name, `grade` = NEW.grade, `label` = NEW.label, `is_boss` = IF(NEW.name = "boss", 1, 0) WHERE `group_name` = NEW.job_name AND `grade` = NEW.grade;
        ELSE
            INSERT INTO `group_grades` (`group_name`, `grade`, `label`, `is_boss`) VALUES (NEW.job_name, NEW.grade, NEW.label, IF(NEW.name = "boss", 1, 0));
        END IF;
    END IF;
END //

DROP TRIGGER IF EXISTS delete_group_grades;

CREATE TRIGGER delete_group_grades
AFTER DELETE ON `job_grades` FOR EACH ROW
BEGIN
    DELETE FROM `group_grades` WHERE `group_name` = OLD.job_name;
END //
DELIMITER ;

-- insert data for existing rows from jobs table into groups table
INSERT INTO `groups` (`name`, `label`) SELECT `name`, `label` FROM `jobs` ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- insert data for existing rows from job_grades table into group_grades table
INSERT INTO `group_grades` (`group_name`, `grade`, `label`, `is_boss`) SELECT `job_name`, `grade`, `label`, IF(`name` = "boss", 1, 0) AS `is_boss` FROM `job_grades` ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `is_boss` = VALUES(`is_boss`);
*/

/* VEHICLE */
CREATE TABLE IF NOT EXISTS `owned_vehicles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(60) NULL DEFAULT NULL,
    `plate` CHAR(8) NOT NULL DEFAULT "",
    `vin` CHAR(17) NOT NULL,
    `type` VARCHAR(20) NOT NULL DEFAULT "car",
    `job` VARCHAR(50) NULL DEFAULT NULL,
    `model` VARCHAR(20) NOT NULL,
    `class` TINYINT(1) NULL DEFAULT NULL,
    `stored` TINYINT(1) NULL DEFAULT NULL,
    `vehicle` LONGTEXT NULL DEFAULT NULL,
    `metadata` LONGTEXT NULL DEFAULT NULL,

    PRIMARY KEY (`id`),
    UNIQUE INDEX `plate` (`plate`),
    UNIQUE INDEX `vin` (`vin`),
    INDEX `FK_owned_vehicles_users` (`owner`),
    CONSTRAINT `FK_owned_vehicles_users` FOREIGN KEY (`owner`) REFERENCES `users` (`identifier`) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `FK_owned_vehicles_groups` FOREIGN KEY (`job`) REFERENCES `groups` (`name`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

ALTER TABLE `owned_vehicles`
    ADD COLUMN IF NOT EXISTS `id` INT NOT NULL AUTO_INCREMENT FIRST,
    ADD COLUMN IF NOT EXISTS `vin` CHAR(17) NOT NULL AFTER `plate`,
    ADD COLUMN IF NOT EXISTS `model` VARCHAR(20) NOT NULL AFTER `job`,
    ADD COLUMN IF NOT EXISTS `class` TINYINT(1) NULL DEFAULT NULL AFTER `model`,
    MODIFY COLUMN `vehicle` LONGTEXT NULL DEFAULT "{}",
    ADD COLUMN IF NOT EXISTS `metadata` LONGTEXT NULL DEFAULT "{}",

    DROP PRIMARY KEY,
    DROP FOREIGN KEY IF EXISTS `FK_owned_vehicles_users`,
    DROP FOREIGN KEY IF EXISTS `FK_owned_vehicles_groups`,

    ADD PRIMARY KEY (`id`),
    ADD UNIQUE INDEX IF NOT EXISTS `plate` (`plate`),
    ADD UNIQUE INDEX IF NOT EXISTS `vin` (`vin`);
-- These two ALTERs *cannot* join with each other as it produces error    
ALTER TABLE `owned_vehicles`
    ADD INDEX IF NOT EXISTS `FK_owned_vehicles_users` (`owner`),
    ADD CONSTRAINT `FK_owned_vehicles_users` FOREIGN KEY (`owner`) REFERENCES `users` (`identifier`) ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT `FK_owned_vehicles_groups` FOREIGN KEY (`job`) REFERENCES `groups` (`name`) ON UPDATE CASCADE ON DELETE CASCADE;