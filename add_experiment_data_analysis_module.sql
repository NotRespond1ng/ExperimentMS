/*
 * 实验数据分析模块权限控制 SQL 脚本
 * 功能：为用户权限管理系统添加 EXPERIMENT_DATA_ANALYSIS 模块
 * 创建日期：2025-01-25
 */

-- 1. 修改 user_permissions 表的 module 枚举，添加 'EXPERIMENT_DATA_ANALYSIS' 选项
ALTER TABLE `user_permissions` 
MODI