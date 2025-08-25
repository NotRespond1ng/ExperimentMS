/*
 Navicat Premium Data Transfer

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80034
 Source Host           : localhost:3306
 Source Schema         : experiment_manage

 Target Server Type    : MySQL
 Target Server Version : 80034
 File Encoding         : 65001

 Date: 25/08/2025 14:25:47
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for activities
-- ----------------------------
DROP TABLE IF EXISTS `activities`;
CREATE TABLE `activities`  (
  `activity_id` int NOT NULL AUTO_INCREMENT COMMENT '活动唯一标识符',
  `activity_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '活动类型',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '活动描述',
  `createTime` datetime NOT NULL COMMENT '创建时间',
  `user_id` int NULL DEFAULT NULL COMMENT '操作用户ID',
  PRIMARY KEY (`activity_id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  INDEX `ix_activities_activity_id`(`activity_id` ASC) USING BTREE,
  CONSTRAINT `activities_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for batches
-- ----------------------------
DROP TABLE IF EXISTS `batches`;
CREATE TABLE `batches`  (
  `batch_id` int NOT NULL AUTO_INCREMENT COMMENT '批次唯一标识符',
  `batch_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '实验批次号名，确保唯一性',
  `start_time` datetime NOT NULL COMMENT '批次开始时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '批次结束时间',
  `person_count` int NULL DEFAULT 0 COMMENT '批次人数统计',
  PRIMARY KEY (`batch_id`) USING BTREE,
  UNIQUE INDEX `batch_number`(`batch_number` ASC) USING BTREE,
  INDEX `idx_batches_number`(`batch_number` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '批次管理表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for competitor_files
-- ----------------------------
DROP TABLE IF EXISTS `competitor_files`;
CREATE TABLE `competitor_files`  (
  `competitor_file_id` int NOT NULL AUTO_INCREMENT COMMENT '竞品文件唯一标识符',
  `person_id` int NOT NULL COMMENT '关联的人员ID',
  `batch_id` int NOT NULL COMMENT '关联的批次ID',
  `file_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '竞品文件名',
  `upload_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '文件上传时间',
  PRIMARY KEY (`competitor_file_id`) USING BTREE,
  INDEX `person_id`(`person_id` ASC) USING BTREE,
  INDEX `batch_id`(`batch_id` ASC) USING BTREE,
  INDEX `idx_upload_time`(`upload_time` ASC) USING BTREE,
  CONSTRAINT `competitor_files_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `competitor_files_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '竞品文件表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for daily_experiment_data
-- ----------------------------
DROP TABLE IF EXISTS `daily_experiment_data`;
CREATE TABLE `daily_experiment_data`  (
  `data_id` int NOT NULL AUTO_INCREMENT COMMENT '数据唯一标识符',
  `person_id` int NOT NULL COMMENT '关联的人员ID (外键, 关联persons.person_id)',
  `batch_id` int NOT NULL COMMENT '关联的批次ID (外键, 关联batches.batch_id)',
  `experiment_day` int NOT NULL COMMENT '实验天数 (例如: 1, 2, 3...)',
  `mard_value` decimal(10, 5) NULL DEFAULT NULL COMMENT '当天的MARD值',
  `pard_value` decimal(10, 5) NULL DEFAULT NULL COMMENT '当天的PARD值',
  `record_date` date NOT NULL COMMENT '记录的实际日期',
  PRIMARY KEY (`data_id`) USING BTREE,
  UNIQUE INDEX `uk_person_day`(`person_id` ASC, `experiment_day` ASC) USING BTREE,
  INDEX `idx_batch_person`(`batch_id` ASC, `person_id` ASC) USING BTREE,
  CONSTRAINT `daily_experiment_data_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `daily_experiment_data_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '每日体内实验数据记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for experiment_members
-- ----------------------------
DROP TABLE IF EXISTS `experiment_members`;
CREATE TABLE `experiment_members`  (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '关联记录唯一标识符',
  `experiment_id` int NOT NULL COMMENT '实验ID',
  `person_id` int NOT NULL COMMENT '人员ID',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unique_experiment_person`(`experiment_id` ASC, `person_id` ASC) USING BTREE,
  INDEX `person_id`(`person_id` ASC) USING BTREE,
  CONSTRAINT `experiment_members_ibfk_1` FOREIGN KEY (`experiment_id`) REFERENCES `experiments` (`experiment_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `experiment_members_ibfk_2` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '实验成员关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for experiments
-- ----------------------------
DROP TABLE IF EXISTS `experiments`;
CREATE TABLE `experiments`  (
  `experiment_id` int NOT NULL AUTO_INCREMENT COMMENT '实验唯一标识符',
  `batch_id` int NOT NULL COMMENT '关联的批次ID',
  `experiment_content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '实验具体内容描述',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`experiment_id`) USING BTREE,
  INDEX `batch_id`(`batch_id` ASC) USING BTREE,
  CONSTRAINT `experiments_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '实验管理表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for finger_blood_files
-- ----------------------------
DROP TABLE IF EXISTS `finger_blood_files`;
CREATE TABLE `finger_blood_files`  (
  `finger_blood_file_id` int NOT NULL AUTO_INCREMENT COMMENT '指尖血文件唯一标识符',
  `person_id` int NOT NULL COMMENT '关联的人员ID',
  `batch_id` int NOT NULL COMMENT '关联的批次ID',
  `collection_time` datetime NOT NULL COMMENT '采集时间',
  `blood_glucose_value` decimal(5, 2) NOT NULL COMMENT '血糖值',
  PRIMARY KEY (`finger_blood_file_id`) USING BTREE,
  INDEX `person_id`(`person_id` ASC) USING BTREE,
  INDEX `batch_id`(`batch_id` ASC) USING BTREE,
  CONSTRAINT `finger_blood_files_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `finger_blood_files_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 203 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '指尖血文件表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for persons
-- ----------------------------
DROP TABLE IF EXISTS `persons`;
CREATE TABLE `persons`  (
  `person_id` int NOT NULL AUTO_INCREMENT COMMENT '人员唯一标识符',
  `person_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '人员名字',
  `gender` enum('Male','Female','Other') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '性别',
  `age` int NULL DEFAULT NULL COMMENT '年龄',
  `batch_id` int NULL DEFAULT NULL COMMENT '关联的批次ID',
  PRIMARY KEY (`person_id`) USING BTREE,
  INDEX `fk_persons_batch`(`batch_id` ASC) USING BTREE,
  INDEX `idx_persons_batch_id`(`batch_id` ASC) USING BTREE,
  INDEX `idx_persons_name`(`person_name` ASC) USING BTREE,
  CONSTRAINT `fk_persons_batch` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 40 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '人员管理表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for sensor_details
-- ----------------------------
DROP TABLE IF EXISTS `sensor_details`;
CREATE TABLE `sensor_details`  (
  `sensor_detail_id` int NOT NULL AUTO_INCREMENT COMMENT '传感器详细信息唯一标识符 (主键)',
  `sterilization_date` date NULL DEFAULT NULL COMMENT '灭菌日期',
  `test_number` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '传感器测试编号 (应唯一)',
  `probe_number` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '探针编号 (应唯一)',
  `value_0` decimal(10, 4) NULL DEFAULT NULL COMMENT '在 0.00 浓度下的响应值',
  `value_2` decimal(10, 4) NULL DEFAULT NULL COMMENT '在 2.00 浓度下的响应值',
  `value_5` decimal(10, 4) NULL DEFAULT NULL COMMENT '在 5.00 浓度下的响应值',
  `value_25` decimal(10, 4) NULL DEFAULT NULL COMMENT '在 25.00 浓度下的响应值',
  `sensitivity` decimal(20, 10) NULL DEFAULT NULL COMMENT '线性灵敏度(未带温度)',
  `r_value` decimal(20, 10) NULL DEFAULT NULL COMMENT '相关系数 R',
  `destination` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '去向',
  `remarks` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  `created_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  PRIMARY KEY (`sensor_detail_id`) USING BTREE,
  UNIQUE INDEX `uk_test_number`(`test_number` ASC) USING BTREE,
  UNIQUE INDEX `uk_probe_number`(`probe_number` ASC) USING BTREE,
  INDEX `idx_sensor_details_test_number`(`test_number` ASC) USING BTREE,
  INDEX `idx_sensor_details_probe_number`(`probe_number` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 76 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '传感器详细信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for sensors
-- ----------------------------
DROP TABLE IF EXISTS `sensors`;
CREATE TABLE `sensors`  (
  `sensor_id` int NOT NULL AUTO_INCREMENT COMMENT '传感器唯一标识符',
  `person_id` int NOT NULL COMMENT '关联的人员ID',
  `batch_id` int NOT NULL COMMENT '关联的批次ID',
  `sensor_detail_id` int NOT NULL COMMENT '关联的传感器详细信息ID',
  `sensor_lot_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '新增: 传感器批号',
  `sensor_batch` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '新增: 传感器批次 (与传感器号值相同)',
  `sensor_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '新增: 传感器号 (与传感器批次值相同)',
  `transmitter_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '新增: 发射器号',
  `start_time` date NULL DEFAULT 'curdate()' COMMENT '佩戴记录创建时间',
  `end_time` date NULL DEFAULT NULL COMMENT '佩戴结束时间',
  `end_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器结束使用原因（可选）',
  PRIMARY KEY (`sensor_id`) USING BTREE,
  INDEX `person_id`(`person_id` ASC) USING BTREE,
  INDEX `batch_id`(`batch_id` ASC) USING BTREE,
  INDEX `fk_sensor_detail`(`sensor_detail_id` ASC) USING BTREE,
  INDEX `idx_sensors_batch_id`(`batch_id` ASC) USING BTREE,
  INDEX `idx_sensors_person_id`(`person_id` ASC) USING BTREE,
  INDEX `idx_sensors_detail_id`(`sensor_detail_id` ASC) USING BTREE,
  CONSTRAINT `fk_sensor_detail` FOREIGN KEY (`sensor_detail_id`) REFERENCES `sensor_details` (`sensor_detail_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `sensors_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sensors_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 26 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '传感器管理表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for user_permissions
-- ----------------------------
DROP TABLE IF EXISTS `user_permissions`;
CREATE TABLE `user_permissions`  (
  `permission_id` int NOT NULL AUTO_INCREMENT COMMENT '权限唯一标识符',
  `user_id` int NOT NULL COMMENT '关联的用户ID',
  `module` enum('BATCH_MANAGEMENT','PERSON_MANAGEMENT','EXPERIMENT_MANAGEMENT','COMPETITOR_DATA','FINGER_BLOOD_DATA','SENSOR_DATA','SENSOR_DETAILS','WEAR_RECORDS','USER_MANAGEMENT') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '模块名称',
  `can_read` tinyint(1) NULL DEFAULT NULL COMMENT '读取权限',
  `can_write` tinyint(1) NULL DEFAULT NULL COMMENT '写入权限',
  `can_delete` tinyint(1) NULL DEFAULT NULL COMMENT '删除权限',
  PRIMARY KEY (`permission_id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  INDEX `ix_user_permissions_permission_id`(`permission_id` ASC) USING BTREE,
  CONSTRAINT `user_permissions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 62 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `user_id` int NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识符',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录用户名',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '哈希加密后的密码',
  `role` enum('Admin','User') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户角色 (Admin/User)',
  `createTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updateTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE INDEX `uq_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for wear_records
-- ----------------------------
DROP TABLE IF EXISTS `wear_records`;
CREATE TABLE `wear_records`  (
  `wear_record_id` int NOT NULL AUTO_INCREMENT COMMENT '佩戴记录唯一标识符 (主键)',
  `batch_id` int NOT NULL COMMENT '关联的批次ID (外键)',
  `person_id` int NOT NULL COMMENT '关联的人员ID (外键)',
  `sensor_id` int NOT NULL COMMENT '关联的传感器ID (外键)',
  `sensor_detail_id` int NULL DEFAULT NULL COMMENT '关联的传感器详细信息ID (外键)',
  `applicator_lot_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '敷贴器批号',
  `sensor_lot_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器批号',
  `sensor_batch` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器批次',
  `sensor_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器号',
  `transmitter_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '发射器号',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户名称',
  `wear_time` date NULL DEFAULT 'curdate()' COMMENT '佩戴记录创建时间',
  `wear_end_time` date NULL DEFAULT NULL COMMENT '佩戴结束时间',
  `wear_position` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户名称',
  `abnormal_situation` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '新增: 记录发生的异常情况',
  `cause_analysis` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '新增: 对异常情况的原因分析',
  PRIMARY KEY (`wear_record_id`) USING BTREE,
  UNIQUE INDEX `uk_person_sensor`(`person_id` ASC, `sensor_id` ASC) USING BTREE,
  INDEX `fk_wear_batch`(`batch_id` ASC) USING BTREE,
  INDEX `fk_wear_person`(`person_id` ASC) USING BTREE,
  INDEX `fk_wear_sensor`(`sensor_id` ASC) USING BTREE,
  INDEX `fk_wear_sensor_detail`(`sensor_detail_id` ASC) USING BTREE,
  INDEX `idx_wear_records_batch_id`(`batch_id` ASC) USING BTREE,
  INDEX `idx_wear_records_person_id`(`person_id` ASC) USING BTREE,
  INDEX `idx_wear_records_sensor_id`(`sensor_id` ASC) USING BTREE,
  INDEX `idx_wear_records_wear_time`(`wear_time` ASC) USING BTREE,
  INDEX `idx_wear_records_batch_person`(`batch_id` ASC, `person_id` ASC) USING BTREE,
  CONSTRAINT `fk_wear_batch` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wear_person` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wear_sensor` FOREIGN KEY (`sensor_id`) REFERENCES `sensors` (`sensor_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wear_sensor_detail` FOREIGN KEY (`sensor_detail_id`) REFERENCES `sensor_details` (`sensor_detail_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 55 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '人员传感器佩戴记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Triggers structure for table persons
-- ----------------------------
DROP TRIGGER IF EXISTS `tr_persons_insert_count`;
delimiter ;;
CREATE TRIGGER `tr_persons_insert_count` AFTER INSERT ON `persons` FOR EACH ROW BEGIN
    IF NEW.batch_id IS NOT NULL THEN
        UPDATE batches
        SET person_count = person_count + 1
        WHERE batch_id = NEW.batch_id;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table persons
-- ----------------------------
DROP TRIGGER IF EXISTS `tr_persons_update_count`;
delimiter ;;
CREATE TRIGGER `tr_persons_update_count` AFTER UPDATE ON `persons` FOR EACH ROW BEGIN
    IF OLD.batch_id != NEW.batch_id THEN
        
        IF OLD.batch_id IS NOT NULL THEN
            UPDATE batches
            SET person_count = person_count - 1
            WHERE batch_id = OLD.batch_id;
        END IF;
        
        IF NEW.batch_id IS NOT NULL THEN
            UPDATE batches
            SET person_count = person_count + 1
            WHERE batch_id = NEW.batch_id;
        END IF;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table persons
-- ----------------------------
DROP TRIGGER IF EXISTS `tr_persons_delete_count`;
delimiter ;;
CREATE TRIGGER `tr_persons_delete_count` AFTER DELETE ON `persons` FOR EACH ROW BEGIN
    IF OLD.batch_id IS NOT NULL THEN
        UPDATE batches
        SET person_count = person_count - 1
        WHERE batch_id = OLD.batch_id;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table wear_records
-- ----------------------------
DROP TRIGGER IF EXISTS `tr_wear_records_delete_sensor`;
delimiter ;;
CREATE TRIGGER `tr_wear_records_delete_sensor` AFTER DELETE ON `wear_records` FOR EACH ROW BEGIN
    
    DELETE FROM `sensors` 
    WHERE `sensor_id` = OLD.sensor_id;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
