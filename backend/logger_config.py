import logging
import logging.handlers
import os
from datetime import datetime

def setup_logger():
    """
    配置应用程序日志记录器
    - 日志文件大小限制：50MB
    - 自动轮转：保留5个备份文件
    - 日志级别：INFO
    - 格式：时间戳 - 日志级别 - 模块名 - 消息
    """
    
    # 创建logs目录
    log_dir = os.path.join(os.path.dirname(__file__), "logs")
    os.makedirs(log_dir, exist_ok=True)
    
    # 日志文件路径
    log_file = os.path.join(log_dir, "app.log")
    
    # 创建根日志记录器
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # 如果已经配置过处理器，则不重复配置
    if logger.handlers:
        return logger
    
    # 创建文件处理器（带轮转功能）
    # maxBytes=50MB, backupCount=5 表示保留5个备份文件
    file_handler = logging.handlers.RotatingFileHandler(
        filename=log_file,
        maxBytes=50 * 1024 * 1024,  # 50MB
        backupCount=5,
        encoding='utf-8'
    )
    file_handler.setLevel(logging.INFO)
    
    # 创建控制台处理器
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    
    # 创建格式化器
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(name)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # 设置格式化器
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    # 添加处理器到日志记录器
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

def get_logger(name: str = None):
    """
    获取指定名称的日志记录器
    
    Args:
        name: 日志记录器名称，通常使用 __name__
    
    Returns:
        logging.Logger: 配置好的日志记录器
    """
    return logging.getLogger(name)

# 应用启动时的日志记录
def log_startup_info():
    """
    记录应用启动信息
    """
    logger = get_logger(__name__)
    logger.info("="*50)
    logger.info("实验数据管理系统后端启动")
    logger.info(f"启动时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info(f"日志配置: 文件大小限制50MB，保留5个备份")
    logger.info("="*50)

# 应用关闭时的日志记录
def log_shutdown_info():
    """
    记录应用关闭信息
    """
    logger = get_logger(__name__)
    logger.info("="*50)
    logger.info("实验数据管理系统后端关闭")
    logger.info(f"关闭时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("="*50)