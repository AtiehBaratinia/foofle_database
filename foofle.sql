-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 20, 2020 at 06:18 PM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.4.5

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `foofle`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_user` (IN `username` VARCHAR(20), IN `address` VARCHAR(512), IN `name` VARCHAR(20), IN `lastname` VARCHAR(50), IN `birthdate` DATE, IN `nickname` VARCHAR(20), IN `phone` VARCHAR(15), IN `id` VARCHAR(15), IN `related_phone` VARCHAR(20), IN `passw` VARCHAR(20), OUT `message` VARCHAR(200))  BEGIN
START TRANSACTION;
IF (username IS Null OR username="" OR address='' OR name IS NULL OR lastname IS NULL OR lastname='' OR nickname IS NULL OR nickname='' OR birthdate IS NULL OR birthdate='' OR
phone IS NULL or phone='' OR id IS NULL or id='' OR related_phone IS NULL or related_phone='' OR passw IS NULL or passw='')
THEN

SET message = "you should fill all the fields correctly!";

ELSE
BEGIN
	IF EXISTS (SELECT system_info.username FROM 	system_info WHERE system_info.username = 		username) THEN
    set message = "Another account with this username already exists";
    ELSEIF LENGTH(username) < 6 THEN
    	SET message = "The length of username should be at least 6.";
    ELSEIF LENGTH(passw) < 6 THEN
    	SET message = "The length of password should be at least 6.";
    ELSEIF (NOT (phone REGEXP '^[0-9]+$')) OR (NOT (related_phone REGEXP '^[0-9]+$')) OR (NOT (id REGEXP '^[0-9]+$')) THEN
    	SET message = "phone and related_phone and id should be integers!";
    ELSE
    BEGIN
    	SET passw = MD5(passw);
		INSERT INTO personal_info(username, 			address, firstname, lastname, nickname, 		birthdate, phone, id) VALUES(username,
                                address,
                                name,
                                lastname,
                				nickname,                                           birthdate, 			phone, id);
                              
		INSERT INTO system_info(username, 				passwrd, related_phone) VALUES 	  			   (username,passw, related_phone);
		SET message = "account was created";
        INSERT INTO notification(owner_user,body) VALUES (username, "welcome to foofle mail!");
	END;
	end if;
END;


END IF;
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_account` ()  BEGIN
	CALL get_last_user(@user);
    
    DELETE FROM personal_info WHERE personal_info.username = @user;
    DELETE FROM specific_allow WHERE specific_allow.target_username = @user OR specific_allow.username = @user;
    DELETE FROM notification WHERE notification.owner_user = @user;
    DELETE FROM receiver_email WHERE receiver_email.receiver_user = @user;
    DELETE FROM receiver_email WHERE receiver_email.id_email IN (SELECT email.id FROM email WHERE email.sender_user = @user);
    DELETE FROM email WHERE email.sender_user = @user;
	DELETE FROM enter_system WHERE enter_system.username = @user;
    DELETE FROM system_info WHERE system_info.username = @user;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_email` (IN `id` INT(11), OUT `message` VARCHAR(512))  BEGIN
	CALL get_last_user(@user);
    SELECT email.id, email.sender_user into @id, @sender FROM email WHERE email.id = id;
    IF ( @id IS NOT NULL) THEN
    BEGIN
    	IF ( @sender = @user) AND (SELECT email.delete_by_sender FROM email WHERE email.id = @id) = 0 THEN
        BEGIN
        	UPDATE email SET email.delete_by_sender = 1 WHERE email.id = @id;
            SET message = "email is deleted!";
        END;
    	ELSEIF EXISTS(SELECT receiver_email.receiver_user FROM receiver_email WHERE receiver_email.id_email = (SELECT @id) AND receiver_email.receiver_user = (SELECT @user) AND receiver_email.delete_by_user = 0)THEN
        BEGIN
        	UPDATE receiver_email SET receiver_email.delete_by_user = 1 WHERE (receiver_email.id_email = @id) AND (receiver_email.receiver_user = @user);
        	
            SET message = "email is deleted!";
        END;
        ELSE
        	SET message = "You don't have access to this email because you are not sender or receiver of this email!";
        END IF;
	END;
    ELSE
    	set message = "There is no email with such id!";
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `does_user_exist` (IN `usern` VARCHAR(20), OUT `mess` TINYINT(1))  BEGIN
	SET mess = 0;
	IF EXISTS (SELECT system_info.username FROM system_info WHERE system_info.username = usern) THEN
    	SET mess = 1;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `enter_user` (IN `username` VARCHAR(20), IN `passw` VARCHAR(20), OUT `message` VARCHAR(50))  BEGIN
	SET passw = MD5(passw);
	IF EXISTS(SELECT 		 
    si.username FROM system_info as si WHERE username = si.username and passw = si.passwrd)THEN 
    BEGIN
     INSERT INTO enter_system(username) VALUES(username);
     set message = "Enter was successfull!";
    END; 
    
    ELSE 
    	SET message = "username or password is wrong!";
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_email` (IN `id` INT(11), OUT `message` VARCHAR(512))  BEGIN
	CALL get_last_user(@user);
    SELECT email.id, email.sender_user into @id, @sender FROM email WHERE email.id = id;
    IF ( @id IS NOT NULL) THEN
    BEGIN
    	IF (SELECT @sender) = (SELECT @user) THEN
        BEGIN
        	SELECT email.id, email.subject, email.body, email.send_time, email.sender_user, receiver_email.receiver_user, receiver_email.cc FROM email, receiver_email WHERE email.id=(SELECT @id) AND receiver_email.id_email = (SELECT @id);
            SET message = "successful";
        END;
    	ELSEIF EXISTS(SELECT receiver_email.receiver_user FROM receiver_email WHERE receiver_email.id_email = (SELECT @id) AND receiver_email.receiver_user = (SELECT @user) AND receiver_email.delete_by_user = 0)THEN
        BEGIN
        	UPDATE receiver_email SET receiver_email.is_read = 1 WHERE (receiver_email.id_email = @id) AND (receiver_email.receiver_user = @user);
        	SELECT email.id,email.sender_user, email.subject, email.body, email.send_time, receiver_email.receiver_user, receiver_email.cc, receiver_email.is_read FROM email, receiver_email WHERE email.id = @id AND receiver_email.id_email = @id AND receiver_email.receiver_user = (SELECT @user);
            SET message = "successful";
        END;
        ELSE
        	SET message = "You don't have access to this email because you are not sender or receiver of this email!";
        END IF;
	END;
    ELSE
    	set message = "There is no email with such id!";
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_inbox_email` (IN `page` INT(11))  BEGIN
	DECLARE start_email INT;
	CALL get_last_user(@id);
    SET start_email = (page - 1)*10;
	SELECT email.id, email.sender_user, email.subject, email.body, email.send_time, receiver_email.cc, receiver_email.is_read from email, receiver_email WHERE receiver_email.receiver_user = @id and email.id = receiver_email.id_email AND receiver_email.delete_by_user = 0 ORDER BY email.send_time DESC LIMIT start_email,10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_information` (IN `username` VARCHAR(20))  BEGIN
	CALL get_last_user(@last_user);
	IF (SELECT @last_user = username)THEN
    BEGIN
    SELECT * FROM  personal_info NATURAL JOIN system_info  WHERE system_info.username = username;
   
    END;
    ELSEIF EXISTS(SELECT * FROM personal_info WHERE personal_info.username = username) THEN
    BEGIN
    
    set @flag := (SELECT specific_allow.allow FROM specific_allow WHERE specific_allow.username = username AND specific_allow.target_username = (SELECT @lastuser));
    
    		IF ((SELECT @flag)IS NULL) THEN
            BEGIN
            
            	IF ((SELECT personal_info.available_to_other FROM personal_info WHERE personal_info.username = username)= 1) THEN
                BEGIN
                
            	SELECT * FROM personal_info WHERE personal_info.username = username;
               
                INSERT INTO notification(owner_user, body) VALUES (username, Concat(@last_user," got your personal information, because (s)he had the access!"));
                END;
                ELSE
                BEGIN
                	SELECT * FROM personal_info WHERE personal_info.username = '*';
                    INSERT INTO notification(owner_user, body) VALUES (username, Concat(@last_user," wanted to get your personal information but (s)he didn't get, because (s)he didn't have access!"));
                    END;
            	END IF;
            END;
        	ELSEIF (SELECT @flag = 1) THEN
            BEGIN
        	SELECT * FROM personal_info WHERE personal_info.username = username;
            INSERT INTO notification(owner_user, body) VALUES (username, Concat(@last_user," got your personal information, because (s)he had the access!"));
            END;
        	ELSEIF (SELECT @flag = 0) THEN 
            BEGIN
        		SELECT * FROM personal_info WHERE personal_info.username = '*';
                INSERT INTO notification(owner_user, body) VALUES (username, Concat(@last_user," wanted to get your personal information but (s)he didn't get, because (s)he didn't have access!"));
            END;
    		END IF;
        
       
    END;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_last_user` (OUT `username` VARCHAR(20))  BEGIN
	SELECT enter_system.username INTO username FROM enter_system ORDER BY enter_system.time_enter DESC LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_notification` ()  BEGIN

	CALL get_last_user(@id);
    SELECT notification.owner_user, notification.body, notification.time_created FROM notification WHERE notification.owner_user = (SELECT @id) ORDER BY notification.time_created DESC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_sent_emails` (IN `page` INT(11))  BEGIN
	DECLARE start_email INT;
	CALL get_last_user(@user);
    set start_email = (page - 1)*10;
    SELECT email.id, email.subject, email.body, email.send_time, receiver_email.receiver_user, receiver_email.cc FROM email, receiver_email WHERE email.sender_user = @user and receiver_email.id_email = email.id AND email.delete_by_sender = 0 ORDER BY email.send_time DESC LIMIT start_email, 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `send_email` (IN `subject` VARCHAR(512), IN `body` VARCHAR(512), IN `receivers` TEXT, IN `receivers_cc` TEXT, OUT `message` VARCHAR(50))  proc_label:BEGIN
	
	DECLARE front TEXT;
    DECLARE frontlen INTEGER;
    DECLARE tempReceiver TEXT;
    CALL get_last_user(@username);
	
    
    START TRANSACTION;
    INSERT INTO email(sender_user, subject, body) VALUES (@username, subject, body);
	set @id := (SELECT last_insert_id());
    IF (LENGTH(TRIM(receivers)) = 0 or receivers IS NULL)THEN
    	set message = "receivers shouldn't be null.";
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    WHILE (LENGTH(TRIM(receivers)) != 0 AND receivers IS NOT NULL) DO
    
    SET front = SUBSTRING_INDEX(receivers,',',1);
    SET frontlen = LENGTH(front);
    SET tempReceiver = TRIM(front);
    IF NOT EXISTS(SELECT system_info.username FROM system_info WHERE tempReceiver = system_info.username) THEN
    	SET message = "One of the receivers doesn't exist!";
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    INSERT INTO receiver_email (id_email, receiver_user, is_read, cc) VALUES (@id ,tempReceiver,0,0);
    SET receivers = INSERT(receivers,1,frontlen + 1,'');
    END WHILE;
    
    WHILE (LENGTH(TRIM(receivers_cc)) != 0 AND receivers_cc IS NOT NULL) DO
    
    SET front = SUBSTRING_INDEX(receivers_cc,',',1);
    SET frontlen = LENGTH(front);
    SET tempReceiver = TRIM(front);
    IF NOT EXISTS(SELECT system_info.username FROM system_info WHERE tempReceiver = system_info.username) THEN
    	SET message = "One of the receivers_cc doesn't exist!";
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    INSERT INTO receiver_email (id_email, receiver_user, is_read, cc) VALUES (@id ,tempReceiver,0,1);
    SET receivers_cc = INSERT(receivers_cc,1,frontlen + 1,'');
    END WHILE;
COMMIT;
SET message = "successful";
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_specific_allow` (IN `username` VARCHAR(20), IN `allow` TINYINT(1), OUT `message` VARCHAR(50))  BEGIN
	
	CALL get_last_user(@id);
    CALL does_user_exist(username, @flag);
    IF (SELECT @flag = 1)THEN
    BEGIN
    	IF EXISTS (SELECT * FROM specific_allow WHERE specific_allow.username = @id AND specific_allow.target_username = username) THEN
        	UPDATE specific_allow SET specific_allow.allow = allow WHERE specific_allow.username = @id and specific_allow.target_username = username;
        ELSE
    		INSERT INTO specific_allow(username, target_username, allow) VALUES ( @id, username, allow);
        END IF;
        set message = "successful";
    END;
    ELSE 
    	set message = "There is no account with such username!";
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_user` (IN `address` VARCHAR(512), IN `name` VARCHAR(30), IN `lastname` VARCHAR(50), IN `phone` VARCHAR(15), IN `related_phone` VARCHAR(15), IN `birthdate` DATE, IN `nickname` VARCHAR(20), IN `id` VARCHAR(20), IN `flag` VARCHAR(20), IN `passw` VARCHAR(20), OUT `mess` VARCHAR(100))  proc_update:BEGIN
	DECLARE flag1 TINYINT(1);
    DECLARE flag2 TINYINT(1);
    CALL get_last_user(@lastuser);
    SET flag1 = 0;
    SELECT si.passwrd, si.related_phone INTO @temp_pass, @temp_rph FROM system_info si WHERE @lastuser=si.username;
    IF (passw != '' AND passw IS NOT NULL)THEN
    	BEGIN
        IF LENGTH(passw) < 6 THEN
        	BEGIN
    		SET mess = "The length of password should be at least 6.";
        	LEAVE proc_update;
        	END;
        END IF;
        SET @temp_pass = MD5(passw);
        SET flag1 = 1;
        END;
    END IF;
    IF (related_phone != '' AND related_phone IS NOT NULL)THEN
    	BEGIN
        IF (NOT (related_phone REGEXP '^[0-9]+$')) THEN
        BEGIN
    	SET mess = "related_phone should be integers!";
        LEAVE proc_update;
        	END;
        END IF;
        SET @temp_rph = related_phone;
        SET flag1 = 1;
        END;
    END IF;
    START TRANSACTION;
    IF flag1 = 1 THEN
    	UPDATE system_info si SET si.passwrd = @temp_pass, si.related_phone = @temp_rph WHERE @lastuser = si.username;
    END IF;
    
    SET flag2 = 0;
    SELECT pi.address, pi.firstname, pi.lastname, pi.phone, pi.birthdate, pi.nickname, pi.available_to_other, pi.id INTO @temp_add, @temp_name, @temp_lastname, @temp_phone, @temp_birthdate, @temp_nickname, @temp_flag, @temp_id FROM personal_info AS pi WHERE @lastuser = pi.username;
	IF (address != '' AND address IS NOT NULL)THEN
    	BEGIN
        SET @temp_add = address;
        SET flag2 = 1;
        END;
    END IF;
    IF (name != '' AND name IS NOT NULL)THEN
        BEGIN
        SET @temp_name = name;
        SET flag2 = 1;
        END;
    END IF;
    IF (lastname != '' AND lastname IS NOT NULL)THEN
    	BEGIN
        SET @temp_lastname = lastname;
        SET flag2 = 1;
        END;
    END IF;
    IF (phone != '' AND phone IS NOT NULL)THEN
        BEGIN
        IF (NOT (phone REGEXP '^[0-9]+$')) THEN
        	BEGIN
    		SET mess = "phone should be integers!";
        	LEAVE proc_update;
        	END;
        END IF;
        SET @temp_phone = phone;
        SET flag2 = 1;
        END;
    END IF;
    IF (birthdate != '' AND birthdate IS NOT NULL)THEN
        BEGIN
        SET @temp_birthdate = birthdate;
        SET flag2 = 1;
        END;
    END IF;
    IF (nickname != '' AND nickname IS NOT NULL)THEN
        BEGIN
        SET @temp_nickname = nickname;
        SET flag2 = 1;
        END;
    END IF;
    IF (id != '' AND id IS NOT NULL)THEN
        BEGIN
        IF (NOT (id REGEXP '^[0-9]+$')) THEN
        	BEGIN
    		SET mess = "id should be integers!";
        	LEAVE proc_update;
        	END;
        END IF;
        SET @temp_id = id;
        SET flag2 = 1;
        END;
    END IF;
    IF (flag != '' AND flag IS NOT NULL)THEN
        
        IF flag = '1' or flag = '0' THEN
        BEGIN
        	SET @temp_flag = flag;
        	SET flag2 = 1;
        END;
        ELSE
        	SET mess = "you didn't put correct input for allowing to people!";
            LEAVE proc_update;
        END IF;
    END IF;
    IF flag2 = 1 THEN
    UPDATE personal_info pi SET pi.address = @temp_add, pi.firstname=@temp_name, pi.lastname=@temp_lastname, pi.phone = @temp_phone, pi.id = @temp_id, pi.available_to_other = @temp_flag, pi.nickname = @temp_nickname, pi.birthdate = @temp_birthdate WHERE @lastuser = pi.username;
	END IF;
    IF ((flag1 = 1) or (flag2 =1)) THEN
    BEGIN
    	COMMIT;
        set mess = "update was successful!";
        END;
    ELSE
    	set mess = "you didn't update anything!";
    END IF;
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `email`
--

CREATE TABLE `email` (
  `id` int(11) NOT NULL,
  `sender_user` varchar(20) NOT NULL,
  `subject` varchar(512) NOT NULL,
  `send_time` datetime NOT NULL DEFAULT current_timestamp(),
  `body` varchar(512) NOT NULL,
  `delete_by_sender` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `email`
--

INSERT INTO `email` (`id`, `sender_user`, `subject`, `send_time`, `body`, `delete_by_sender`) VALUES
(15, 'shahriar', 'hello everybody', '2020-06-19 20:24:43', 'salam, khoobi? mamam koobam', 0),
(17, 'shahram', 'hichi', '2020-06-20 19:39:49', 'khastam halet ro beporsam', 0);

--
-- Triggers `email`
--
DELIMITER $$
CREATE TRIGGER `sender_delete_email` AFTER UPDATE ON `email` FOR EACH ROW BEGIN
	INSERT INTO notification(owner_user, body) VALUES (NEW.sender_user, "email was deleted!");

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `enter_system`
--

CREATE TABLE `enter_system` (
  `time_enter` datetime NOT NULL DEFAULT current_timestamp(),
  `username` varchar(20) NOT NULL DEFAULT '*'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `enter_system`
--

INSERT INTO `enter_system` (`time_enter`, `username`) VALUES
('2020-06-20 19:37:09', 'shahram'),
('2020-06-19 20:14:55', 'shahriar'),
('2020-06-19 21:16:36', 'shahriar'),
('2020-06-11 21:34:32', 'soheila'),
('2020-06-12 20:04:33', 'soheila'),
('2020-06-13 18:40:44', 'soheila'),
('2020-06-19 22:29:23', 'soheila');

--
-- Triggers `enter_system`
--
DELIMITER $$
CREATE TRIGGER `notif_enter` AFTER INSERT ON `enter_system` FOR EACH ROW BEGIN
	INSERT INTO notification(owner_user, body) VALUES (NEW.username, "happy to see you again!");

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `notification`
--

CREATE TABLE `notification` (
  `id` int(11) NOT NULL,
  `owner_user` varchar(20) DEFAULT NULL,
  `body` varchar(512) DEFAULT NULL,
  `time_created` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `notification`
--

INSERT INTO `notification` (`id`, `owner_user`, `body`, `time_created`) VALUES
(7, 'soheila', 'welcome to foofle mail!', '2020-06-11 21:32:47'),
(15, 'soheila', 'you have a new email, check your inbox', '2020-06-13 02:00:00'),
(18, 'soheila', 'you have a new CC email, check your inbox', '2020-06-13 02:05:05'),
(21, 'soheila', 'happy to see you again!', '2020-06-13 18:40:44'),
(31, 'shahriar', 'welcome to foofle mail!', '2020-06-19 20:13:54'),
(32, 'shahriar', 'happy to see you again!', '2020-06-19 20:14:55'),
(34, 'soheila', 'you have a new email, check your inbox', '2020-06-19 20:24:43'),
(35, 'shahriar', 'happy to see you again!', '2020-06-19 21:16:36'),
(36, 'shahriar', 'An update was performed on your personal information', '2020-06-19 21:31:03'),
(38, 'soheila', 'happy to see you again!', '2020-06-19 22:29:23'),
(39, 'soheila', 'your email was deleted', '2020-06-19 22:30:09'),
(40, 'soheila', 'An update was performed on your personal information', '2020-06-19 22:31:18'),
(43, 'shahram', 'welcome to foofle mail!', '2020-06-20 19:36:56'),
(44, 'shahram', 'happy to see you again!', '2020-06-20 19:37:09'),
(46, 'soheila', 'you have a new email, check your inbox', '2020-06-20 19:39:49'),
(47, 'shahriar', 'you have a new CC email, check your inbox', '2020-06-20 19:39:49');

-- --------------------------------------------------------

--
-- Table structure for table `personal_info`
--

CREATE TABLE `personal_info` (
  `username` varchar(20) NOT NULL,
  `address` varchar(512) DEFAULT NULL,
  `firstname` varchar(30) DEFAULT NULL,
  `lastname` varchar(50) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `birthdate` date DEFAULT current_timestamp(),
  `nickname` varchar(20) DEFAULT NULL,
  `id` varchar(10) DEFAULT NULL,
  `available_to_other` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `personal_info`
--

INSERT INTO `personal_info` (`username`, `address`, `firstname`, `lastname`, `phone`, `birthdate`, `nickname`, `id`, `available_to_other`) VALUES
('shahram', 'america', 'shahram', 'shappare', '12346578', '1997-06-07', 'shah', '15648', 1),
('shahriar', 'valiasr', 'hamid', 'shahriari', '15648912', '1960-03-06', 'kahkeshani', '12458786', 0),
('soheila', 'shiraz', 'soheila', 'ahmadi', '0923456', '1989-06-07', 'sohi', '451248', 1);

--
-- Triggers `personal_info`
--
DELIMITER $$
CREATE TRIGGER `update_pi` AFTER UPDATE ON `personal_info` FOR EACH ROW BEGIN

	INSERT INTO notification(owner_user, body) VALUES (NEW.username, "An update was performed on your personal information");

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `receiver_email`
--

CREATE TABLE `receiver_email` (
  `id_email` int(11) NOT NULL,
  `receiver_user` varchar(20) NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `cc` tinyint(1) NOT NULL DEFAULT 0,
  `delete_by_user` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `receiver_email`
--

INSERT INTO `receiver_email` (`id_email`, `receiver_user`, `is_read`, `cc`, `delete_by_user`) VALUES
(15, 'soheila', 1, 0, 0),
(17, 'shahriar', 0, 1, 0),
(17, 'soheila', 0, 0, 0);

--
-- Triggers `receiver_email`
--
DELIMITER $$
CREATE TRIGGER `delete_email_rec` AFTER UPDATE ON `receiver_email` FOR EACH ROW BEGIN
	DECLARE mess varchar(100);
    SET mess = "your email was deleted";
	IF New.cc = 1 THEN
		SET mess = "your CC email was deleted";
	END IF;
    INSERT INTO notification(owner_user, body) VALUES (NEW.receiver_user, mess);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `notif_email` AFTER INSERT ON `receiver_email` FOR EACH ROW BEGIN
	DECLARE mess varchar(100);
    SET mess = "you have a new email, check your inbox";
	IF New.cc = 1 THEN
		SET mess = "you have a new CC email, check your inbox";
	END IF;
    INSERT INTO notification(owner_user, body) VALUES (NEW.receiver_user, mess);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `specific_allow`
--

CREATE TABLE `specific_allow` (
  `username` varchar(20) NOT NULL,
  `target_username` varchar(20) NOT NULL,
  `allow` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `specific_allow`
--

INSERT INTO `specific_allow` (`username`, `target_username`, `allow`) VALUES
('shahriar', 'soheila', 1);

-- --------------------------------------------------------

--
-- Table structure for table `system_info`
--

CREATE TABLE `system_info` (
  `username` varchar(20) NOT NULL,
  `passwrd` varchar(30) DEFAULT NULL,
  `date_created` datetime NOT NULL DEFAULT current_timestamp(),
  `related_phone` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `system_info`
--

INSERT INTO `system_info` (`username`, `passwrd`, `date_created`, `related_phone`) VALUES
('shahram', '1b0b60f7effe14af6a0c', '2020-06-20 19:36:56', '4567128'),
('shahriar', '5f4dcc3b5aa765d61d83', '2020-06-19 20:13:54', '1325452'),
('soheila', 'db5afeb102b4846ed084', '2020-06-11 21:32:47', '2154545');

--
-- Triggers `system_info`
--
DELIMITER $$
CREATE TRIGGER `update_si` AFTER UPDATE ON `system_info` FOR EACH ROW BEGIN

	INSERT INTO notification(owner_user, body) VALUES (NEW.username, "An update was performed on your system information");

END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `email`
--
ALTER TABLE `email`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender_user` (`sender_user`);

