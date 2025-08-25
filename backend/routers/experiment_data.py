from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
import pandas as pd
import io
from datetime import datetime

from database import get_db
from models import DailyExperimentData, Batch, Person, User, ModuleEnum
from schemas import DailyExperimentDataResponse, ExperimentDataSummary, BatchResponse, PersonResponse, UploadResponse
from datetime import date
from logging_setup import get_logger
from routers.auth import check_module_permission

router = APIRouter(prefix="/api/experimentData", tags=["实验数据分析"])
logger = get_logger(__name__)

@router.get("/batches", response_model=List[BatchResponse])
def get_batches(
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.EXPERIMENT_DATA_ANALYSIS, "read"))
):
    """获取所有实验批次"""
    try:
        batches = db.query(Batch).all()
        return batches
    except Exception as e:
        logger.error(f"获取批次列表失败: {str(e)}")
        raise HTTPException(status_code=500, detail="获取批次列表失败")

@router.get("/batches-with-data", response_model=List[BatchResponse])
def get_batches_with_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.EXPERIMENT_DATA_ANALYSIS, "read"))
):
    """获取有实验数据的批次列表"""
    try:
        # 查询有实验数据的批次
        batches_with_data = db.query(Batch).join(
            DailyExperimentData, Batch.batch_id == DailyExperimentData.batch_id
        ).distinct().all()
        
        return batches_with_data
    except Exception as e:
        logger.error(f"获取有数据的批次列表失败: {str(e)}")
        raise HTTPException(status_code=500, detail="获取有数据的批次列表失败")

@router.get("/persons", response_model=List[PersonResponse])
def get_persons_by_batch(
    batch_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.EXPERIMENT_DATA_ANALYSIS, "read"))
):
    """根据批次ID获取人员列表"""
    try:
        persons = db.query(Person).filter(Person.batch_id == batch_id).all()
        return persons
    except Exception as e:
        logger.error(f"获取人员列表失败: {str(e)}")
        raise HTTPException(status_code=500, detail="获取人员列表失败")

@router.get("/persons-with-data", response_model=List[PersonResponse])
def get_persons_with_data_by_batch(
    batch_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.EXPERIMENT_DATA_ANALYSIS, "read"))
):
    """根据批次ID获取有实验数据的人员列表"""
    try:
        # 查询有实验数据的人员
        persons_with_data = db.query(Person).join(
            DailyExperimentData, Person.person_id == DailyExperimentData.person_id
        ).filter(
            Person.batch_id == batch_id
        ).distinct().all()
        
        return persons_with_data
    except Exception as e:
        logger.error(f"获取有数据的人员列表失败: {str(e)}")
        raise HTTPException(status_code=500, detail="获取有数据的人员列表失败")

@router.get("/data", response_model=ExperimentDataSummary)
def get_experiment_data(
    person_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.EXPERIMENT_DATA_ANALYSIS, "read"))
):
    """获取指定人员的每日MARD/PARD数据及总体平均值"""
    try:
        # 获取每日数据
        daily_data = db.query(DailyExperimentData).filter(
            DailyExperimentData.person_id == person_id
        ).order_by(DailyExperimentData.experiment_day).all()
        
        # 即使没有数据也返回空结果，不报错
        if not daily_data:
            return {
                "daily_data": [],
                "avg_mard": 0.0,
                "avg_pard": 0.0
            }
        
        # 计算总平均值
        mard_values = [data.mard_value for data in daily_data if data.mard_value is not None]
        pard_values = [data.pard_value for data in daily_data if data.pard_value is not None]
        
        avg_mard = sum(mard_values) / len(mard_values) if mard_values else 0
        avg_pard = sum(pard_values) / len(pard_values) if pard_values else 0
        
        return {
            "daily_data": daily_data,
            "avg_mard": round(avg_mard, 5),
            "avg_pard": round(avg_pard, 5)
        }
    except Exception as e:
        logger.error(f"获取实验数据失败: {str(e)}")
        raise HTTPException(status_code=500, detail="获取实验数据失败")

@router.post("/upload")
async def upload_experiment_data(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.EXPERIMENT_DATA_ANALYSIS, "write"))
):
    """上传并处理Excel实验数据文件"""
    try:
        # 验证文件类型
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise HTTPException(status_code=400, detail="文件格式错误，请上传Excel文件")
        
        # 读取Excel文件
        contents = await file.read()
        df = pd.read_excel(io.BytesIO(contents))
        
        processed_rows = 0
        
        # 解析Excel数据（这里需要根据实际Excel格式调整）
        # 假设Excel格式：批次号、姓名、实验天数、MARD值、PARD值、记录日期
        for index, row in df.iterrows():
            try:
                # 根据批次号和姓名查找对应的ID
                batch = db.query(Batch).filter(Batch.batch_number == str(row['批次号'])).first()
                if not batch:
                    logger.warning(f"未找到批次: {row['批次号']}")
                    continue
                
                person = db.query(Person).filter(
                    Person.person_name == str(row['姓名']),
                    Person.batch_id == batch.batch_id
                ).first()
                if not person:
                    logger.warning(f"未找到人员: {row['姓名']}")
                    continue
                
                # 检查是否已存在该记录
                existing_data = db.query(DailyExperimentData).filter(
                    DailyExperimentData.person_id == person.person_id,
                    DailyExperimentData.experiment_day == int(row['实验天数'])
                ).first()
                
                if existing_data:
                    # 更新现有记录
                    existing_data.mard_value = float(row['MARD值']) if pd.notna(row['MARD值']) else None
                    existing_data.pard_value = float(row['PARD值']) if pd.notna(row['PARD值']) else None
                    existing_data.record_date = pd.to_datetime(row['记录日期']).date()
                else:
                    # 创建新记录
                    record_date = pd.to_datetime(row['记录日期']).date() if pd.notna(row['记录日期']) else date.today()
                    new_data = DailyExperimentData(
                        person_id=person.person_id,
                        batch_id=batch.batch_id,
                        experiment_day=int(row['实验天数']),
                        mard_value=float(row['MARD值']) if pd.notna(row['MARD值']) else None,
                        pard_value=float(row['PARD值']) if pd.notna(row['PARD值']) else None,
                        record_date=record_date
                    )
                    db.add(new_data)
                
                processed_rows += 1
                
            except Exception as row_error:
                logger.error(f"处理第{index+1}行数据时出错: {str(row_error)}")
                continue
        
        db.commit()
        
        return {
            "message": "文件导入成功",
            "processed_rows": processed_rows
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"文件上传处理失败: {str(e)}")
        raise HTTPException(status_code=400, detail=f"文件格式错误或内容无法解析: {str(e)}")