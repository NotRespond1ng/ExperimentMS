from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from database import get_db
from models import SensorDetail, User, Sensor
from schemas import SensorDetailCreate, SensorDetailUpdate, SensorDetailResponse, MessageResponse, BatchDeleteRequest
from routers.auth import get_current_user, check_module_permission
from models import ModuleEnum

router = APIRouter(prefix="/api/sensorDetails", tags=["传感器详细信息管理"])

@router.get("/", response_model=List[SensorDetailResponse])
def get_sensor_details(
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(100, ge=1, le=1000, description="返回的记录数"),
    test_number: Optional[str] = Query(None, description="按测试编号筛选"),
    probe_number: Optional[str] = Query(None, description="按探针编号筛选"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "read"))
):
    """获取传感器详细信息列表"""
    query = db.query(SensorDetail)
    
    if test_number:
        query = query.filter(SensorDetail.test_number.contains(test_number))
    
    if probe_number:
        query = query.filter(SensorDetail.probe_number.contains(probe_number))
    
    sensor_details = query.offset(skip).limit(limit).all()
    
    result = []
    for detail in sensor_details:
        detail_dict = {
            "sensor_detail_id": detail.sensor_detail_id,
            "sterilization_date": detail.sterilization_date,
            "test_number": detail.test_number,
            "probe_number": detail.probe_number,
            "value_0": detail.value_0,
            "value_2": detail.value_2,
            "value_5": detail.value_5,
            "value_25": detail.value_25,
            "sensitivity": detail.sensitivity,
            "r_value": detail.r_value,
            "destination": detail.destination,
            "remarks": detail.remarks,
            "created_time": detail.created_time
        }
        result.append(SensorDetailResponse(**detail_dict))
    
    return result

@router.get("/used-sensor-details", response_model=List[int])
def get_used_sensor_details(
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "read"))
):
    """获取已分配的传感器详细信息ID列表"""
    # 查询所有已分配的传感器详细信息ID（即在sensors表中被引用的sensor_detail_id）
    used_sensor_detail_ids = db.query(Sensor.sensor_detail_id).filter(
        Sensor.sensor_detail_id.isnot(None)
    ).distinct().all()
    
    # 提取ID列表
    result = [id_tuple[0] for id_tuple in used_sensor_detail_ids]
    return result

@router.post("/", response_model=SensorDetailResponse)
def create_sensor_detail(
    sensor_detail: SensorDetailCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "write"))
):
    """新增传感器详细信息记录"""
    # 检查测试编号是否已存在
    existing_test = db.query(SensorDetail).filter(SensorDetail.test_number == sensor_detail.test_number).first()
    if existing_test:
        raise HTTPException(status_code=400, detail="测试编号已存在")
    
    # 检查探针编号是否已存在
    existing_probe = db.query(SensorDetail).filter(SensorDetail.probe_number == sensor_detail.probe_number).first()
    if existing_probe:
        raise HTTPException(status_code=400, detail="探针编号已存在")
    
    db_sensor_detail = SensorDetail(**sensor_detail.dict())
    db.add(db_sensor_detail)
    db.commit()
    db.refresh(db_sensor_detail)
    
    result = SensorDetailResponse(
        sensor_detail_id=db_sensor_detail.sensor_detail_id,
        sterilization_date=db_sensor_detail.sterilization_date,
        test_number=db_sensor_detail.test_number,
        probe_number=db_sensor_detail.probe_number,
        value_0=db_sensor_detail.value_0,
        value_2=db_sensor_detail.value_2,
        value_5=db_sensor_detail.value_5,
        value_25=db_sensor_detail.value_25,
        sensitivity=db_sensor_detail.sensitivity,
        r_value=db_sensor_detail.r_value,
        destination=db_sensor_detail.destination,
        remarks=db_sensor_detail.remarks,
        created_time=db_sensor_detail.created_time
    )
    
    return result

@router.get("/{sensor_detail_id}", response_model=SensorDetailResponse)
def get_sensor_detail(
    sensor_detail_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "read"))
):
    """获取单个传感器详细信息"""
    sensor_detail = db.query(SensorDetail).filter(SensorDetail.sensor_detail_id == sensor_detail_id).first()
    if not sensor_detail:
        raise HTTPException(status_code=404, detail="传感器详细信息不存在")
    
    result = SensorDetailResponse(
        sensor_detail_id=sensor_detail.sensor_detail_id,
        sterilization_date=sensor_detail.sterilization_date,
        test_number=sensor_detail.test_number,
        probe_number=sensor_detail.probe_number,
        value_0=sensor_detail.value_0,
        value_2=sensor_detail.value_2,
        value_5=sensor_detail.value_5,
        value_25=sensor_detail.value_25,
        sensitivity=sensor_detail.sensitivity,
        r_value=sensor_detail.r_value,
        destination=sensor_detail.destination,
        remarks=sensor_detail.remarks,
        created_time=sensor_detail.created_time
    )
    
    return result

