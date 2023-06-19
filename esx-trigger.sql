ALTER DATABASE DEFAULT CHARACTER SET UTF8MB4;
ALTER DATABASE DEFAULT COLLATE UTF8MB4_UNICODE_CI;

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
END //
DELIMITER ;
