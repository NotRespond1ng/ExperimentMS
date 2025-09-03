from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import shutil
from datetime import datetime
import pandas as pd
import tempfile
import uuid
from pathlib import Path
import logging
from database import get_db
from models import CompetitorFile, Batch, Person, User, ModuleEnum
from schemas import CompetitorFileResponse, MessageResponse
from routers.activities import log_activity
from routers.auth import get_current_user, check_module_permission
from utils import format_file_size

router = APIRouter(prefix="/api/competitorFiles", tags=["竞品数据管理"])

# 文件上传目录 - 使用 pathlib 确保跨平台兼容性
BASE_DIR = Path(__file__).parent.parent
UPLOAD_DIR = BASE_DIR / "uploads" / "competitor_files"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

@router.get("/", response_model=List[CompetitorFileResponse])
def get_competitor_files(
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(100, ge=1, le=1000, description="返回的记录数"),
    batch_id: Optional[int] = Query(None, description="按批次筛选"),
    person_id: Optional[int] = Query(None, description="按人员筛选"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.COMPETITOR_DATA, "read"))
):
    """获取竞品文件列表"""
    query = db.query(CompetitorFile).join(Batch).join(Person)
    
    if batch_id:
        query = query.filter(CompetitorFile.batch_id == batch_id)
    
    if person_id:
        query = query.filter(CompetitorFile.person_id == person_id)
    
    files = query.offset(skip).limit(limit).all()
    
    # 添加关联信息
    result = []
    for file in files:
        # 获取文件大小
        file_size = None
        file_path = Path(file.file_path)
        if file_path.exists():
            try:
                file_size = file_path.stat().st_size
            except OSError:
                file_size = None
        
        # 提取原始文件名（去掉UUID前缀）
        filename = file_path.name
        if '_' in filename and len(filename.split('_')[0]) == 8:
            # 如果文件名包含UUID前缀，提取原始文件名
            filename = '_'.join(filename.split('_')[1:])
        
        file_dict = {
            "competitor_file_id": file.competitor_file_id,
            "person_id": file.person_id,
            "batch_id": file.batch_id,
            "file_path": file.file_path,
            "upload_time": file.upload_time,
            "person_name": file.person.person_name if file.person else None,
            "batch_number": file.batch.batch_number if file.batch else None,
            "file_size": file_size,
            "filename": filename
        }
        result.append(CompetitorFileResponse(**file_dict))
    
    return result

@router.post("/upload", response_model=CompetitorFileResponse)
async def upload_competitor_file(
    batch_id: int = Form(...),
    person_id: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.COMPETITOR_DATA, "write"))
):
    """上传竞品文件"""
    # 验证批次和人员是否存在
    batch = db.query(Batch).filter(Batch.batch_id == batch_id).first()
    if not batch:
        raise HTTPException(status_code=400, detail="指定的批次不存在")
    
    person = db.query(Person).filter(Person.person_id == person_id).first()
    if not person:
        raise HTTPException(status_code=400, detail="指定的人员不存在")
    
    # 验证文件名
    if not file.filename:
        raise HTTPException(status_code=400, detail="文件名不能为空")
    
    original_filename = file.filename
    file_extension = Path(original_filename).suffix
    
    # 检查是否已存在相同的文件记录（基于原始文件名、批次和人员）
    existing_file = db.query(CompetitorFile).filter(
        CompetitorFile.file_path.like(f"%{original_filename}"),
        CompetitorFile.batch_id == batch_id,
        CompetitorFile.person_id == person_id
    ).first()
    
    if existing_file:
        # 如果存在相同记录，检查物理文件是否存在
        existing_path = Path(existing_file.file_path)
        if existing_path.exists():
            # 文件已存在，返回现有记录信息
            file_size = existing_path.stat().st_size
            return CompetitorFileResponse(
                competitor_file_id=existing_file.competitor_file_id,
                person_id=existing_file.person_id,
                batch_id=existing_file.batch_id,
                file_path=str(existing_file.file_path),
                upload_time=existing_file.upload_time,
                person_name=person.person_name,
                batch_number=batch.batch_number,
                file_size=file_size,
                filename=original_filename
            )
        else:
            # 数据库记录存在但物理文件不存在，删除旧记录
            db.delete(existing_file)
            db.commit()
    
    # 生成唯一文件名：UUID + 原始文件名
    unique_id = str(uuid.uuid4())[:8]
    safe_filename = f"{unique_id}_{original_filename}"
    file_path = UPLOAD_DIR / safe_filename
    
    # 保存文件
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"文件保存失败: {str(e)}")
    
    # 创建新的数据库记录
    db_file = CompetitorFile(
        person_id=person_id,
        batch_id=batch_id,
        file_path=str(file_path)
    )
    db.add(db_file)
    db.commit()
    db.refresh(db_file)
    
    # 获取文件大小
    file_size = None
    try:
        file_size = file_path.stat().st_size
    except OSError:
        file_size = None
    
    result = CompetitorFileResponse(
        competitor_file_id=db_file.competitor_file_id,
        person_id=db_file.person_id,
        batch_id=db_file.batch_id,
        file_path=str(db_file.file_path),
        upload_time=db_file.upload_time,
        person_name=person.person_name,
        batch_number=batch.batch_number,
        file_size=file_size,
        filename=original_filename
    )
    
    return result

