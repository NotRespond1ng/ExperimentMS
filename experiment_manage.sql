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

 Date: 13/08/2025 17:53:20
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
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of activities
-- ----------------------------
INSERT INTO `activities` VALUES (1, 'experiment_update', '更新了实验 5', '2025-07-23 12:11:07', NULL);
INSERT INTO `activities` VALUES (2, 'data_export', '导出了竞品数据', '2025-07-23 12:12:08', NULL);
INSERT INTO `activities` VALUES (3, 'data_export', '导出了竞品数据', '2025-07-23 12:12:22', NULL);
INSERT INTO `activities` VALUES (4, 'data_export', '导出了竞品数据', '2025-07-23 12:17:56', NULL);
INSERT INTO `activities` VALUES (5, '导出指尖血数据', '导出了3条指尖血数据', '2025-07-23 12:18:03', NULL);
INSERT INTO `activities` VALUES (6, 'experiment_delete', '删除了实验 3', '2025-07-23 12:37:36', NULL);
INSERT INTO `activities` VALUES (7, 'experiment_update', '更新了实验 4', '2025-07-24 01:45:40', NULL);
INSERT INTO `activities` VALUES (8, 'experiment_create', '创建了实验 6，批次：003，成员：王五, 李四, 张三', '2025-07-24 10:37:54', NULL);
INSERT INTO `activities` VALUES (9, 'experiment_create', '创建了实验 7，批次：003，成员：张三, 李四, 王五', '2025-07-24 10:47:19', NULL);
INSERT INTO `activities` VALUES (10, 'experiment_update', '更新了实验 7', '2025-07-26 06:53:34', NULL);

