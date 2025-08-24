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
    """获取已被佩戴的传感器ID列表"""
    used_sensor_ids = db.query(WearRecord.sensor_id).distinct().all()
    return [sensor_id[0] for sensor_id in used_sensor_ids]

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
    
    wear_records = query.offset(skip).limit(limit).all()
    
    result = []
    for record in wear_records:
        sensor_detail_data = None
        if record.sensor and record.sensor.sensor_detail:
            sensor_detail_data = SensorDetailResponse(
                sensor_detail_id=record.sensor.sensor_detail.sensor_detail_id,
                sterilization_date=record.sensor.sensor_detail.sterilization_date,
                test_number=record.sensor.sensor_detail.test_number,
                probe_number=record.sensor.sensor_detail.probe_number,
                value_0=record.sensor.sensor_detail.value_0,
                value_2=record.sensor.sensor_detail.value_2,
                value_5=record.sensor.sensor_detail.value_5,
                value_25=record.sensor.sensor_detail.value_25,
                sensitivity=record.sensor.sensor_detail.sensitivity,
                r_value=record.sensor.sensor_detail.r_value,
                destination=record.sensor.sensor_detail.destination,
                remarks=record.sensor.sensor_detail.remarks,
                created_time=record.sensor.sensor_detail.created_time
            )
        
        record_dict = {
            "wear_record_id": record.wear_record_id,
            "batch_id": record.batch_id,
            "person_id": record.person_id,
            "sensor_id": record.sensor_id,
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
    # 验证批次是否存在
    batch = db.query(Batch).filter(Batch.batch_id == wear_record.batch_id).first()
    if not batch:
        raise HTTPException(status_code=400, detail="指定的批次不存在")
    
    # 验证人员是否存在
    person = db.query(Person).filter(Person.person_id == wear_record.person_id).first()
    if not person:
        raise HTTPException(status_code=400, detail="指定的人员不存在")
    
    # 验证传感器是否存在，并预加载关联的传感器详细信息
    sensor = db.query(Sensor).options(joinedload(Sensor.sensor_detail)).filter(Sensor.sensor_id == wear_record.sensor_id).first()
    if not sensor:
        raise HTTPException(status_code=400, detail="指定的传感器不存在")
    
    # 检查是否已存在相同的佩戴记录（同一人员佩戴同一传感器）
    existing_record = db.query(WearRecord).filter(
        WearRecord.person_id == wear_record.person_id,
        WearRecord.sensor_id == wear_record.sensor_id
    ).first()
    if existing_record:
        raise HTTPException(status_code=400, detail="该人员已佩戴此传感器")
    
    # 检查同一人员是否已在相同位置佩戴其他传感器
    existing_position_record = db.query(WearRecord).filter(
        WearRecord.person_id == wear_record.person_id,
        WearRecord.wear_position == wear_record.wear_position
    ).first()
    if existing_position_record:
        raise HTTPException(status_code=400, detail=f"该人员已在{wear_record.wear_position}位置佩戴其他传感器设备")
    
    # 创建佩戴记录，如果没有提供wear_time则使用当前日期
    wear_record_data = wear_record.dict()
    if wear_record_data.get('wear_time') is None:
        wear_record_data['wear_time'] = datetime.now().date()
    
    # 设置nickname字段（从wear_record获取）
    wear_record_data['nickname'] = wear_record.nickname if hasattr(wear_record, 'nickname') and wear_record.nickname else person.person_name
    # 设置user_name字段（从person获取）
    wear_record_data['user_name'] = person.person_name
    
    # 设置sensor_detail_id字段（从sensor获取）
    if sensor.sensor_detail:
        wear_record_data['sensor_detail_id'] = sensor.sensor_detail.sensor_detail_id
    
    db_wear_record = WearRecord(**wear_record_data)
    db.add(db_wear_record)
    db.commit()
    db.refresh(db_wear_record)
    
    # 获取传感器关联的详细信息
    sensor_detail_data = None
    if sensor.sensor_detail:
        sensor_detail_data = SensorDetailResponse(
            sensor_detail_id=sensor.sensor_detail.sensor_detail_id,
            sterilization_date=sensor.sensor_detail.sterilization_date,
            test_number=sensor.sensor_detail.test_number,
            probe_number=sensor.sensor_detail.probe_number,
            value_0=sensor.sensor_detail.value_0,
            value_2=sensor.sensor_detail.value_2,
            value_5=sensor.sensor_detail.value_5,
            value_25=sensor.sensor_detail.value_25,
            sensitivity=sensor.sensor_detail.sensitivity,
            r_value=sensor.sensor_detail.r_value,
            destination=sensor.sensor_detail.destination,
            remarks=sensor.sensor_detail.remarks,
            created_time=sensor.sensor_detail.created_time
        )
    
    result = WearRecordResponse(
        wear_record_id=db_wear_record.wear_record_id,
        batch_id=db_wear_record.batch_id,
        person_id=db_wear_record.person_id,
        sensor_id=db_wear_record.sensor_id,
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
    
    return result

@router.get("/{wear_record_id}", response_model=WearRecordResponse)
def get_wear_record(
    wear_record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "read"))
):
    """获取单个佩戴记录详情"""
    wear_record = db.query(WearRecord)\
        .outerjoin(WearRecord.batch)\
        .outerjoin(WearRecord.person)\
        .outerjoin(WearRecord.sensor)\
        .outerjoin(Sensor.sensor_detail)\
        .options(
            contains_eager(WearRecord.batch),
            contains_eager(WearRecord.person),
            contains_eager(WearRecord.sensor).contains_eager(Sensor.sensor_detail)
        ).filter(WearRecord.wear_record_id == wear_record_id).first()
    if not wear_record:
        raise HTTPException(status_code=404, detail="佩戴记录不存在")
    
    sensor_detail_data = None
    if wear_record.sensor and wear_record.sensor.sensor_detail:
        sensor_detail_data = SensorDetailResponse(
            sensor_detail_id=wear_record.sensor.sensor_detail.sensor_detail_id,
            sterilization_date=wear_record.sensor.sensor_detail.sterilization_date,
            test_number=wear_record.sensor.sensor_detail.test_number,
            probe_number=wear_record.sensor.sensor_detail.probe_number,
            value_0=wear_record.sensor.sensor_detail.value_0,
            value_2=wear_record.sensor.sensor_detail.value_2,
            value_5=wear_record.sensor.sensor_detail.value_5,
            value_25=wear_record.sensor.sensor_detail.value_25,
            sensitivity=wear_record.sensor.sensor_detail.sensitivity,
            r_value=wear_record.sensor.sensor_detail.r_value,
            destination=wear_record.sensor.sensor_detail.destination,
            remarks=wear_record.sensor.sensor_detail.remarks,
            created_time=wear_record.sensor.sensor_detail.created_time
        )
    
    result = WearRecordResponse(
        wear_record_id=wear_record.wear_record_id,
        batch_id=wear_record.batch_id,
        person_id=wear_record.person_id,
        sensor_id=wear_record.sensor_id,
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
    
    return result

@router.put("/{wear_record_id}", response_model=WearRecordResponse)
def update_wear_record(
    wear_record_id: int,
    wear_record: WearRecordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.WEAR_RECORDS, "write"))
):
    """更新佩戴记录信息"""
    db_wear_record = db.query(WearRecord).filter(WearRecord.wear_record_id == wear_record_id).first()
    if not db_wear_record:
        raise HTTPException(status_code=404, detail="佩戴记录不存在")
    
    # 验证批次是否存在
    batch = db.query(Batch).filter(Batch.batch_id == wear_record.batch_id).first()
    if not batch:
        raise HTTPException(status_code=400, detail="指定的批次不存在")
    
    # 验证人员是否存在
    person = db.query(Person).filter(Person.person_id == wear_record.person_id).first()
    if not person:
        raise HTTPException(status_code=400, detail="指定的人员不存在")
    
    # 验证传感器是否存在，并预加载关联的传感器详细信息
    sensor = db.query(Sensor).options(joinedload(Sensor.sensor_detail)).filter(Sensor.sensor_id == wear_record.sensor_id).first()
    if not sensor:
        raise HTTPException(status_code=400, detail="指定的传感器不存在")
    
    # 检查是否与其他记录冲突（同一人员佩戴同一传感器）
    if (wear_record.person_id != db_wear_record.person_id or 
        wear_record.sensor_id != db_wear_record.sensor_id):
        existing_record = db.query(WearRecord).filter(
            WearRecord.person_id == wear_record.person_id,
            WearRecord.sensor_id == wear_record.sensor_id,
            WearRecord.wear_record_id != wear_record_id
        ).first()
        if existing_record:
            raise HTTPException(status_code=400, detail="该人员已佩戴此传感器")
    
    # 检查同一人员是否已在相同位置佩戴其他传感器（排除当前记录）
    if (wear_record.person_id != db_wear_record.person_id or 
        wear_record.wear_position != db_wear_record.wear_position):
        existing_position_record = db.query(WearRecord).filter(
            WearRecord.person_id == wear_record.person_id,
            WearRecord.wear_position == wear_record.wear_position,
            WearRecord.wear_record_id != wear_record_id
        ).first()
        if existing_position_record:
            raise HTTPException(status_code=400, detail=f"该人员已在{wear_record.wear_position}位置佩戴其他传感器设备")
    
    # 更新佩戴记录字段
    wear_record_data = wear_record.dict(exclude_unset=True)
    for field, value in wear_record_data.items():
        setattr(db_wear_record, field, value)
    
    # 更新nickname字段（从wear_record获取）
    db_wear_record.nickname = wear_record.nickname if hasattr(wear_record, 'nickname') and wear_record.nickname else person.person_name
    # 更新user_name字段（从person获取）
    db_wear_record.user_name = person.person_name
    
    # 更新sensor_detail_id字段（从sensor获取）
    if sensor.sensor_detail:
        db_wear_record.sensor_detail_id = sensor.sensor_detail.sensor_detail_id
    else:
        db_wear_record.sensor_detail_id = None
    
    # 同步更新传感器表中的相关字段
    if hasattr(wear_record, 'wear_end_time') and wear_record.wear_end_time is not None:
        # 如果设置了佩戴结束时间，同步更新传感器的end_time
        from datetime import datetime
        if isinstance(wear_record.wear_end_time, str):
            # 如果是字符串格式的日期，转换为datetime
            try:
                end_datetime = datetime.strptime(wear_record.wear_end_time, '%Y-%m-%d')
                sensor.end_time = end_datetime
            except ValueError:
                # 如果日期格式不正确，使用当前时间
                sensor.end_time = datetime.now()
        else:
            # 如果是date对象，转换为datetime
            sensor.end_time = datetime.combine(wear_record.wear_end_time, datetime.min.time())
    
    # 同步更新传感器的结束原因
    if hasattr(wear_record, 'cause_analysis'):
        sensor.end_reason = wear_record.cause_analysis
    
    db.commit()
    db.refresh(db_wear_record)
    
    # 获取传感器关联的详细信息
    sensor_detail_data = None
    if sensor.sensor_detail:
        sensor_detail_data = SensorDetailResponse(
            sensor_detail_id=sensor.sensor_detail.sensor_detail_id,
            sterilization_date=sensor.sensor_detail.sterilization_date,
            test_number=sensor.sensor_detail.test_number,
            probe_number=sensor.sensor_detail.probe_number,
            value_0=sensor.sensor_detail.value_0,
            value_2=sensor.sensor_detail.value_2,
            value_5=sensor.sensor_detail.value_5,
            value_25=sensor.sensor_detail.value_25,
            sensitivity=sensor.sensor_detail.sensitivity,
            r_value=sensor.sensor_detail.r_value,
            destination=sensor.sensor_detail.destination,
            remarks=sensor.sensor_detail.remarks,
            created_time=sensor.sensor_detail.created_time
        )
    
    result = WearRecordResponse(
        wear_record_id=db_wear_record.wear_record_id,
        batch_id=db_wear_record.batch_id,
        person_id=db_wear_record.person_id,
        sensor_id=db_wear_record.sensor_id,
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
    
    return result

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
    
    db.delete(db_wear_record)
    db.commit()
    return MessageResponse(message="佩戴记录删除成功")