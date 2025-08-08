from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from models import Batch, Person, Experiment, FingerBloodFile, User, ModuleEnum
from routers.auth import check_module_permission
from pydantic import BaseModel

router = APIRouter(
    prefix="/api/stats",
    tags=["统计"]
)

class DashboardStatsResponse(BaseModel):
    """首页统计数据响应模型"""
    batches_count: int
    persons_count: int
    experiments_count: int
    finger_blood_data_count: int

@router.get("/dashboard", response_model=DashboardStatsResponse)
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.BATCH_MANAGEMENT, "read"))
):
    """获取首页统计数据"""
    try:
        # 获取各种数据的数量统计
        batches_count = db.query(func.count(Batch.batch_id)).scalar() or 0
        persons_count = db.query(func.count(Person.person_id)).scalar() or 0
        experiments_count = db.query(func.count(Experiment.experiment_id)).scalar() or 0
        finger_blood_data_count = db.query(func.count(FingerBloodFile.finger_blood_file_id)).scalar() or 0
        
        return DashboardStatsResponse(
            batches_count=batches_count,
            persons_count=persons_count,
            experiments_count=experiments_count,
            finger_blood_data_count=finger_blood_data_count
        )
    except Exception as e:
        # 如果查询失败，返回默认值
        return DashboardStatsResponse(
            batches_count=0,
            persons_count=0,
            experiments_count=0,
            finger_blood_data_count=0
        )