import logging
import logging.config
import os
import yaml
from datetime import datetime


def setup_logger():
    """
    从 YAML 文件加载配置，并动态设置日志文件路径，
    确保在多进程环境下（如 Uvicorn workers）日志记录安全。
    """
    # 1. 定义日志配置文件和日志文件的路径
    # __file__ 是当前脚本的路径 (logging_setup.py)
    # os.path.dirname(__file__) 是当前脚本所在的目录
    base_dir = os.path.dirname(os.path.abspath(__file__))
    log_config_path = os.path.join(base_dir, "log_config.yaml")
    log_dir = os.path.join(base_dir, "logs")
    
    # 确保 logs 目录存在
    os.makedirs(log_dir, exist_ok=True)
    
    # 日志文件的完整路径
    log_file_path = os.path.join(log_dir, "app.log")

    # 2. 读取 YAML 配置文件
    if os.path.exists(log_config_path):
        with open(log_config_path, 'r', encoding='utf-8') as f:
            # 使用 safe_load 防止执行任意代码
            config = yaml.safe_load(f)

        # 3. 动态修改配置字典，将日志文件名替换为绝对路径
        # 这样做可以避免在不同工作目录下运行程序时出现路径问题
        # 同时为所有 handler 设置统一的、进程安全的文件写入器
        if 'handlers' in config:
            for handler_name in config['handlers']:
                handler_config = config['handlers'][handler_name]
                # 检查 handler 是否是用于文件输出的类型
                if 'filename' in handler_config:
                    handler_config['filename'] = log_file_path
        
        # 4. 应用配置
        logging.config.dictConfig(config)
        
        # 获取根 logger 并添加一个初始信息
        root_logger = logging.getLogger()
        root_logger.info("日志系统配置完成，使用进程安全的 ConcurrentRotatingFileHandler。")

    else:
        # 如果找不到配置文件，则进行基本的日志配置以避免程序崩溃
        logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s')
        logging.warning(f"警告：未找到日志配置文件 {log_config_path}，已启用基本日志配置。")

def get_logger(name: str = None) -> logging.Logger:
    """
    获取指定名称的日志记录器。
    这是对 logging.getLogger 的一个简单封装，以保持 API 一致性。
    
    Args:
        name: 日志记录器名称，通常传入 __name__
    
    Returns:
        配置好的日志记录器实例
    """
    return logging.getLogger(name)

def log_startup_info():
    """
    记录应用启动信息。
    """
    logger = get_logger(__name__)
    logger.info("=" * 60)
    logger.info("实验数据管理系统后端启动")
    logger.info(f"启动时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info(f"日志配置: 统一输出到 app.log, 进程安全, 大小限制50MB, 保留5个备份")
    logger.info("=" * 60)

def log_shutdown_info():
    """
    记录应用关闭信息。
    """
    logger = get_logger(__name__)
    logger.info("=" * 60)
    logger.info("实验数据管理系统后端关闭")
    logger.info(f"关闭时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 60)