-- ----------------------------
-- Table structure for batches
-- ----------------------------
DROP TABLE IF EXISTS `batches`;
CREATE TABLE `batches`  (
  `batch_id` int NOT NULL AUTO_INCREMENT COMMENT '批次唯一标识符',
  `batch_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '批次号名，确保唯一性',
  `start_time` datetime NOT NULL COMMENT '批次开始时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '批次结束时间',
  `person_count` int NULL DEFAULT 0 COMMENT '批次人数统计',
  PRIMARY KEY (`batch_id`) USING BTREE,
  UNIQUE INDEX `batch_number`(`batch_number` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '批次管理表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of batches
-- ----------------------------
INSERT INTO `batches` VALUES (1, 'B20240701-001', '2024-07-01 09:00:00', '2024-07-16 17:00:00', 28);
INSERT INTO `batches` VALUES (2, 'B20240701-002', '2024-07-05 10:30:00', '2024-07-20 16:00:00', 1);
INSERT INTO `batches` VALUES (3, 'B20240701-003', '2024-07-10 14:00:00', NULL, 0);
INSERT INTO `batches` VALUES (4, '20250717', '2025-07-22 00:00:00', NULL, 0);
INSERT INTO `batches` VALUES (5, '20250723', '2025-07-23 00:00:00', NULL, 0);
INSERT INTO `batches` VALUES (6, '001', '2025-07-24 00:00:00', '2025-08-07 00:00:00', 0);
INSERT INTO `batches` VALUES (7, '002', '2025-07-30 00:00:00', NULL, 0);
INSERT INTO `batches` VALUES (8, '003', '2025-07-15 00:00:00', '2025-07-26 00:00:00', 3);
INSERT INTO `batches` VALUES (9, '00001', '2025-08-07 16:08:58', NULL, 1);
INSERT INTO `batches` VALUES (10, '00000012', '2025-08-07 00:00:00', NULL, 0);

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
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '竞品文件表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of competitor_files
-- ----------------------------
INSERT INTO `competitor_files` VALUES (14, 35, 9, 'D:\\Trae_Projects\\ExprimentMS\\backend\\uploads\\competitor_files\\伍珊珊-数据图谱(血糖版).xlsx', '2025-08-07 19:59:25');

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
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '每日体内实验数据记录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of daily_experiment_data
-- ----------------------------
INSERT INTO `daily_experiment_data` VALUES (1, 1, 1, 1, 12.34567, 15.12345, '2024-07-20');
INSERT INTO `daily_experiment_data` VALUES (2, 1, 1, 2, 11.98765, 14.87654, '2024-07-21');
INSERT INTO `daily_experiment_data` VALUES (3, 1, 1, 3, 12.11111, 14.99999, '2024-07-22');
INSERT INTO `daily_experiment_data` VALUES (4, 1, 1, 4, 12.55500, 15.33300, '2024-07-23');
INSERT INTO `daily_experiment_data` VALUES (5, 1, 1, 5, 11.80000, 14.50000, '2024-07-24');
INSERT INTO `daily_experiment_data` VALUES (6, 2, 2, 1, 9.87654, 11.23456, '2024-07-20');
INSERT INTO `daily_experiment_data` VALUES (7, 2, 2, 2, 10.12345, 11.54321, '2024-07-21');
INSERT INTO `daily_experiment_data` VALUES (8, 2, 2, 3, 9.99999, 11.11111, '2024-07-22');
INSERT INTO `daily_experiment_data` VALUES (9, 2, 2, 4, 10.30000, 11.80000, '2024-07-23');
INSERT INTO `daily_experiment_data` VALUES (10, 2, 2, 5, NULL, 11.40000, '2024-07-24');
INSERT INTO `daily_experiment_data` VALUES (11, 3, 3, 1, 14.50000, 18.20000, '2024-07-20');
INSERT INTO `daily_experiment_data` VALUES (12, 3, 3, 2, 14.25000, 17.95000, '2024-07-21');
INSERT INTO `daily_experiment_data` VALUES (13, 3, 3, 3, 14.65000, 18.55000, '2024-07-22');
INSERT INTO `daily_experiment_data` VALUES (14, 3, 3, 4, 14.80000, NULL, '2024-07-23');
INSERT INTO `daily_experiment_data` VALUES (15, 3, 3, 5, 14.10000, 17.80000, '2024-07-24');

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
) ENGINE = InnoDB AUTO_INCREMENT = 27 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '实验成员关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of experiment_members
-- ----------------------------
INSERT INTO `experiment_members` VALUES (8, 2, 1, '2025-07-23 19:58:39');
INSERT INTO `experiment_members` VALUES (9, 2, 2, '2025-07-23 19:58:39');
INSERT INTO `experiment_members` VALUES (10, 2, 3, '2025-07-23 19:58:39');
INSERT INTO `experiment_members` VALUES (11, 5, 2, '2025-07-23 20:11:07');
INSERT INTO `experiment_members` VALUES (12, 5, 1, '2025-07-23 20:11:07');
INSERT INTO `experiment_members` VALUES (13, 5, 3, '2025-07-23 20:11:07');
INSERT INTO `experiment_members` VALUES (14, 5, 5, '2025-07-23 20:11:07');
INSERT INTO `experiment_members` VALUES (15, 5, 6, '2025-07-23 20:11:07');
INSERT INTO `experiment_members` VALUES (16, 5, 7, '2025-07-23 20:11:07');
INSERT INTO `experiment_members` VALUES (17, 4, 4, '2025-07-24 09:45:39');
INSERT INTO `experiment_members` VALUES (18, 6, 29, '2025-07-24 18:37:54');
INSERT INTO `experiment_members` VALUES (19, 6, 28, '2025-07-24 18:37:54');
INSERT INTO `experiment_members` VALUES (20, 6, 27, '2025-07-24 18:37:54');
INSERT INTO `experiment_members` VALUES (24, 7, 27, '2025-07-26 14:53:34');
INSERT INTO `experiment_members` VALUES (25, 7, 28, '2025-07-26 14:53:34');
INSERT INTO `experiment_members` VALUES (26, 7, 29, '2025-07-26 14:53:34');

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
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '实验管理表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of experiments
-- ----------------------------
INSERT INTO `experiments` VALUES (2, 1, '测试批次1中李四的睡眠质量分析', '2025-07-23 19:51:23');
INSERT INTO `experiments` VALUES (4, 4, '1232132412412', '2025-07-23 19:51:23');
INSERT INTO `experiments` VALUES (5, 5, '123123123', '2025-07-23 19:51:23');
INSERT INTO `experiments` VALUES (6, 8, '哈哈哈哈哈哈哈哈哈', '2025-07-24 10:37:54');
INSERT INTO `experiments` VALUES (7, 8, '12312313顶顶顶顶', '2025-07-24 10:47:19');

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
) ENGINE = InnoDB AUTO_INCREMENT = 37 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '指尖血文件表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of finger_blood_files
-- ----------------------------
INSERT INTO `finger_blood_files` VALUES (12, 27, 8, '2025-07-23 00:00:00', 5.10);
INSERT INTO `finger_blood_files` VALUES (13, 27, 8, '2025-07-23 01:00:00', 5.00);
INSERT INTO `finger_blood_files` VALUES (14, 27, 8, '2025-07-23 02:00:00', 4.90);
INSERT INTO `finger_blood_files` VALUES (15, 27, 8, '2025-07-23 03:00:00', 4.80);
INSERT INTO `finger_blood_files` VALUES (16, 27, 8, '2025-07-23 04:00:00', 4.85);
INSERT INTO `finger_blood_files` VALUES (17, 27, 8, '2025-07-23 05:00:00', 4.90);
INSERT INTO `finger_blood_files` VALUES (18, 27, 8, '2025-07-23 06:00:00', 5.20);
INSERT INTO `finger_blood_files` VALUES (19, 27, 8, '2025-07-23 07:00:00', 5.60);
INSERT INTO `finger_blood_files` VALUES (20, 27, 8, '2025-07-23 08:00:00', 6.40);
INSERT INTO `finger_blood_files` VALUES (21, 27, 8, '2025-07-23 09:00:00', 6.10);
INSERT INTO `finger_blood_files` VALUES (22, 27, 8, '2025-07-23 10:00:00', 5.70);
INSERT INTO `finger_blood_files` VALUES (23, 27, 8, '2025-07-23 11:00:00', 5.30);
INSERT INTO `finger_blood_files` VALUES (24, 27, 8, '2025-07-23 12:00:00', 6.90);
INSERT INTO `finger_blood_files` VALUES (25, 27, 8, '2025-07-23 13:00:00', 7.20);
INSERT INTO `finger_blood_files` VALUES (26, 27, 8, '2025-07-23 14:00:00', 6.60);
INSERT INTO `finger_blood_files` VALUES (27, 27, 8, '2025-07-23 15:00:00', 6.00);
INSERT INTO `finger_blood_files` VALUES (28, 27, 8, '2025-07-23 16:00:00', 5.50);
INSERT INTO `finger_blood_files` VALUES (29, 27, 8, '2025-07-23 17:00:00', 5.30);
INSERT INTO `finger_blood_files` VALUES (30, 27, 8, '2025-07-23 18:00:00', 6.50);
INSERT INTO `finger_blood_files` VALUES (31, 27, 8, '2025-07-23 19:00:00', 7.00);
INSERT INTO `finger_blood_files` VALUES (32, 27, 8, '2025-07-23 20:00:00', 6.40);
INSERT INTO `finger_blood_files` VALUES (33, 27, 8, '2025-07-23 21:00:00', 5.80);
INSERT INTO `finger_blood_files` VALUES (34, 27, 8, '2025-07-23 22:00:00', 5.40);
INSERT INTO `finger_blood_files` VALUES (35, 27, 8, '2025-07-23 23:00:00', 5.20);

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
  CONSTRAINT `fk_persons_batch` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 37 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '人员管理表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of persons
-- ----------------------------
INSERT INTO `persons` VALUES (1, '张三', 'Male', 30, 1);
INSERT INTO `persons` VALUES (2, '李四', 'Female', 25, 1);
INSERT INTO `persons` VALUES (3, '王五', 'Male', 40, 1);
INSERT INTO `persons` VALUES (4, '哈哈', 'Male', 120, 1);
INSERT INTO `persons` VALUES (5, 'hahhah', 'Male', NULL, 1);
INSERT INTO `persons` VALUES (6, '赵六', 'Male', 28, 1);
INSERT INTO `persons` VALUES (7, '钱七', 'Female', 22, 1);
INSERT INTO `persons` VALUES (8, '孙八', 'Male', 35, 1);
INSERT INTO `persons` VALUES (9, '周九', 'Female', 29, 1);
INSERT INTO `persons` VALUES (10, '吴十', 'Male', 42, 1);
INSERT INTO `persons` VALUES (11, '郑十一', 'Female', 26, 1);
INSERT INTO `persons` VALUES (12, '王十二', 'Male', 31, 1);
INSERT INTO `persons` VALUES (13, '冯十三', 'Female', 27, 1);
INSERT INTO `persons` VALUES (14, '陈十四', 'Male', 38, 1);
INSERT INTO `persons` VALUES (15, '褚十五', 'Female', 24, 1);
INSERT INTO `persons` VALUES (16, '卫十六', 'Male', 33, 1);
INSERT INTO `persons` VALUES (17, '蒋十七', 'Female', 25, 1);
INSERT INTO `persons` VALUES (18, '沈十八', 'Male', 45, 1);
INSERT INTO `persons` VALUES (19, '韩十九', 'Female', 28, 1);
INSERT INTO `persons` VALUES (20, '杨二十', 'Male', 36, 1);
INSERT INTO `persons` VALUES (21, '朱二十一', 'Female', 30, 1);
INSERT INTO `persons` VALUES (22, '秦二十二', 'Male', 34, 1);
INSERT INTO `persons` VALUES (24, '许二十四', 'Male', 40, 2);
INSERT INTO `persons` VALUES (25, '何二十五', 'Female', 32, 1);
INSERT INTO `persons` VALUES (26, 'adada', 'Male', NULL, 1);
INSERT INTO `persons` VALUES (27, '张三', 'Male', 24, 8);
INSERT INTO `persons` VALUES (28, '李四', 'Male', NULL, 8);
INSERT INTO `persons` VALUES (29, '王五', 'Male', NULL, 8);
INSERT INTO `persons` VALUES (30, '测试人员', 'Male', 25, 1);
INSERT INTO `persons` VALUES (31, '测试人员', 'Male', 25, 1);
INSERT INTO `persons` VALUES (32, '测试人员', 'Male', 25, 1);
INSERT INTO `persons` VALUES (33, '测试人员', 'Male', 25, 1);
INSERT INTO `persons` VALUES (35, '24444', NULL, NULL, 9);

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
  UNIQUE INDEX `uk_probe_number`(`probe_number` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 60 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '传感器详细信息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sensor_details
-- ----------------------------
INSERT INTO `sensor_details` VALUES (1, '2024-05-17', '阻氧-15', 'E051501', 0.0000, 2.7100, 6.9200, 40.6700, 1.5367160000, 0.9916904170, '去向1', '0619A', '2025-08-08 10:00:01');
INSERT INTO `sensor_details` VALUES (2, '2024-05-17', '阻氧-18', 'E051503', 0.0000, 2.9200, 7.2700, 35.3400, 1.5015540000, 0.9960834830, '去向2', '0619B', '2025-08-08 10:00:01');
INSERT INTO `sensor_details` VALUES (3, '2025-08-08', '0001', '09002', 4.0000, 2.0000, 4.0000, 5.0000, 4.0000000000, 1.0000000000, '213124', '', '2025-08-08 10:33:45');
INSERT INTO `sensor_details` VALUES (4, '2025-08-12', '1', '1', 23.0000, 2.0000, 23.0000, 4.0000, 4.0000000000, 1.0000000000, '2141', '214124', '2025-08-12 11:20:25');
INSERT INTO `sensor_details` VALUES (41, '2024-07-15', '20240701-39#', 'F070904', 0.0000, 4.2200, 9.9700, 36.6400, 1.8400000000, 0.9952000000, NULL, NULL, '2025-08-12 17:00:22');
INSERT INTO `sensor_details` VALUES (42, '2024-07-15', '20240624阻氧-250#', 'B070904', 0.0000, 3.7300, 9.1200, 39.6200, 1.6900000000, 0.9984000000, NULL, '0716A', '2025-08-12 17:00:22');
INSERT INTO `sensor_details` VALUES (43, '2024-07-15', '20240701-6#', 'E070902', 0.0000, 4.4800, 10.6000, 38.8100, 1.9800000000, 0.9949000000, NULL, '崔总佩戴', '2025-08-12 17:00:22');
INSERT INTO `sensor_details` VALUES (44, '2024-07-15', '20240624阻氧-256#', 'B070905', 0.0000, 3.9400, 9.5100, 38.8900, 1.8700000000, 0.9965000000, NULL, NULL, '2025-08-12 17:00:22');
INSERT INTO `sensor_details` VALUES (45, '2024-07-15', '20240701-38#', 'F070903', 0.0000, 4.4500, 10.4800, 37.6000, 1.9900000000, 0.9933000000, NULL, '袁总', '2025-08-12 17:00:23');
INSERT INTO `sensor_details` VALUES (46, '2024-07-15', '20240624阻氧-227#', 'B070902', 0.0000, 4.4800, 10.8200, 44.2500, 2.1400000000, 0.9962000000, NULL, '备用', '2025-08-12 17:00:23');
INSERT INTO `sensor_details` VALUES (47, '2024-07-15', '20240701-15#', 'E070904', 0.0000, 4.4400, 9.9600, 29.6200, 1.7100000000, 0.9854000000, NULL, NULL, '2025-08-12 17:00:23');
INSERT INTO `sensor_details` VALUES (48, '2024-07-15', '20240624阻氧-214#', 'B070901', 0.0000, 4.0700, 10.1500, 49.8600, 2.1700000000, 0.9964000000, NULL, '袁总', '2025-08-12 17:00:23');
INSERT INTO `sensor_details` VALUES (49, '2024-07-15', '20240624-阻氧-244#', 'A070502', 0.0000, 4.7600, 11.9100, 59.9800, 2.4600000000, 0.9983000000, NULL, '0716A', '2025-08-12 17:00:23');
INSERT INTO `sensor_details` VALUES (50, '2024-07-15', '20240624阻氧-265#', 'B070906', 0.0000, 4.3000, 10.6400, 50.0600, 2.2500000000, 0.9972000000, NULL, '袁总', '2025-08-12 17:00:23');
INSERT INTO `sensor_details` VALUES (51, '2024-10-09', '20240909-86#', 'B092003', 0.0000, 4.6200, 11.6100, 59.8600, 2.4300000000, 0.9980000000, NULL, '1016B', '2025-08-12 17:00:25');
INSERT INTO `sensor_details` VALUES (52, '2024-10-09', '20240909-83#', 'B092002', 0.0000, 3.8900, 9.7300, 49.1300, 2.0400000000, 0.9966000000, NULL, '1016A', '2025-08-12 17:00:25');
INSERT INTO `sensor_details` VALUES (53, '2024-10-09', '20240909-49＃', 'D091901', 0.0000, 4.6200, 11.2500, 48.1800, 2.1800000000, 0.9970000000, NULL, '体外', '2025-08-12 17:00:25');
INSERT INTO `sensor_details` VALUES (54, '2024-10-09', '20240909-37＃', 'C091901', 0.0000, 4.8200, 11.6200, 47.2200, 2.2200000000, 0.9973000000, NULL, '体外', '2025-08-12 17:00:25');
INSERT INTO `sensor_details` VALUES (55, '2024-10-09', '20240909-15#', 'E091902', 0.0000, 4.8600, 11.8000, 49.6400, 2.2700000000, 0.9972000000, NULL, '1016C', '2025-08-12 17:00:25');
INSERT INTO `sensor_details` VALUES (56, '2024-10-09', '20240909-33#', 'F091905', 0.0000, 4.8400, 11.8200, 51.2300, 2.3100000000, 0.9975000000, NULL, '备用', '2025-08-12 17:00:25');
INSERT INTO `sensor_details` VALUES (57, '2024-10-09', '20240909-31#', 'F091903', 0.0000, 4.9300, 12.0600, 52.6100, 2.3000000000, 0.9969000000, NULL, '备用', '2025-08-12 17:00:27');
INSERT INTO `sensor_details` VALUES (58, '2024-10-09', '20240909-60＃', 'D091906', 0.0000, 4.9400, 12.0400, 51.5200, 2.3200000000, 0.9975000000, '哈哈哈哈', '备用', '2025-08-12 17:00:27');
INSERT INTO `sensor_details` VALUES (59, '2025-08-13', '12313', '3211', 12.0000, 21.0000, 21.0000, 21.0000, 41.0000000000, 0.5000000000, '', '测试', '2025-08-13 17:10:25');

-- ----------------------------
-- Table structure for sensors
-- ----------------------------
DROP TABLE IF EXISTS `sensors`;
CREATE TABLE `sensors`  (
  `sensor_id` int NOT NULL AUTO_INCREMENT COMMENT '传感器唯一标识符',
  `sensor_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '传感器名称',
  `person_id` int NOT NULL COMMENT '关联的人员ID',
  `batch_id` int NOT NULL COMMENT '关联的批次ID',
  `start_time` datetime NOT NULL COMMENT '传感器开始使用时间',
  `end_time` datetime NULL DEFAULT NULL COMMENT '传感器结束使用时间',
  `end_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器结束使用原因（可选）',
  PRIMARY KEY (`sensor_id`) USING BTREE,
  INDEX `person_id`(`person_id` ASC) USING BTREE,
  INDEX `batch_id`(`batch_id` ASC) USING BTREE,
  CONSTRAINT `sensors_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sensors_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '传感器管理表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sensors
-- ----------------------------
INSERT INTO `sensors` VALUES (1, '血糖传感器-001', 1, 1, '2024-07-01 09:30:00', '2024-07-14 18:00:00', NULL);
INSERT INTO `sensors` VALUES (2, '心率传感器-A', 2, 1, '2024-07-05 11:00:00', NULL, NULL);
INSERT INTO `sensors` VALUES (3, '温度传感器-XYZ', 1, 2, '2024-07-10 15:00:00', '2024-07-20 10:00:00', NULL);
INSERT INTO `sensors` VALUES (4, '123', 1, 2, '2025-07-07 00:00:00', '2025-07-08 00:00:00', NULL);
INSERT INTO `sensors` VALUES (5, '123', 1, 1, '2025-07-24 00:00:00', '2025-07-26 00:00:00', '自然结束');

-- ----------------------------
-- Table structure for user_permissions
-- ----------------------------
DROP TABLE IF EXISTS `user_permissions`;
CREATE TABLE `user_permissions`  (
  `permission_id` int NOT NULL AUTO_INCREMENT COMMENT '权限唯一标识符',
  `user_id` int NOT NULL COMMENT '关联的用户ID',
  `module` enum('BATCH_MANAGEMENT','PERSON_MANAGEMENT','EXPERIMENT_MANAGEMENT','COMPETITOR_DATA','FINGER_BLOOD_DATA','SENSOR_DATA','USER_MANAGEMENT') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '模块名称',
  `can_read` tinyint(1) NULL DEFAULT NULL COMMENT '读取权限',
  `can_write` tinyint(1) NULL DEFAULT NULL COMMENT '写入权限',
  `can_delete` tinyint(1) NULL DEFAULT NULL COMMENT '删除权限',
  PRIMARY KEY (`permission_id`) USING BTREE,
  INDEX `user_id`(`user_id` ASC) USING BTREE,
  INDEX `ix_user_permissions_permission_id`(`permission_id` ASC) USING BTREE,
  CONSTRAINT `user_permissions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_permissions
-- ----------------------------
INSERT INTO `user_permissions` VALUES (1, 2, 'BATCH_MANAGEMENT', 1, 0, 0);
INSERT INTO `user_permissions` VALUES (2, 2, 'PERSON_MANAGEMENT', 1, 0, 0);
INSERT INTO `user_permissions` VALUES (3, 2, 'EXPERIMENT_MANAGEMENT', 1, 0, 0);
INSERT INTO `user_permissions` VALUES (4, 2, 'COMPETITOR_DATA', 1, 0, 0);
INSERT INTO `user_permissions` VALUES (5, 2, 'FINGER_BLOOD_DATA', 1, 0, 0);
INSERT INTO `user_permissions` VALUES (6, 2, 'SENSOR_DATA', 1, 0, 0);
INSERT INTO `user_permissions` VALUES (14, 4, 'BATCH_MANAGEMENT', 1, 1, 0);
INSERT INTO `user_permissions` VALUES (15, 4, 'PERSON_MANAGEMENT', 1, 1, 0);
INSERT INTO `user_permissions` VALUES (16, 4, 'EXPERIMENT_MANAGEMENT', 1, 1, 0);
INSERT INTO `user_permissions` VALUES (17, 4, 'COMPETITOR_DATA', 1, 1, 0);
INSERT INTO `user_permissions` VALUES (18, 4, 'FINGER_BLOOD_DATA', 1, 1, 0);
INSERT INTO `user_permissions` VALUES (19, 4, 'SENSOR_DATA', 1, 1, 0);

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
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, 'admin', '$2b$12$OrEfSmkameHVVRayq/Y4BORSYxWXbu0P8H135ZlkduYFGo3Wr8VCG', 'Admin', '2025-07-23 19:12:57', '2025-07-23 12:30:03');
INSERT INTO `users` VALUES (2, 'test', '$2b$12$60QG7BG0S3XqhfkqkoeVM.fRylsA8plpnjA7Em2HTJc74ZYHA56Ci', 'User', '2025-07-23 11:14:45', '2025-07-23 11:14:45');
INSERT INTO `users` VALUES (3, 'test1', '$2b$12$V7gMAszAdAi/hy0n3.Ph5eIWvErYegHNhZqpUNgz1YVEpCEn5vDiS', 'User', '2025-07-23 17:01:22', '2025-07-23 17:01:22');
INSERT INTO `users` VALUES (4, 'test2', '$2b$12$WFWLtNoMtGGuuleu5bU0pOFVIr3WuINmDakZqOf4KeW82nVVFR5/i', 'User', '2025-07-24 11:30:49', '2025-07-24 11:30:49');
INSERT INTO `users` VALUES (5, 'testuser2', '$2b$12$V2lzIQ6g6auSvXzaUpCi5OVURDglOXoxIdBynKklKlnW2QvULcCFS', 'User', '2025-08-07 15:23:32', '2025-08-07 15:23:32');

-- ----------------------------
-- Table structure for wear_records
-- ----------------------------
DROP TABLE IF EXISTS `wear_records`;
CREATE TABLE `wear_records`  (
  `wear_record_id` int NOT NULL AUTO_INCREMENT COMMENT '佩戴记录唯一标识符 (主键)',
  `batch_id` int NOT NULL COMMENT '关联的批次ID (外键)',
  `person_id` int NOT NULL COMMENT '关联的人员ID (外键)',
  `sensor_detail_id` int NOT NULL COMMENT '关联的传感器ID (外键)',
  `applicator_lot_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '敷贴器批号',
  `sensor_lot_no` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器批号',
  `sensor_batch` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器批次',
  `sensor_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '传感器号',
  `transmitter_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '发射器号',
  `wear_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '佩戴记录创建时间',
  PRIMARY KEY (`wear_record_id`) USING BTREE,
  UNIQUE INDEX `uk_person_sensor`(`person_id` ASC, `sensor_detail_id` ASC) USING BTREE,
  INDEX `fk_wear_batch`(`batch_id` ASC) USING BTREE,
  INDEX `fk_wear_person`(`person_id` ASC) USING BTREE,
  INDEX `fk_wear_sensor_detail`(`sensor_detail_id` ASC) USING BTREE,
  CONSTRAINT `fk_wear_batch` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`batch_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wear_person` FOREIGN KEY (`person_id`) REFERENCES `persons` (`person_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wear_sensor_detail` FOREIGN KEY (`sensor_detail_id`) REFERENCES `sensor_details` (`sensor_detail_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 21 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '人员传感器佩戴记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of wear_records
-- ----------------------------
INSERT INTO `wear_records` VALUES (14, 1, 1, 1, '1', '2', '3', '4', '5', '2025-08-08 15:33:54');
INSERT INTO `wear_records` VALUES (15, 1, 1, 3, '141', '124', '124', '214', '412', '2025-08-08 15:33:54');
INSERT INTO `wear_records` VALUES (16, 1, 1, 2, '421', '412', '41', '421', '42', '2025-08-08 15:33:54');
INSERT INTO `wear_records` VALUES (17, 1, 1, 4, 'e12', '312', '321', '31', '231', '2025-08-12 03:22:30');
INSERT INTO `wear_records` VALUES (18, 1, 2, 59, '1', '2', '3', '4', '5', '2025-08-13 17:10:36');
INSERT INTO `wear_records` VALUES (19, 1, 2, 58, '5', '6', '62', '362', '623', '2025-08-13 17:10:36');
INSERT INTO `wear_records` VALUES (20, 2, 24, 41, '1', '2', '3', '4', '5', '2025-08-13 17:19:15');

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
-- Triggers structure for table persons
-- ----------------------------
DROP TRIGGER IF EXISTS `tr_persons_update_count`;
delimiter ;;
CREATE TRIGGER `tr_persons_update_count` AFTER UPDATE ON `persons` FOR EACH ROW BEGIN
    IF OLD.batch_id != NEW.batch_id THEN
        -- 从旧批次减少计数
        IF OLD.batch_id IS NOT NULL THEN
            UPDATE batches
            SET person_count = person_count - 1
            WHERE batch_id = OLD.batch_id;
        END IF;
        -- 向新批次增加计数
        IF NEW.batch_id IS NOT NULL THEN
            UPDATE batches
            SET person_count = person_count + 1
            WHERE batch_id = NEW.batch_id;
        END IF;
    END IF;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