@router.get("/download/{file_id}")
def download_competitor_file(
    file_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.COMPETITOR_DATA, "read"))
):
    """下载竞品文件"""
    file_record = db.query(CompetitorFile).filter(CompetitorFile.competitor_file_id == file_id).first()
    if not file_record:
        raise HTTPException(status_code=404, detail="文件不存在")
    
    file_path = Path(file_record.file_path)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="文件已被删除或移动")
    
    # 提取原始文件名（去掉UUID前缀）
    filename = file_path.name
    if '_' in filename and len(filename.split('_')[0]) == 8:
        filename = '_'.join(filename.split('_')[1:])
    
    return FileResponse(
        path=str(file_path),
        filename=filename,
        media_type='application/octet-stream'
    )

@router.put("/rename/{competitor_file_id}")
async def rename_competitor_file(
    competitor_file_id: int,
    new_filename: str,
    db: Session = Depends(get_db)
):
    """重命名竞品文件"""
    file = db.query(CompetitorFile).filter(CompetitorFile.competitor_file_id == competitor_file_id).first()
    if not file:
        raise HTTPException(status_code=404, detail="文件不存在")
    
    old_path = Path(file.file_path)
    if not old_path.exists():
        raise HTTPException(status_code=404, detail="文件已被删除")
    
    # 生成新的安全文件名（保留UUID前缀）
    old_filename = old_path.name
    if '_' in old_filename and len(old_filename.split('_')[0]) == 8:
        # 保留UUID前缀，只更新原始文件名部分
        uuid_prefix = old_filename.split('_')[0]
        new_safe_filename = f"{uuid_prefix}_{new_filename}"
    else:
        # 如果没有UUID前缀，生成新的
        new_safe_filename = f"{uuid.uuid4().hex[:8]}_{new_filename}"
    
    new_path = old_path.parent / new_safe_filename
    
    try:
        # 重命名物理文件
        old_path.rename(new_path)
        
        # 更新数据库记录
        file.file_path = str(new_path)
        db.commit()
        
        # 获取关联信息
        batch = db.query(Batch).filter(Batch.batch_id == file.batch_id).first()
        person = db.query(Person).filter(Person.person_id == file.person_id).first()
        
        # 获取文件大小
        file_size = None
        if new_path.exists():
            try:
                file_size = new_path.stat().st_size
            except OSError:
                file_size = None
        
        # 返回完整的CompetitorFileResponse对象
        result = CompetitorFileResponse(
            competitor_file_id=file.competitor_file_id,
            person_id=file.person_id,
            batch_id=file.batch_id,
            file_path=str(new_path),
            upload_time=file.upload_time,
            person_name=person.person_name if person else None,
            batch_number=batch.batch_number if batch else None,
            file_size=file_size,
            filename=new_filename
        )
        
        return result
    except OSError as e:
        raise HTTPException(status_code=500, detail=f"重命名失败: {str(e)}")

@router.delete("/delete/{competitor_file_id}")
async def delete_competitor_file(
    competitor_file_id: int,
    db: Session = Depends(get_db)
):
    """删除竞品文件"""
    file = db.query(CompetitorFile).filter(CompetitorFile.competitor_file_id == competitor_file_id).first()
    if not file:
        raise HTTPException(status_code=404, detail="文件不存在")
    
    # 删除物理文件
    file_path = Path(file.file_path)
    if file_path.exists():
        try:
            file_path.unlink()
        except OSError as e:
            raise HTTPException(status_code=500, detail=f"删除文件失败: {str(e)}")
    
    # 删除数据库记录
    db.delete(file)
    db.commit()
    
    return {"message": "文件删除成功"}