--
-- Indexes for table `enter_system`
--
ALTER TABLE `enter_system`
  ADD PRIMARY KEY (`time_enter`),
  ADD KEY `username` (`username`);

--
-- Indexes for table `notification`
--
ALTER TABLE `notification`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner_user` (`owner_user`);

--
-- Indexes for table `personal_info`
--
ALTER TABLE `personal_info`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `receiver_email`
--
ALTER TABLE `receiver_email`
  ADD PRIMARY KEY (`id_email`,`receiver_user`),
  ADD KEY `id_email` (`id_email`),
  ADD KEY `receiver_user` (`receiver_user`);

--
-- Indexes for table `specific_allow`
--
ALTER TABLE `specific_allow`
  ADD PRIMARY KEY (`target_username`,`username`);

--
-- Indexes for table `system_info`
--
ALTER TABLE `system_info`
  ADD PRIMARY KEY (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `email`
--
ALTER TABLE `email`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `notification`
--
ALTER TABLE `notification`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `email`
--
ALTER TABLE `email`
  ADD CONSTRAINT `email_ibfk_1` FOREIGN KEY (`sender_user`) REFERENCES `system_info` (`username`);

--
-- Constraints for table `enter_system`
--
ALTER TABLE `enter_system`
  ADD CONSTRAINT `enter_system_ibfk_1` FOREIGN KEY (`username`) REFERENCES `system_info` (`username`);

--
-- Constraints for table `notification`
--
ALTER TABLE `notification`
  ADD CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`owner_user`) REFERENCES `system_info` (`username`);

--
-- Constraints for table `receiver_email`
--
ALTER TABLE `receiver_email`
  ADD CONSTRAINT `receiver_email_ibfk_1` FOREIGN KEY (`id_email`) REFERENCES `email` (`id`),
  ADD CONSTRAINT `receiver_email_ibfk_2` FOREIGN KEY (`receiver_user`) REFERENCES `system_info` (`username`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