@router.put("/{sensor_detail_id}", response_model=SensorDetailResponse)
def update_sensor_detail(
    sensor_detail_id: int,
    sensor_detail: SensorDetailUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "write"))
):
    """更新传感器详细信息"""
    db_sensor_detail = db.query(SensorDetail).filter(SensorDetail.sensor_detail_id == sensor_detail_id).first()
    if not db_sensor_detail:
        raise HTTPException(status_code=404, detail="传感器详细信息不存在")
    
    # 检查测试编号是否与其他记录冲突
    if sensor_detail.test_number != db_sensor_detail.test_number:
        existing_test = db.query(SensorDetail).filter(
            SensorDetail.test_number == sensor_detail.test_number,
            SensorDetail.sensor_detail_id != sensor_detail_id
        ).first()
        if existing_test:
            raise HTTPException(status_code=400, detail="测试编号已存在")
    
    # 检查探针编号是否与其他记录冲突
    if sensor_detail.probe_number != db_sensor_detail.probe_number:
        existing_probe = db.query(SensorDetail).filter(
            SensorDetail.probe_number == sensor_detail.probe_number,
            SensorDetail.sensor_detail_id != sensor_detail_id
        ).first()
        if existing_probe:
            raise HTTPException(status_code=400, detail="探针编号已存在")
    
    for field, value in sensor_detail.dict().items():
        setattr(db_sensor_detail, field, value)
    
    db.commit()
    db.refresh(db_sensor_detail)
    
    result = SensorDetailResponse(
        sensor_detail_id=db_sensor_detail.sensor_detail_id,
        sterilization_date=db_sensor_detail.sterilization_date,
        test_number=db_sensor_detail.test_number,
        probe_number=db_sensor_detail.probe_number,
        value_0=db_sensor_detail.value_0,
        value_2=db_sensor_detail.value_2,
        value_5=db_sensor_detail.value_5,
        value_25=db_sensor_detail.value_25,
        sensitivity=db_sensor_detail.sensitivity,
        r_value=db_sensor_detail.r_value,
        destination=db_sensor_detail.destination,
        remarks=db_sensor_detail.remarks,
        created_time=db_sensor_detail.created_time
    )
    
    return result

@router.delete("/{sensor_detail_id}", response_model=MessageResponse)
def delete_sensor_detail(
    sensor_detail_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "delete"))
):
    """删除传感器详细信息记录"""
    db_sensor_detail = db.query(SensorDetail).filter(SensorDetail.sensor_detail_id == sensor_detail_id).first()
    if not db_sensor_detail:
        raise HTTPException(status_code=404, detail="传感器详细信息不存在")
    
    # 检查是否有传感器引用了这个传感器详细信息
    referenced_sensor = db.query(Sensor).filter(Sensor.sensor_detail_id == sensor_detail_id).first()
    if referenced_sensor:
        raise HTTPException(status_code=400, detail="该传感器详细信息正在被传感器管理模块使用，无法删除")
    
    db.delete(db_sensor_detail)
    db.commit()
    return MessageResponse(message="传感器详细信息记录删除成功")

