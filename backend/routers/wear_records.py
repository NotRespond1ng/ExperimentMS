from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload, contains_eager
from typing import List, Optional
from datetime import datetime
from database import get_db
from models import WearRecord, Batch, Person, SensorDetail, Sensor, User
from schemas import WearRecordCreate, WearRecordUpdate, WearRecordResponse, MessageResponse, SensorDetailResponse
from routers.auth import get_current_user, check_module_permission
from models import ModuleEnum

router = APIRouter(prefix="/api/wearRecords", tags=["佩戴记录管理"])

@router.get("/used-sensors", response_model=List[int])
def get_used_sensors(
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "read"))
):
    """获取正在被佩戴的传感器的详细信息ID列表 (sensor_detail_id)"""
    active_wear_records = db.query(WearRecord.sensor_id)\
        .filter(WearRecord.wear_end_time.is_(None))\
        .distinct()

    used_sensor_detail_ids = db.query(Sensor.sensor_detail_id)\
        .filter(Sensor.sensor_id.in_(active_wear_records), Sensor.sensor_detail_id.isnot(None))\
        .distinct().all()

    return [sensor_detail_id[0] for sensor_detail_id in used_sensor_detail_ids]

@router.get("/", response_model=List[WearRecordResponse])
def get_wear_records(
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(1000, ge=1, le=1000, description="返回的记录数"),
    batch_id: Optional[int] = Query(None, description="按批次筛选"),
    person_id: Optional[int] = Query(None, description="按人员筛选"),
    sensor_id: Optional[int] = Query(None, description="按传感器详细信息筛选"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "read"))
):
    """获取佩戴记录列表"""
    query = db.query(WearRecord)\
        .outerjoin(WearRecord.batch)\
        .outerjoin(WearRecord.person)\
        .outerjoin(WearRecord.sensor)\
        .outerjoin(Sensor.sensor_detail)\
        .options(
            contains_eager(WearRecord.batch),
            contains_eager(WearRecord.person),
            contains_eager(WearRecord.sensor).contains_eager(Sensor.sensor_detail)
        )
    
    if batch_id:
        query = query.filter(WearRecord.batch_id == batch_id)
    
    if person_id:
        query = query.filter(WearRecord.person_id == person_id)
    
    if sensor_id:
        query = query.filter(WearRecord.sensor_id == sensor_id)
    
    wear_records = query.order_by(WearRecord.wear_time.desc()).offset(skip).limit(limit).all()
    
    result = []
    for record in wear_records:
        sensor_detail_data = None
        if record.sensor and record.sensor.sensor_detail:
            sensor_detail_data = SensorDetailResponse.from_orm(record.sensor.sensor_detail)
        
        record_dict = {
            "wear_record_id": record.wear_record_id,
            "batch_id": record.batch_id,
            "person_id": record.person_id,
            "sensor_id": record.sensor_id,
            "sensor_detail_id": record.sensor_detail_id,
            "applicator_lot_no": record.applicator_lot_no,
            "sensor_lot_no": record.sensor_lot_no,
            "sensor_batch": record.sensor_batch,
            "sensor_number": record.sensor_number,
            "transmitter_id": record.transmitter_id,
            "wear_position": record.wear_position,
            "nickname": record.nickname,
            "user_name": record.user_name,
            "abnormal_situation": record.abnormal_situation,
            "cause_analysis": record.cause_analysis,
            "wear_time": record.wear_time,
            "wear_end_time": record.wear_end_time,
            "person_name": record.person.person_name if record.person else None,
            "batch_number": record.batch.batch_number if record.batch else None,
            "test_number": record.sensor.sensor_detail.test_number if record.sensor and record.sensor.sensor_detail else None,
            "probe_number": record.sensor.sensor_detail.probe_number if record.sensor and record.sensor.sensor_detail else None,
            "sensor_detail": sensor_detail_data
        }
        result.append(WearRecordResponse(**record_dict))
    
    return result