@router.get("/check-integrity")
def check_file_integrity(db: Session = Depends(get_db)):
    """
    检查文件完整性，修复数据库记录与物理文件不一致的问题
    """
    try:
        files = db.query(CompetitorFile).all()
        issues_fixed = 0
        
        for file_record in files:
            file_path = UPLOAD_DIR / file_record.file_path
            
            # 检查物理文件是否存在
            if not file_path.exists():
                logging.warning(f"Physical file missing for record {file_record.competitor_file_id}: {file_path}")
                # 删除数据库中的孤立记录
                db.delete(file_record)
                issues_fixed += 1
            else:
                # 检查文件大小是否正确
                actual_size = file_path.stat().st_size
                if file_record.file_size != actual_size:
                    logging.info(f"Updating file size for {file_record.competitor_file_id}: {file_record.file_size} -> {actual_size}")
                    file_record.file_size = actual_size
                    issues_fixed += 1
        
        db.commit()
        return {
            "message": "File integrity check completed",
            "issues_fixed": issues_fixed
        }
    except Exception as e:
        db.rollback()
        logging.error(f"Error during file integrity check: {str(e)}")
        raise HTTPException(status_code=500, detail=f"File integrity check failed: {str(e)}")

@router.get("/export")
def export_competitor_files(
    batch_id: Optional[int] = Query(None, description="按批次筛选"),
    person_id: Optional[int] = Query(None, description="按人员筛选"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_module_permission(ModuleEnum.COMPETITOR_DATA, "read"))
):
    """导出竞品文件数据为Excel"""
    query = db.query(CompetitorFile).join(Batch).join(Person)
    
    if batch_id:
        query = query.filter(CompetitorFile.batch_id == batch_id)
    
    if person_id:
        query = query.filter(CompetitorFile.person_id == person_id)
    
    files = query.all()
    
    # 准备导出数据
    export_data = []
    for file in files:
        # 获取文件大小
        file_size = None
        if os.path.exists(file.file_path):
            try:
                file_size = os.path.getsize(file.file_path)
            except OSError:
                file_size = None
        
        # 格式化文件大小
        file_size_str = format_file_size(file_size)
        
        # 从文件路径获取文件名
        filename = os.path.basename(file.file_path) if file.file_path else "未知文件"
        
        export_data.append({
            "文件ID": file.competitor_file_id,
            "文件名": filename,
            "关联批次": file.batch.batch_number if file.batch else "未知批次",
            "关联人员": file.person.person_name if file.person else "未知人员",
            "文件大小": file_size_str,
            "文件路径": file.file_path
        })
    
    # 创建DataFrame
    df = pd.DataFrame(export_data)
    
    # 创建临时文件
    with tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx") as tmp_file:
        # 写入Excel文件
        with pd.ExcelWriter(tmp_file.name, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='竞品数据', index=False)
            
            # 调整列宽
            worksheet = writer.sheets['竞品数据']
            for column in worksheet.columns:
                max_length = 0
                column_letter = column[0].column_letter
                for cell in column:
                    try:
                        if len(str(cell.value)) > max_length:
                            max_length = len(str(cell.value))
                    except:
                        pass
                adjusted_width = min(max_length + 2, 50)
                worksheet.column_dimensions[column_letter].width = adjusted_width
        
        # 记录活动
        filter_desc = []
        if batch_id:
            batch = db.query(Batch).filter(Batch.batch_id == batch_id).first()
            if batch:
                filter_desc.append(f"批次：{batch.batch_number}")
        if person_id:
            person = db.query(Person).filter(Person.person_id == person_id).first()
            if person:
                filter_desc.append(f"人员：{person.person_name}")
        
        filter_text = f"（筛选条件：{', '.join(filter_desc)}）" if filter_desc else ""
        log_activity(db, "data_export", f"导出了竞品数据{filter_text}")
        
        # 生成文件名
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"竞品数据导出_{timestamp}.xlsx"
        
        return FileResponse(
            path=tmp_file.name,
            filename=filename,
            media_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )