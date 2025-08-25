/*
 Navicat Premium Data Transfer

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80032
 Source Host           : localhost:3306
 Source Schema         : experiment_manage

 Target Server Type    : MySQL
 Target Server Version : 80032
 File Encoding         : 65001

 Date: 24/08/2025 23:32:55
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
INSERT INTO `activities` VALUES (11, 'experiment_create', '创建了实验 8，批次：测试批次，成员：小华, 小俊, 小明', '2025-08-22 15:14:46', NULL);

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
-- Records of batches
-- ----------------------------
INSERT INTO `batches` VALUES (1, '0723', '2024-07-01 09:00:00', '2024-07-16 17:00:00', 28);
INSERT INTO `batches` VALUES (2, '0724', '2024-07-05 10:30:00', '2024-07-20 16:00:00', 1);
INSERT INTO `batches` VALUES (3, '0729', '2024-07-10 14:00:00', NULL, 0);
INSERT INTO `batches` VALUES (4, '0731', '2025-07-22 00:00:00', NULL, 1);
INSERT INTO `batches` VALUES (5, '0806', '2025-07-23 00:00:00', NULL, 0);
INSERT INTO `batches` VALUES (6, '0813', '2025-07-24 00:00:00', '2025-08-07 00:00:00', 0);
INSERT INTO `batches` VALUES (7, '002', '2025-07-30 00:00:00', NULL, 0);
INSERT INTO `batches` VALUES (8, '003', '2025-07-15 00:00:00', '2025-07-26 00:00:00', 3);
INSERT INTO `batches` VALUES (9, '00001', '2025-08-07 16:08:58', NULL, 2);
INSERT INTO `batches` VALUES (10, '测试批次', '2025-08-08 00:00:00', NULL, 3);
INSERT INTO `batches` VALUES (11, '99809', '2025-08-09 00:00:00', NULL, 0);

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
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '每日体内实验数据记录表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '实验成员关联表' ROW_FORMAT = DYNAMIC;

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
INSERT INTO `experiment_members` VALUES (27, 8, 39, '2025-08-22 15:14:46');
INSERT INTO `experiment_members` VALUES (28, 8, 38, '2025-08-22 15:14:46');
INSERT INTO `experiment_members` VALUES (29, 8, 36, '2025-08-22 15:14:46');

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
-- Records of experiments
-- ----------------------------
INSERT INTO `experiments` VALUES (2, 1, '测试批次1中李四的睡眠质量分析', '2025-07-23 19:51:23');
INSERT INTO `experiments` VALUES (4, 4, '1232132412412', '2025-07-23 19:51:23');
INSERT INTO `experiments` VALUES (5, 5, '123123123', '2025-07-23 19:51:23');
INSERT INTO `experiments` VALUES (6, 8, '哈哈哈哈哈哈哈哈哈', '2025-07-24 10:37:54');
INSERT INTO `experiments` VALUES (7, 8, '12312313顶顶顶顶', '2025-07-24 10:47:19');
INSERT INTO `experiments` VALUES (8, 10, '', '2025-08-22 15:14:46');

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
INSERT INTO `finger_blood_files` VALUES (37, 36, 10, '2025-08-08 02:01:01', 5.40);
INSERT INTO `finger_blood_files` VALUES (38, 36, 10, '2025-08-08 02:04:01', 6.60);
INSERT INTO `finger_blood_files` VALUES (39, 36, 10, '2025-08-08 02:07:01', 6.90);
INSERT INTO `finger_blood_files` VALUES (40, 36, 10, '2025-08-08 02:10:01', 5.40);
INSERT INTO `finger_blood_files` VALUES (42, 36, 10, '2025-08-09 00:49:40', 5.50);
INSERT INTO `finger_blood_files` VALUES (43, 36, 10, '2025-08-09 02:48:01', 10.50);
INSERT INTO `finger_blood_files` VALUES (44, 36, 10, '2025-08-09 06:15:53', 3.90);
INSERT INTO `finger_blood_files` VALUES (45, 36, 10, '2025-08-09 10:30:05', 14.90);
INSERT INTO `finger_blood_files` VALUES (46, 36, 10, '2025-08-09 11:27:35', 10.30);
INSERT INTO `finger_blood_files` VALUES (47, 36, 10, '2025-08-09 16:13:12', 6.00);
INSERT INTO `finger_blood_files` VALUES (48, 36, 10, '2025-08-09 19:53:01', 8.70);
INSERT INTO `finger_blood_files` VALUES (49, 36, 10, '2025-08-09 21:05:20', 8.00);
INSERT INTO `finger_blood_files` VALUES (50, 36, 10, '2025-08-10 01:44:08', 6.10);
INSERT INTO `finger_blood_files` VALUES (51, 36, 10, '2025-08-10 06:41:59', 6.60);
INSERT INTO `finger_blood_files` VALUES (52, 36, 10, '2025-08-10 11:17:47', 13.70);
INSERT INTO `finger_blood_files` VALUES (53, 36, 10, '2025-08-10 11:34:33', 12.00);
INSERT INTO `finger_blood_files` VALUES (54, 36, 10, '2025-08-10 15:28:07', 3.70);
INSERT INTO `finger_blood_files` VALUES (55, 36, 10, '2025-08-10 19:10:29', 6.70);
INSERT INTO `finger_blood_files` VALUES (56, 36, 10, '2025-08-10 21:30:46', 14.40);
INSERT INTO `finger_blood_files` VALUES (57, 36, 10, '2025-08-10 23:03:34', 8.00);
INSERT INTO `finger_blood_files` VALUES (58, 36, 10, '2025-08-11 01:28:33', 8.70);
INSERT INTO `finger_blood_files` VALUES (59, 36, 10, '2025-08-11 01:38:57', 3.30);
INSERT INTO `finger_blood_files` VALUES (60, 36, 10, '2025-08-11 06:35:41', 6.40);
INSERT INTO `finger_blood_files` VALUES (61, 36, 10, '2025-08-11 10:19:30', 10.50);
INSERT INTO `finger_blood_files` VALUES (62, 36, 10, '2025-08-11 11:35:30', 5.70);
INSERT INTO `finger_blood_files` VALUES (63, 36, 10, '2025-08-11 16:37:46', 7.60);
INSERT INTO `finger_blood_files` VALUES (64, 36, 10, '2025-08-11 23:03:43', 7.80);
INSERT INTO `finger_blood_files` VALUES (65, 36, 10, '2025-08-11 23:35:54', 6.20);
INSERT INTO `finger_blood_files` VALUES (66, 36, 10, '2025-08-12 04:04:40', 12.00);
INSERT INTO `finger_blood_files` VALUES (67, 36, 10, '2025-08-12 10:02:22', 3.30);
INSERT INTO `finger_blood_files` VALUES (68, 36, 10, '2025-08-12 10:57:45', 10.00);
INSERT INTO `finger_blood_files` VALUES (69, 36, 10, '2025-08-12 11:11:30', 7.00);
INSERT INTO `finger_blood_files` VALUES (70, 36, 10, '2025-08-12 12:32:55', 14.90);
INSERT INTO `finger_blood_files` VALUES (71, 36, 10, '2025-08-12 13:24:31', 14.60);
INSERT INTO `finger_blood_files` VALUES (72, 36, 10, '2025-08-12 19:49:15', 12.80);
INSERT INTO `finger_blood_files` VALUES (73, 36, 10, '2025-08-12 19:55:32', 4.50);
INSERT INTO `finger_blood_files` VALUES (74, 36, 10, '2025-08-13 07:21:41', 5.20);
INSERT INTO `finger_blood_files` VALUES (75, 36, 10, '2025-08-13 08:55:25', 14.10);
INSERT INTO `finger_blood_files` VALUES (76, 36, 10, '2025-08-13 11:04:50', 7.60);
INSERT INTO `finger_blood_files` VALUES (77, 36, 10, '2025-08-13 13:52:50', 5.70);
INSERT INTO `finger_blood_files` VALUES (78, 36, 10, '2025-08-13 15:17:27', 3.50);
INSERT INTO `finger_blood_files` VALUES (79, 36, 10, '2025-08-13 18:20:15', 7.10);
INSERT INTO `finger_blood_files` VALUES (80, 36, 10, '2025-08-13 22:06:54', 8.90);
INSERT INTO `finger_blood_files` VALUES (81, 36, 10, '2025-08-13 22:56:39', 3.20);
INSERT INTO `finger_blood_files` VALUES (82, 36, 10, '2025-08-14 04:06:20', 5.40);
INSERT INTO `finger_blood_files` VALUES (83, 36, 10, '2025-08-14 08:19:20', 4.20);
INSERT INTO `finger_blood_files` VALUES (84, 36, 10, '2025-08-14 09:04:57', 7.40);
INSERT INTO `finger_blood_files` VALUES (85, 36, 10, '2025-08-14 11:41:53', 11.10);
INSERT INTO `finger_blood_files` VALUES (86, 36, 10, '2025-08-14 15:16:19', 4.80);
INSERT INTO `finger_blood_files` VALUES (87, 36, 10, '2025-08-14 16:07:29', 8.40);
INSERT INTO `finger_blood_files` VALUES (88, 36, 10, '2025-08-14 19:47:20', 4.80);
INSERT INTO `finger_blood_files` VALUES (89, 36, 10, '2025-08-14 23:11:33', 13.80);
INSERT INTO `finger_blood_files` VALUES (90, 36, 10, '2025-08-15 01:45:36', 12.00);
INSERT INTO `finger_blood_files` VALUES (91, 36, 10, '2025-08-15 05:08:30', 13.90);
INSERT INTO `finger_blood_files` VALUES (92, 36, 10, '2025-08-15 07:46:05', 13.10);
INSERT INTO `finger_blood_files` VALUES (93, 36, 10, '2025-08-15 18:41:55', 5.00);
INSERT INTO `finger_blood_files` VALUES (94, 36, 10, '2025-08-15 19:35:22', 11.00);
INSERT INTO `finger_blood_files` VALUES (95, 36, 10, '2025-08-15 23:22:13', 5.10);
INSERT INTO `finger_blood_files` VALUES (96, 36, 10, '2025-08-15 23:25:44', 4.80);
INSERT INTO `finger_blood_files` VALUES (97, 36, 10, '2025-08-15 23:47:56', 6.20);
INSERT INTO `finger_blood_files` VALUES (98, 36, 10, '2025-08-16 04:00:29', 11.40);
INSERT INTO `finger_blood_files` VALUES (99, 36, 10, '2025-08-16 10:25:07', 4.90);
INSERT INTO `finger_blood_files` VALUES (100, 36, 10, '2025-08-16 14:02:28', 11.30);
INSERT INTO `finger_blood_files` VALUES (101, 36, 10, '2025-08-16 16:25:00', 5.10);
INSERT INTO `finger_blood_files` VALUES (102, 36, 10, '2025-08-16 17:52:44', 7.20);
INSERT INTO `finger_blood_files` VALUES (103, 36, 10, '2025-08-16 17:54:12', 5.80);
INSERT INTO `finger_blood_files` VALUES (104, 36, 10, '2025-08-16 18:49:42', 4.20);
INSERT INTO `finger_blood_files` VALUES (105, 36, 10, '2025-08-16 18:54:24', 7.90);
INSERT INTO `finger_blood_files` VALUES (106, 36, 10, '2025-08-17 04:08:35', 14.90);
INSERT INTO `finger_blood_files` VALUES (107, 36, 10, '2025-08-17 07:37:51', 14.00);
INSERT INTO `finger_blood_files` VALUES (108, 36, 10, '2025-08-17 08:20:01', 4.50);
INSERT INTO `finger_blood_files` VALUES (109, 36, 10, '2025-08-17 10:30:38', 11.00);
INSERT INTO `finger_blood_files` VALUES (110, 36, 10, '2025-08-17 10:54:15', 12.20);
INSERT INTO `finger_blood_files` VALUES (111, 36, 10, '2025-08-17 14:22:39', 3.50);
INSERT INTO `finger_blood_files` VALUES (112, 36, 10, '2025-08-17 17:23:39', 10.00);
INSERT INTO `finger_blood_files` VALUES (113, 36, 10, '2025-08-17 21:29:33', 11.20);
INSERT INTO `finger_blood_files` VALUES (114, 36, 10, '2025-08-18 01:52:00', 4.90);
INSERT INTO `finger_blood_files` VALUES (115, 36, 10, '2025-08-18 03:25:39', 8.20);
INSERT INTO `finger_blood_files` VALUES (116, 36, 10, '2025-08-18 08:03:46', 14.80);
INSERT INTO `finger_blood_files` VALUES (117, 36, 10, '2025-08-18 08:44:57', 13.60);
INSERT INTO `finger_blood_files` VALUES (118, 36, 10, '2025-08-18 08:46:14', 10.80);
INSERT INTO `finger_blood_files` VALUES (119, 36, 10, '2025-08-18 11:26:47', 6.50);
INSERT INTO `finger_blood_files` VALUES (120, 36, 10, '2025-08-18 15:22:30', 14.30);
INSERT INTO `finger_blood_files` VALUES (121, 36, 10, '2025-08-18 22:39:41', 8.40);
INSERT INTO `finger_blood_files` VALUES (122, 39, 10, '2025-08-08 00:00:00', 6.30);
INSERT INTO `finger_blood_files` VALUES (123, 39, 10, '2025-08-09 00:48:44', 12.70);
INSERT INTO `finger_blood_files` VALUES (124, 39, 10, '2025-08-09 06:11:13', 12.40);
INSERT INTO `finger_blood_files` VALUES (125, 39, 10, '2025-08-09 07:23:06', 6.30);
INSERT INTO `finger_blood_files` VALUES (126, 39, 10, '2025-08-09 10:34:05', 7.40);
INSERT INTO `finger_blood_files` VALUES (127, 39, 10, '2025-08-09 12:11:51', 13.50);
INSERT INTO `finger_blood_files` VALUES (128, 39, 10, '2025-08-09 20:12:49', 11.80);
INSERT INTO `finger_blood_files` VALUES (129, 39, 10, '2025-08-09 23:28:12', 4.30);
INSERT INTO `finger_blood_files` VALUES (130, 39, 10, '2025-08-09 23:42:14', 5.60);
INSERT INTO `finger_blood_files` VALUES (131, 39, 10, '2025-08-10 02:04:48', 12.90);
INSERT INTO `finger_blood_files` VALUES (132, 39, 10, '2025-08-10 03:14:00', 12.10);
INSERT INTO `finger_blood_files` VALUES (133, 39, 10, '2025-08-10 03:56:47', 4.20);
INSERT INTO `finger_blood_files` VALUES (134, 39, 10, '2025-08-10 04:08:01', 5.60);
INSERT INTO `finger_blood_files` VALUES (135, 39, 10, '2025-08-10 04:54:07', 12.20);
INSERT INTO `finger_blood_files` VALUES (136, 39, 10, '2025-08-10 12:09:44', 6.30);
INSERT INTO `finger_blood_files` VALUES (137, 39, 10, '2025-08-10 16:31:00', 8.40);
INSERT INTO `finger_blood_files` VALUES (138, 39, 10, '2025-08-10 21:31:08', 9.30);
INSERT INTO `finger_blood_files` VALUES (139, 39, 10, '2025-08-11 01:56:31', 7.60);
INSERT INTO `finger_blood_files` VALUES (140, 39, 10, '2025-08-11 10:55:37', 14.20);
INSERT INTO `finger_blood_files` VALUES (141, 39, 10, '2025-08-11 11:07:32', 3.10);
INSERT INTO `finger_blood_files` VALUES (142, 39, 10, '2025-08-11 15:31:55', 10.00);
INSERT INTO `finger_blood_files` VALUES (143, 39, 10, '2025-08-11 17:12:43', 3.20);
INSERT INTO `finger_blood_files` VALUES (144, 39, 10, '2025-08-11 19:57:20', 9.30);
INSERT INTO `finger_blood_files` VALUES (145, 39, 10, '2025-08-11 20:39:32', 7.80);
INSERT INTO `finger_blood_files` VALUES (146, 39, 10, '2025-08-11 21:19:34', 12.60);
INSERT INTO `finger_blood_files` VALUES (147, 39, 10, '2025-08-12 01:37:33', 12.40);
INSERT INTO `finger_blood_files` VALUES (148, 39, 10, '2025-08-12 04:02:00', 4.20);
INSERT INTO `finger_blood_files` VALUES (149, 39, 10, '2025-08-12 04:13:29', 6.70);
INSERT INTO `finger_blood_files` VALUES (150, 39, 10, '2025-08-12 05:44:01', 4.70);
INSERT INTO `finger_blood_files` VALUES (151, 39, 10, '2025-08-12 11:56:55', 7.30);
INSERT INTO `finger_blood_files` VALUES (152, 39, 10, '2025-08-12 16:05:52', 8.00);
INSERT INTO `finger_blood_files` VALUES (153, 39, 10, '2025-08-12 17:50:40', 14.30);
INSERT INTO `finger_blood_files` VALUES (154, 39, 10, '2025-08-12 22:14:37', 4.60);
INSERT INTO `finger_blood_files` VALUES (155, 39, 10, '2025-08-13 00:26:48', 11.70);
INSERT INTO `finger_blood_files` VALUES (156, 39, 10, '2025-08-13 04:18:43', 11.90);
INSERT INTO `finger_blood_files` VALUES (157, 39, 10, '2025-08-13 05:28:08', 10.00);
INSERT INTO `finger_blood_files` VALUES (158, 39, 10, '2025-08-13 07:43:16', 10.00);
INSERT INTO `finger_blood_files` VALUES (159, 39, 10, '2025-08-13 11:09:23', 3.20);
INSERT INTO `finger_blood_files` VALUES (160, 39, 10, '2025-08-13 13:51:24', 13.80);
INSERT INTO `finger_blood_files` VALUES (161, 39, 10, '2025-08-13 19:10:00', 7.10);
INSERT INTO `finger_blood_files` VALUES (162, 39, 10, '2025-08-13 20:44:02', 10.90);
INSERT INTO `finger_blood_files` VALUES (163, 39, 10, '2025-08-14 06:00:10', 14.60);
INSERT INTO `finger_blood_files` VALUES (164, 39, 10, '2025-08-14 13:26:30', 4.30);
INSERT INTO `finger_blood_files` VALUES (165, 39, 10, '2025-08-14 16:03:12', 11.20);
INSERT INTO `finger_blood_files` VALUES (166, 39, 10, '2025-08-14 16:53:02', 8.20);
INSERT INTO `finger_blood_files` VALUES (167, 39, 10, '2025-08-14 17:34:01', 5.80);
INSERT INTO `finger_blood_files` VALUES (168, 39, 10, '2025-08-14 18:08:36', 8.30);
INSERT INTO `finger_blood_files` VALUES (169, 39, 10, '2025-08-14 19:34:28', 7.20);
INSERT INTO `finger_blood_files` VALUES (170, 39, 10, '2025-08-14 22:59:12', 7.40);
INSERT INTO `finger_blood_files` VALUES (171, 39, 10, '2025-08-15 01:46:01', 5.60);
INSERT INTO `finger_blood_files` VALUES (172, 39, 10, '2025-08-15 03:17:14', 10.70);
INSERT INTO `finger_blood_files` VALUES (173, 39, 10, '2025-08-15 04:03:30', 6.30);
INSERT INTO `finger_blood_files` VALUES (174, 39, 10, '2025-08-15 06:49:43', 12.10);
INSERT INTO `finger_blood_files` VALUES (175, 39, 10, '2025-08-15 14:51:55', 7.70);
INSERT INTO `finger_blood_files` VALUES (176, 39, 10, '2025-08-15 15:12:30', 5.20);
INSERT INTO `finger_blood_files` VALUES (177, 39, 10, '2025-08-15 20:38:29', 10.00);
INSERT INTO `finger_blood_files` VALUES (178, 39, 10, '2025-08-15 22:59:27', 14.40);
INSERT INTO `finger_blood_files` VALUES (179, 39, 10, '2025-08-16 00:13:34', 6.50);
INSERT INTO `finger_blood_files` VALUES (180, 39, 10, '2025-08-16 09:02:04', 13.60);
INSERT INTO `finger_blood_files` VALUES (181, 39, 10, '2025-08-16 09:27:49', 11.40);
INSERT INTO `finger_blood_files` VALUES (182, 39, 10, '2025-08-16 10:36:34', 3.20);
INSERT INTO `finger_blood_files` VALUES (183, 39, 10, '2025-08-16 14:49:40', 9.20);
INSERT INTO `finger_blood_files` VALUES (184, 39, 10, '2025-08-16 16:41:02', 8.20);
INSERT INTO `finger_blood_files` VALUES (185, 39, 10, '2025-08-16 17:10:32', 10.20);
INSERT INTO `finger_blood_files` VALUES (186, 39, 10, '2025-08-16 20:41:48', 9.80);
INSERT INTO `finger_blood_files` VALUES (187, 39, 10, '2025-08-17 00:09:44', 10.40);
INSERT INTO `finger_blood_files` VALUES (188, 39, 10, '2025-08-17 09:52:59', 13.00);
INSERT INTO `finger_blood_files` VALUES (189, 39, 10, '2025-08-17 10:14:22', 10.20);
INSERT INTO `finger_blood_files` VALUES (190, 39, 10, '2025-08-17 11:53:23', 8.00);
INSERT INTO `finger_blood_files` VALUES (191, 39, 10, '2025-08-17 16:39:57', 5.20);
INSERT INTO `finger_blood_files` VALUES (192, 39, 10, '2025-08-17 21:43:59', 12.50);
INSERT INTO `finger_blood_files` VALUES (193, 39, 10, '2025-08-17 22:52:39', 3.50);
INSERT INTO `finger_blood_files` VALUES (194, 39, 10, '2025-08-17 23:39:45', 9.30);
INSERT INTO `finger_blood_files` VALUES (195, 39, 10, '2025-08-18 02:33:44', 5.60);
INSERT INTO `finger_blood_files` VALUES (196, 39, 10, '2025-08-18 03:29:52', 8.20);
INSERT INTO `finger_blood_files` VALUES (197, 39, 10, '2025-08-18 05:39:47', 7.20);
INSERT INTO `finger_blood_files` VALUES (198, 39, 10, '2025-08-18 10:11:52', 5.90);
INSERT INTO `finger_blood_files` VALUES (199, 39, 10, '2025-08-18 14:05:51', 14.80);
INSERT INTO `finger_blood_files` VALUES (200, 39, 10, '2025-08-18 19:34:30', 10.70);
INSERT INTO `finger_blood_files` VALUES (201, 39, 10, '2025-08-18 20:33:47', 10.10);
INSERT INTO `finger_blood_files` VALUES (202, 39, 10, '2025-08-18 21:45:42', 13.50);

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
INSERT INTO `persons` VALUES (23, '尤二十三', 'Female', 23, 4);
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
INSERT INTO `persons` VALUES (34, '123123', NULL, NULL, 9);
INSERT INTO `persons` VALUES (35, '24444', NULL, NULL, 9);
INSERT INTO `persons` VALUES (36, '小明', 'Female', 34, 10);
INSERT INTO `persons` VALUES (38, '小俊', 'Male', 25, 10);
INSERT INTO `persons` VALUES (39, '小华', 'Male', 23, 10);

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
-- Records of sensor_details
-- ----------------------------
INSERT INTO `sensor_details` VALUES (1, '2024-05-17', '7-003-49', 'E051501', 0.0000, 2.7100, 6.9200, 40.6700, 1.5367160000, 0.9916904170, '去向1', '0619A', '2025-08-08 10:00:01');
INSERT INTO `sensor_details` VALUES (2, '2024-05-17', '7-003-54', 'E051503', 0.0000, 2.9200, 7.2700, 35.3400, 1.5015540000, 0.9960834830, '去向2', '0619B', '2025-08-08 10:00:01');
INSERT INTO `sensor_details` VALUES (3, '2025-08-08', '7-003-59', '09002', 4.0000, 2.0000, 4.0000, 5.0000, 4.0000000000, 1.0000000000, '213124', '', '2025-08-08 10:33:45');
INSERT INTO `sensor_details` VALUES (60, '2025-06-27', '5-007-12', 'D061706', 0.0000, 3.6300, 8.5500, 30.8700, 1.5200000000, 0.9940860000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (61, '2025-06-27', '5-007-04', 'C061704', 0.0000, 3.6800, 8.6600, 31.2800, 1.5200000000, 0.9941550000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (62, '2025-06-27', '5-007-02', 'C061702', 0.0000, 3.8100, 8.9500, 32.1600, 1.5700000000, 0.9938300000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (63, '2025-06-27', '5-007-48', 'B061806', 0.0000, 4.0400, 9.5200, 34.3500, 1.7000000000, 0.9939900000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (64, '2025-06-27', '5-007-03', 'C061703', 0.0000, 4.1500, 9.6900, 33.6300, 1.6900000000, 0.9926070000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (65, '2025-06-27', '5-007-47', 'B061805', 0.0000, 4.1100, 9.7200, 35.5500, 1.7200000000, 0.9946990000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (66, '2025-06-27', '5-007-46', 'B061804', 0.0000, 4.1400, 9.7300, 34.8500, 1.7100000000, 0.9938900000, NULL, '已经坏了', '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (67, '2025-06-27', '5-006-36', 'I061710', 0.0000, 4.2300, 10.0200, 37.1100, 1.7600000000, 0.9950280000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (68, '2025-06-27', '5-007-01', 'C061701', 0.0000, 4.3000, 10.0600, 35.1500, 1.7600000000, 0.9928450000, NULL, '嘻嘻哈哈', '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (69, '2025-06-27', '5-007-38', 'A061802', 0.0000, 4.2500, 10.1400, 38.9800, 1.8300000000, 0.9963410000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (70, '2025-06-27', '5-007-10', 'D061704', 0.0000, 4.2700, 10.1700, 38.4900, 1.8400000000, 0.9957360000, NULL, '不知道了', '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (71, '2025-06-27', '5-007-42', 'A061806', 0.0000, 4.3700, 10.2200, 35.8500, 1.8100000000, 0.9925780000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (72, '2025-06-27', '5-007-39', 'A061803', 0.0000, 4.3200, 10.2400, 38.1600, 1.8200000000, 0.9954270000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (73, '2025-06-27', '5-007-09', 'D061703', 0.0000, 4.3100, 10.2600, 38.9800, 1.8700000000, 0.9957770000, NULL, NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (74, '2025-06-27', '5-007-11', 'D061705', 0.0000, 4.3600, 10.3300, 38.4900, 1.8400000000, 0.9954180000, '测试', NULL, '2025-08-19 10:50:01');
INSERT INTO `sensor_details` VALUES (75, '2025-08-21', '5-007-88', '	 D061777', 3.0000, 4.0000, 5.0000, 6.0000, 45.0000000000, 1.0000000000, '', '测试一下添加', '2025-08-21 11:36:58');

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
  `start_time` date NULL DEFAULT (curdate()) COMMENT '佩戴记录创建时间',
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
) ENGINE = InnoDB AUTO_INCREMENT = 25 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '传感器管理表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sensors
-- ----------------------------
INSERT INTO `sensors` VALUES (7, 2, 1, 2, '1225070901\r\n', '7-003-54', '7-003-54', 'CGMS1002CDB0', '2025-07-05', NULL, NULL);
INSERT INTO `sensors` VALUES (11, 36, 10, 73, '1225070901', '5-007-09', '5-007-09', 'CGMS10B57696', '2025-08-19', '2025-08-22', '');
INSERT INTO `sensors` VALUES (12, 36, 10, 71, '1225070901', '5-007-42', '5-007-42', 'CGMS1002CDB0', '2025-08-20', '2025-08-24', '');
INSERT INTO `sensors` VALUES (15, 26, 1, 69, '1-1', '5-007-38', '5-007-38', '12124', '2025-08-20', NULL, NULL);
INSERT INTO `sensors` VALUES (16, 2, 1, 75, '467365765', '5-007-88', '5-007-88', 'CGM5458967', '2025-08-21', NULL, NULL);
INSERT INTO `sensors` VALUES (23, 36, 10, 1, '6457656', '7-003-49', '7-003-49', 'CGM6868787', '2025-08-08', '2025-08-26', '');
INSERT INTO `sensors` VALUES (24, 36, 10, 3, '787676', '7-003-59', '7-003-59', 'CGM775878897', '2025-08-08', '2025-08-26', '');

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
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, 'admin', '$2b$12$OrEfSmkameHVVRayq/Y4BORSYxWXbu0P8H135ZlkduYFGo3Wr8VCG', 'Admin', '2025-07-23 19:12:57', '2025-07-23 12:30:03');
INSERT INTO `users` VALUES (2, 'test', '$2b$12$60QG7BG0S3XqhfkqkoeVM.fRylsA8plpnjA7Em2HTJc74ZYHA56Ci', 'User', '2025-07-23 11:14:45', '2025-07-23 11:14:45');
INSERT INTO `users` VALUES (3, 'test1', '$2b$12$V7gMAszAdAi/hy0n3.Ph5eIWvErYegHNhZqpUNgz1YVEpCEn5vDiS', 'User', '2025-07-23 17:01:22', '2025-07-23 17:01:22');
INSERT INTO `users` VALUES (4, 'test2', '$2b$12$WFWLtNoMtGGuuleu5bU0pOFVIr3WuINmDakZqOf4KeW82nVVFR5/i', 'User', '2025-07-24 11:30:49', '2025-07-24 11:30:49');

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
  `wear_time` date NULL DEFAULT (curdate()) COMMENT '佩戴记录创建时间',
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
) ENGINE = InnoDB AUTO_INCREMENT = 54 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '人员传感器佩戴记录表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of wear_records
-- ----------------------------
INSERT INTO `wear_records` VALUES (39, 1, 26, 15, 69, '2', '1-1', '5-007-38', '5-007-38', '12124', 'adada', '2025-08-20', NULL, '左一', 'adada', '', '');
INSERT INTO `wear_records` VALUES (42, 10, 36, 12, 71, '测试一下', '1225070901', '5-007-42', '5-007-42', 'CGMS1002CDB0', '0068', '2025-08-21', '2025-08-24', '左一', '小明', '', '');
INSERT INTO `wear_records` VALUES (43, 10, 36, 11, 73, '测试哈', '1225070901', '5-007-09', '5-007-09', 'CGMS10B57696', '0069', '2025-08-21', '2025-08-22', '左二', '小明', '', '');
INSERT INTO `wear_records` VALUES (45, 1, 2, 7, 2, '', '1225070901\r\n', '7-003-54', '7-003-54', 'CGMS1002CDB0', '李四', '2025-08-21', NULL, '左一', '李四', '', '');
INSERT INTO `wear_records` VALUES (46, 1, 2, 16, 75, '4463463', '467365765', '5-007-88', '5-007-88', 'CGM5458967', '0098', '2025-08-21', NULL, '左二', '李四', '', '');
INSERT INTO `wear_records` VALUES (52, 10, 36, 23, 1, '67676767', '6457656', '7-003-49', '7-003-49', 'CGM6868787', '0078', '2025-08-08', '2025-08-26', '右一', '小明', '', '');
INSERT INTO `wear_records` VALUES (53, 10, 36, 24, 3, '6778746567', '787676', '7-003-59', '7-003-59', 'CGM775878897', '0069', '2025-08-08', '2025-08-26', '右二', '小明', '', '');

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
    -- 删除传感器管理表中关联的传感器记录
    DELETE FROM `sensors` 
    WHERE `sensor_id` = OLD.sensor_id;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