@router.post("/", response_model=WearRecordResponse)
def create_wear_record(
    wear_record: WearRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "write"))
):
    """新增佩戴记录"""
    batch = db.query(Batch).filter(Batch.batch_id == wear_record.batch_id).first()
    if not batch:
        raise HTTPException(status_code=400, detail="指定的批次不存在")
    
    person = db.query(Person).filter(Person.person_id == wear_record.person_id).first()
    if not person:
        raise HTTPException(status_code=400, detail="指定的人员不存在")
    
    sensor = db.query(Sensor).options(joinedload(Sensor.sensor_detail)).filter(Sensor.sensor_id == wear_record.sensor_id).first()
    if not sensor:
        raise HTTPException(status_code=400, detail="指定的传感器不存在")
    
    existing_record = db.query(WearRecord).filter(
        WearRecord.sensor_id == wear_record.sensor_id,
        WearRecord.wear_end_time.is_(None)
    ).first()
    if existing_record:
        raise HTTPException(status_code=400, detail="此传感器已被佩戴且未结束")
    
    if wear_record.wear_position:
        existing_position_record = db.query(WearRecord).filter(
            WearRecord.person_id == wear_record.person_id,
            WearRecord.wear_position == wear_record.wear_position,
            WearRecord.wear_end_time.is_(None)
        ).first()
        if existing_position_record:
            raise HTTPException(status_code=400, detail=f"该人员已在“{wear_record.wear_position}”位置佩戴其他传感器")
    
    wear_record_data = wear_record.dict()
    if wear_record_data.get('wear_time') is None:
        wear_record_data['wear_time'] = datetime.now()
    
    wear_record_data['nickname'] = wear_record.nickname or person.person_name
    wear_record_data['user_name'] = person.person_name
    
    if sensor.sensor_detail:
        wear_record_data['sensor_detail_id'] = sensor.sensor_detail.sensor_detail_id
    
    db_wear_record = WearRecord(**wear_record_data)
    db.add(db_wear_record)
    db.commit()
    db.refresh(db_wear_record)
    
    db.refresh(sensor)
    
    sensor_detail_data = SensorDetailResponse.from_orm(sensor.sensor_detail) if sensor.sensor_detail else None
    
    return WearRecordResponse(
        wear_record_id=db_wear_record.wear_record_id,
        batch_id=db_wear_record.batch_id,
        person_id=db_wear_record.person_id,
        sensor_id=db_wear_record.sensor_id,
        sensor_detail_id=db_wear_record.sensor_detail_id,
        applicator_lot_no=db_wear_record.applicator_lot_no,
        sensor_lot_no=db_wear_record.sensor_lot_no,
        sensor_batch=db_wear_record.sensor_batch,
        sensor_number=db_wear_record.sensor_number,
        transmitter_id=db_wear_record.transmitter_id,
        wear_position=db_wear_record.wear_position,
        nickname=db_wear_record.nickname,
        user_name=db_wear_record.user_name,
        abnormal_situation=db_wear_record.abnormal_situation,
        cause_analysis=db_wear_record.cause_analysis,
        wear_time=db_wear_record.wear_time,
        wear_end_time=db_wear_record.wear_end_time,
        person_name=person.person_name,
        batch_number=batch.batch_number,
        test_number=sensor.sensor_detail.test_number if sensor.sensor_detail else None,
        probe_number=sensor.sensor_detail.probe_number if sensor.sensor_detail else None,
        sensor_detail=sensor_detail_data
    )

@router.get("/{wear_record_id}", response_model=WearRecordResponse)
def get_wear_record(
    wear_record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "read"))
):
    """获取单个佩戴记录详情"""
    wear_record = db.query(WearRecord)\
        .options(
            joinedload(WearRecord.batch),
            joinedload(WearRecord.person),
            joinedload(WearRecord.sensor).joinedload(Sensor.sensor_detail)
        ).filter(WearRecord.wear_record_id == wear_record_id).first()
        
    if not wear_record:
        raise HTTPException(status_code=404, detail="佩戴记录不存在")
    
    sensor_detail_data = None
    if wear_record.sensor and wear_record.sensor.sensor_detail:
        sensor_detail_data = SensorDetailResponse.from_orm(wear_record.sensor.sensor_detail)
    
    return WearRecordResponse(
        wear_record_id=wear_record.wear_record_id,
        batch_id=wear_record.batch_id,
        person_id=wear_record.person_id,
        sensor_id=wear_record.sensor_id,
        sensor_detail_id=wear_record.sensor_detail_id,
        applicator_lot_no=wear_record.applicator_lot_no,
        sensor_lot_no=wear_record.sensor_lot_no,
        sensor_batch=wear_record.sensor_batch,
        sensor_number=wear_record.sensor_number,
        transmitter_id=wear_record.transmitter_id,
        wear_position=wear_record.wear_position,
        nickname=wear_record.nickname,
        user_name=wear_record.user_name,
        abnormal_situation=wear_record.abnormal_situation,
        cause_analysis=wear_record.cause_analysis,
        wear_time=wear_record.wear_time,
        wear_end_time=wear_record.wear_end_time,
        person_name=wear_record.person.person_name if wear_record.person else None,
        batch_number=wear_record.batch.batch_number if wear_record.batch else None,
        test_number=wear_record.sensor.sensor_detail.test_number if wear_record.sensor and wear_record.sensor.sensor_detail else None,
        probe_number=wear_record.sensor.sensor_detail.probe_number if wear_record.sensor and wear_record.sensor.sensor_detail else None,
        sensor_detail=sensor_detail_data
    )

