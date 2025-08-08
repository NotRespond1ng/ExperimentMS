from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from database import get_db
from models import Activity, User
from schemas import ActivityResponse, ActivityCreate
from routers.auth import get_current_user

router = APIRouter(prefix="/api/activities", tags=["activities"])

@router.get("/", response_model=List[ActivityResponse])
def get_activities(
    limit: int = 10,  # 减少默认查询数量
    skip: int = 0,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取最近活动列表
    """
    # 限制最大查询数量，防止性能问题
    limit = min(limit, 50)
    
    # 优化查询：只选择需要的字段，减少数据传输
    activities = (
        db.query(
            Activity.activity_id,
            Activity.activity_type,
            Activity.description,
            Activity.createTime,
            Activity.user_id,
            User.username
        )
        .outerjoin(User, Activity.user_id == User.user_id)
        .order_by(Activity.createTime.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    
    # 直接构建响应，避免额外的对象创建
    result = [
        ActivityResponse(
            activity_id=activity.activity_id,
            activity_type=activity.activity_type,
            description=activity.description,
            createTime=activity.createTime,
            user_id=activity.user_id,
            username=activity.username
        )
        for activity in activities
    ]
    
    return result

@router.post("/", response_model=ActivityResponse)
def create_activity(
    activity: ActivityCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    创建新的活动记录
    """
    db_activity = Activity(
        activity_type=activity.activity_type,
        description=activity.description,
        user_id=activity.user_id,
        createTime=datetime.now()
    )
    
    db.add(db_activity)
    db.commit()
    db.refresh(db_activity)
    
    # 获取用户名
    username = None
    if db_activity.user_id:
        user = db.query(User).filter(User.user_id == db_activity.user_id).first()
        username = user.username if user else None
    
    return ActivityResponse(
        activity_id=db_activity.activity_id,
        activity_type=db_activity.activity_type,
        description=db_activity.description,
        createTime=db_activity.createTime,
        user_id=db_activity.user_id,
        username=username
    )

def log_activity(db: Session, activity_type: str, description: str, user_id: Optional[int] = None):
    """
    记录活动的辅助函数
    """
    activity = Activity(
        activity_type=activity_type,
        description=description,
        user_id=user_id,
        createTime=datetime.now()
    )
    db.add(activity)
    db.commit()
    return activity