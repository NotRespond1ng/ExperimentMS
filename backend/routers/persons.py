from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from database import get_db
from models import Person, Batch, User, ExperimentMember, WearRecord, Experiment
from schemas import PersonCreate, PersonUpdate, PersonResponse, MessageResponse, BatchResponse
from routers.auth import get_current_user, check_module_permission
from models import ModuleEnum

router = APIRouter(prefix="/api/persons", tags=["人员管理"])

@router.get("/batches", response_model=List[BatchResponse])
def get_batches_for_person(
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.PERSON_MANAGEMENT, "read"))
):
    """获取可选择的批次列表"""
    batches = db.query(Batch).all()
    return batches

@router.get("/", response_model=List[PersonResponse])
def get_persons(
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(100, ge=1, le=1000, description="返回的记录数"),
    search: Optional[str] = Query(None, description="按姓名搜索"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.PERSON_MANAGEMENT, "read"))
):
    """获取人员列表"""
    query = db.query(Person).options(joinedload(Person.batch))
    
    if search:
        query = query.filter(Person.person_name.contains(search))
    
    persons = query.offset(skip).limit(limit).all()
    
    # 构建返回结果，包含批次信息
    result = []
    for person in persons:
        person_dict = {
            "person_id": person.person_id,
            "person_name": person.person_name,
            "gender": person.gender,
            "age": person.age,
            "batch_id": person.batch_id,
            "batch_number": person.batch.batch_number if person.batch else None
        }
        result.append(PersonResponse(**person_dict))
    
    return result

@router.post("/", response_model=PersonResponse)
def create_person(
    person: PersonCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.PERSON_MANAGEMENT, "write"))
):
    """添加新人员"""
    db_person = Person(**person.dict())
    db.add(db_person)
    
    try:
        # 先提交人员信息以获取person_id
        db.commit()
        db.refresh(db_person)
        
        # 如果新建的人员有batch_id，自动将该人员添加到该批次对应的所有实验中
        if db_person.batch_id:
            experiments = db.query(Experiment).filter(Experiment.batch_id == db_person.batch_id).all()
            for experiment in experiments:
                # 检查是否已经存在该成员记录，避免重复添加
                existing_member = db.query(ExperimentMember).filter(
                    ExperimentMember.experiment_id == experiment.experiment_id,
                    ExperimentMember.person_id == db_person.person_id
                ).first()
                
                if not existing_member:
                    # 添加新的实验成员记录
                    new_member = ExperimentMember(
                        experiment_id=experiment.experiment_id,
                        person_id=db_person.person_id
                    )
                    db.add(new_member)
            
            # 提交实验成员关系的更改
            db.commit()
        
        return db_person
        
    except Exception as e:
        # 如果出现错误，回滚事务
        db.rollback()
        raise HTTPException(status_code=500, detail=f"创建人员时发生错误: {str(e)}")

@router.get("/{person_id}", response_model=PersonResponse)
def get_person(
    person_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.PERSON_MANAGEMENT, "read"))
):
    """获取单个人员详情"""
    person = db.query(Person).filter(Person.person_id == person_id).first()
    if not person:
        raise HTTPException(status_code=404, detail="人员不存在")
    return person

@router.put("/{person_id}", response_model=PersonResponse)
def update_person(
    person_id: int,
    person: PersonUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.PERSON_MANAGEMENT, "write"))
):
    """更新人员信息"""
    db_person = db.query(Person).filter(Person.person_id == person_id).first()
    if not db_person:
        raise HTTPException(status_code=404, detail="人员不存在")
    
    # 获取旧的batch_id用于后续比较
    old_batch_id = db_person.batch_id
    
    # 更新人员信息
    update_data = person.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_person, field, value)
    
    # 检查batch_id是否发生变化
    new_batch_id = getattr(db_person, 'batch_id', old_batch_id)
    
    try:
        # 如果batch_id发生变化，需要同步更新实验成员关系
        if old_batch_id != new_batch_id:
            # 从旧批次对应的实验中移除该人员
            if old_batch_id:
                old_experiments = db.query(Experiment).filter(Experiment.batch_id == old_batch_id).all()
                for experiment in old_experiments:
                    # 移除该人员的实验成员记录
                    db.query(ExperimentMember).filter(
                        ExperimentMember.experiment_id == experiment.experiment_id,
                        ExperimentMember.person_id == person_id
                    ).delete()
            
            # 将该人员添加到新批次对应的实验中
            if new_batch_id:
                new_experiments = db.query(Experiment).filter(Experiment.batch_id == new_batch_id).all()
                for experiment in new_experiments:
                    # 检查是否已经存在该成员记录，避免重复添加
                    existing_member = db.query(ExperimentMember).filter(
                        ExperimentMember.experiment_id == experiment.experiment_id,
                        ExperimentMember.person_id == person_id
                    ).first()
                    
                    if not existing_member:
                        # 添加新的实验成员记录
                        new_member = ExperimentMember(
                            experiment_id=experiment.experiment_id,
                            person_id=person_id
                        )
                        db.add(new_member)
        
        # 提交所有更改
        db.commit()
        db.refresh(db_person)
        
        return db_person
        
    except Exception as e:
        # 如果出现错误，回滚事务
        db.rollback()
        raise HTTPException(status_code=500, detail=f"更新人员信息时发生错误: {str(e)}")

@router.delete("/{person_id}", response_model=MessageResponse)
def delete_person(
    person_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.PERSON_MANAGEMENT, "delete"))
):
    """删除人员"""
    db_person = db.query(Person).filter(Person.person_id == person_id).first()
    if not db_person:
        raise HTTPException(status_code=404, detail="人员不存在")
    
    # 检查是否有关联的数据，并统计数量
    error_details = []
    
    # 检查实验成员关联
    experiment_members_count = db.query(ExperimentMember).filter(ExperimentMember.person_id == person_id).count()
    if experiment_members_count > 0:
        error_details.append(f"实验记录{experiment_members_count}条")
    
    # 检查佩戴记录关联
    wear_records_count = db.query(WearRecord).filter(WearRecord.person_id == person_id).count()
    if wear_records_count > 0:
        error_details.append(f"佩戴记录{wear_records_count}条")
    
    # 检查竞品文件关联
    competitor_files_count = len(db_person.competitor_files) if db_person.competitor_files else 0
    if competitor_files_count > 0:
        error_details.append(f"竞品文件{competitor_files_count}个")
    
    # 检查指血文件关联
    finger_blood_files_count = len(db_person.finger_blood_files) if db_person.finger_blood_files else 0
    if finger_blood_files_count > 0:
        error_details.append(f"指血文件{finger_blood_files_count}个")
    
    # 检查传感器关联
    sensors_count = len(db_person.sensors) if db_person.sensors else 0
    if sensors_count > 0:
        error_details.append(f"传感器{sensors_count}个")
    
    # 如果有关联数据，返回详细错误信息
    if error_details:
        detail_message = f"无法删除该人员，存在以下关联数据：{', '.join(error_details)}"
        raise HTTPException(status_code=400, detail=detail_message)
    
    db.delete(db_person)
    db.commit()
    return MessageResponse(message="人员删除成功")