@router.put("/{wear_record_id}", response_model=WearRecordResponse)
def update_wear_record(
    wear_record_id: int,
    wear_record: WearRecordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "write"))
):
    """更新佩戴记录信息, 并同步结束时间到传感器管理"""
    db_wear_record = db.query(WearRecord).filter(WearRecord.wear_record_id == wear_record_id).first()
    if not db_wear_record:
        raise HTTPException(status_code=404, detail="佩戴记录不存在")
    
    batch = db.query(Batch).filter(Batch.batch_id == wear_record.batch_id).first()
    if not batch:
        raise HTTPException(status_code=400, detail="指定的批次不存在")
    
    person = db.query(Person).filter(Person.person_id == wear_record.person_id).first()
    if not person:
        raise HTTPException(status_code=400, detail="指定的人员不存在")
    
    sensor = db.query(Sensor).options(joinedload(Sensor.sensor_detail)).filter(Sensor.sensor_id == wear_record.sensor_id).first()
    if not sensor:
        raise HTTPException(status_code=400, detail="指定的传感器不存在")
    
    existing_record = db.query(WearRecord).filter(
        WearRecord.sensor_id == wear_record.sensor_id,
        WearRecord.wear_end_time.is_(None),
        WearRecord.wear_record_id != wear_record_id
    ).first()
    if existing_record:
        raise HTTPException(status_code=400, detail="此传感器已被其他人员佩戴且未结束")

    if wear_record.wear_position:
        existing_position_record = db.query(WearRecord).filter(
            WearRecord.person_id == wear_record.person_id,
            WearRecord.wear_position == wear_record.wear_position,
            WearRecord.wear_end_time.is_(None),
            WearRecord.wear_record_id != wear_record_id
        ).first()
        if existing_position_record:
            raise HTTPException(status_code=400, detail=f"该人员已在“{wear_record.wear_position}”位置佩戴其他传感器")

    wear_record_data = wear_record.dict(exclude_unset=True)
    for field, value in wear_record_data.items():
        setattr(db_wear_record, field, value)
    
    db_wear_record.nickname = wear_record.nickname or person.person_name
    db_wear_record.user_name = person.person_name
    db_wear_record.sensor_detail_id = sensor.sensor_detail.sensor_detail_id if sensor.sensor_detail else None
    
    # --- 新增的同步逻辑 ---
    # 检查佩戴记录是否设置了结束时间
    if db_wear_record.wear_end_time:
        # 如果设置了，就同步更新对应传感器的 end_time 和 end_reason
        sensor.end_time = db_wear_record.wear_end_time
        # 将佩戴记录的"原因分析"同步为传感器的"结束原因"
        sensor.end_reason = db_wear_record.cause_analysis
    else:
        # 如果佩戴记录的结束时间被清空了，也同步清空传感器的结束信息
        sensor.end_time = None
        sensor.end_reason = None
    # --- 同步逻辑结束 ---

    db.commit()
    db.refresh(db_wear_record)
    db.refresh(sensor)

    sensor_detail_data = SensorDetailResponse.from_orm(sensor.sensor_detail) if sensor.sensor_detail else None

    return WearRecordResponse(
        wear_record_id=db_wear_record.wear_record_id,
        batch_id=db_wear_record.batch_id,
        person_id=db_wear_record.person_id,
        sensor_id=db_wear_record.sensor_id,
        sensor_detail_id=db_wear_record.sensor_detail_id,
        applicator_lot_no=db_wear_record.applicator_lot_no,
        sensor_lot_no=db_wear_record.sensor_lot_no,
        sensor_batch=db_wear_record.sensor_batch,
        sensor_number=db_wear_record.sensor_number,
        transmitter_id=db_wear_record.transmitter_id,
        wear_position=db_wear_record.wear_position,
        nickname=db_wear_record.nickname,
        user_name=db_wear_record.user_name,
        abnormal_situation=db_wear_record.abnormal_situation,
        cause_analysis=db_wear_record.cause_analysis,
        wear_time=db_wear_record.wear_time,
        wear_end_time=db_wear_record.wear_end_time,
        person_name=person.person_name,
        batch_number=batch.batch_number,
        test_number=sensor.sensor_detail.test_number if sensor.sensor_detail else None,
        probe_number=sensor.sensor_detail.probe_number if sensor.sensor_detail else None,
        sensor_detail=sensor_detail_data
    )

@router.delete("/{wear_record_id}", response_model=MessageResponse)
def delete_wear_record(
    wear_record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "delete"))
):
    """删除佩戴记录"""
    db_wear_record = db.query(WearRecord).filter(WearRecord.wear_record_id == wear_record_id).first()
    if not db_wear_record:
        raise HTTPException(status_code=404, detail="佩戴记录不存在")
    
    # 在删除佩戴记录前，清空对应传感器的结束信息
    sensor = db.query(Sensor).filter(Sensor.sensor_id == db_wear_record.sensor_id).first()
    if sensor:
        sensor.end_time = None
        sensor.end_reason = None

    db.delete(db_wear_record)
    db.commit()
    return MessageResponse(message="佩戴记录删除成功")