@router.post("/batch")
async def batch_create_sensor_details(
    sensor_details: List[SensorDetailCreate],
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "write"))
) -> Dict[str, Any]:
    """批量创建传感器详细信息"""
    try:
        # 1. 检查批次内重复
        batch_duplicates = []
        test_numbers = {}
        probe_numbers = {}
        
        for i, detail in enumerate(sensor_details):
            # 检查测试编号重复
            if detail.test_number:
                if detail.test_number in test_numbers:
                    batch_duplicates.append({
                        "field": "test_number",
                        "value": detail.test_number,
                        "positions": [test_numbers[detail.test_number], i + 1]
                    })
                else:
                    test_numbers[detail.test_number] = i + 1
            
            # 检查探针编号重复
            if detail.probe_number:
                if detail.probe_number in probe_numbers:
                    batch_duplicates.append({
                        "field": "probe_number",
                        "value": detail.probe_number,
                        "positions": [probe_numbers[detail.probe_number], i + 1]
                    })
                else:
                    probe_numbers[detail.probe_number] = i + 1
        
        if batch_duplicates:
            raise HTTPException(
                status_code=400,
                detail={
                    "type": "batch_duplicate",
                    "message": "批次内存在重复数据",
                    "duplicates": batch_duplicates
                }
            )
        
        # 2. 检查数据库中是否存在重复
        db_duplicates = []
        for i, detail in enumerate(sensor_details):
            # 检查测试编号是否已存在
            if detail.test_number:
                existing = db.query(SensorDetail).filter(
                    SensorDetail.test_number == detail.test_number
                ).first()
                if existing:
                    db_duplicates.append({
                        "field": "test_number",
                        "value": detail.test_number,
                        "position": i + 1
                    })
            
            # 检查探针编号是否已存在
            if detail.probe_number:
                existing = db.query(SensorDetail).filter(
                    SensorDetail.probe_number == detail.probe_number
                ).first()
                if existing:
                    db_duplicates.append({
                        "field": "probe_number",
                        "value": detail.probe_number,
                        "position": i + 1
                    })
        
        if db_duplicates:
            raise HTTPException(
                status_code=400,
                detail={
                    "type": "database_duplicate",
                    "message": "数据库中已存在重复数据",
                    "duplicates": db_duplicates
                }
            )
        
        # 3. 批量创建
        created_details = []
        for detail_data in sensor_details:
            db_sensor_detail = SensorDetail(**detail_data.dict())
            db.add(db_sensor_detail)
            created_details.append(db_sensor_detail)
        
        db.commit()
        
        # 刷新对象以获取生成的ID
        for detail in created_details:
            db.refresh(detail)
        
        return {
            "message": f"成功创建 {len(created_details)} 条传感器详细信息",
            "created_count": len(created_details),
            "data": [SensorDetailResponse.from_orm(detail) for detail in created_details]
        }
    
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"批量创建失败: {str(e)}")


@router.post("/check-duplicates")
async def check_duplicates(
    test_number: Optional[str] = None,
    probe_number: Optional[str] = None,
    exclude_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "read"))
) -> Dict[str, Any]:
    """检查测试编号或探针编号是否重复"""
    duplicates = []
    
    if test_number:
        query = db.query(SensorDetail).filter(SensorDetail.test_number == test_number)
        if exclude_id:
            query = query.filter(SensorDetail.sensor_detail_id != exclude_id)
        
        existing = query.first()
        if existing:
            duplicates.append({
                "field": "test_number",
                "value": test_number,
                "existing_id": existing.sensor_detail_id
            })
    
    if probe_number:
        query = db.query(SensorDetail).filter(SensorDetail.probe_number == probe_number)
        if exclude_id:
            query = query.filter(SensorDetail.sensor_detail_id != exclude_id)
        
        existing = query.first()
        if existing:
            duplicates.append({
                "field": "probe_number",
                "value": probe_number,
                "existing_id": existing.sensor_detail_id
            })
    
    return {
        "has_duplicates": len(duplicates) > 0,
        "duplicates": duplicates
    }


@router.post("/batch-delete")
def batch_delete_sensor_details(
    request: BatchDeleteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.SENSOR_DETAILS, "delete"))
):
    """批量删除传感器详细信息"""
    if not request.ids:
        raise HTTPException(status_code=400, detail="请提供要删除的数据ID列表")
    
    # 查询要删除的数据
    details_to_delete = db.query(SensorDetail).filter(SensorDetail.sensor_detail_id.in_(request.ids)).all()
    
    if not details_to_delete:
        raise HTTPException(status_code=404, detail="未找到要删除的数据")
    
    # 检查是否有传感器引用了这些传感器详细信息
    referenced_sensors = db.query(Sensor).filter(Sensor.sensor_detail_id.in_(request.ids)).all()
    if referenced_sensors:
        referenced_ids = [sensor.sensor_detail_id for sensor in referenced_sensors]
        raise HTTPException(status_code=400, detail=f"传感器详细信息ID {referenced_ids} 正在被传感器管理模块使用，无法删除")
    
    deleted_count = len(details_to_delete)
    
    # 执行批量删除
    for detail in details_to_delete:
        db.delete(detail)
    
    db.commit()
    
    return {"deleted_count": deleted_count, "message": f"成功删除{deleted_count}条传感器详细信息记录"}