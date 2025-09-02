import * as XLSX from 'xlsx'

/**
 * Excel导出工具函数
 */

/**
 * 导出数据到Excel文件
 * @param data 要导出的数据数组
 * @param filename 文件名（不包含扩展名）
 * @param sheetNameOrColWidths 工作表名称或列宽配置对象
 */
export function exportToExcel(
  data: any[], 
  filename: string, 
  sheetNameOrColWidths: string | Record<string, number> = 'Sheet1'
) {
  try {
    // 创建工作簿
    const wb = XLSX.utils.book_new()
    const ws = XLSX.utils.json_to_sheet(data)
    
    // 定义数值列名称（需要保持数值格式的列）
    const numericColumns = ['0.00', '2.00', '5.00', '25.00', '初始灵敏度', 'R']
    
    // 设置单元格格式，确保数值列保持数值格式
    if (data.length > 0) {
      const headers = Object.keys(data[0])
      headers.forEach((header, colIndex) => {
        if (numericColumns.includes(header)) {
          // 为数值列设置数值格式
          data.forEach((row, rowIndex) => {
            const cellAddress = XLSX.utils.encode_cell({ r: rowIndex + 1, c: colIndex })
            if (ws[cellAddress] && typeof row[header] === 'number') {
              ws[cellAddress].t = 'n' // 设置单元格类型为数值
              ws[cellAddress].v = row[header] // 确保值为数字
              // 设置数值格式
              if (header === 'R') {
                ws[cellAddress].z = '0.0000' // R值保留4位小数
              } else {
                ws[cellAddress].z = '0.00' // 其他数值保留2位小数
              }
            }
          })
        }
      })
    }
    
    // 设置列宽
    let colWidths: any[]
    let sheetName: string
    
    if (typeof sheetNameOrColWidths === 'string') {
      // 如果是字符串，作为工作表名称，自动计算列宽
      sheetName = sheetNameOrColWidths
      colWidths = Object.keys(data[0] || {}).map(key => {
        const maxLength = Math.max(
          key.length,
          ...data.map(row => String(row[key] || '').length)
        )
        return { wch: Math.min(maxLength + 2, 50) }
      })
    } else {
      // 如果是对象，作为列宽配置
      sheetName = 'Sheet1'
      colWidths = Object.keys(data[0] || {}).map(key => ({
        wch: sheetNameOrColWidths[key] || 15
      }))
    }
    
    ws['!cols'] = colWidths
    
    // 添加工作表到工作簿
    XLSX.utils.book_append_sheet(wb, ws, sheetName)
    
    // 导出文件
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')
    const fullFilename = `${filename}_${timestamp}.xlsx`
    XLSX.writeFile(wb, fullFilename)
    
    return true
  } catch (error) {
    console.error('Excel导出失败:', error)
    return false
  }
}

/**
 * Excel导入工具函数
 */

/**
 * 从Excel文件导入数据
 * @param file Excel文件对象
 * @param expectedColumns 期望的列名数组
 * @param usePositionMode 是否使用列位置模式（不依赖列名）
 * @returns Promise<any[]> 解析后的数据数组
 */
export function importFromExcel(
  file: File,
  expectedColumns?: string[],
  usePositionMode: boolean = false
): Promise<any[]> {
  return new Promise((resolve, reject) => {
    try {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        try {
          const data = new Uint8Array(e.target?.result as ArrayBuffer)
          const workbook = XLSX.read(data, { type: 'array' })
          
          // 获取第一个工作表
          const firstSheetName = workbook.SheetNames[0]
          const worksheet = workbook.Sheets[firstSheetName]
          
          // 将工作表转换为JSON数据
          const jsonData = XLSX.utils.sheet_to_json(worksheet, {
            header: 1, // 使用数组格式，第一行作为表头
            defval: '' // 空单元格的默认值
          }) as any[][]
          
          if (jsonData.length === 0) {
            reject(new Error('Excel文件为空'))
            return
          }
          
          if (usePositionMode) {
            // 位置模式：直接返回原始行数据（跳过表头）
            const dataRows = jsonData.slice(1)
            
            // 过滤掉完全空的行
            const filteredResult = dataRows.filter(row => {
              const values = row.filter(v => v !== null && v !== undefined && v !== '')
              return values.length > 0 // 至少有一个有效值
            })
            
            resolve(filteredResult)
          } else {
            // 传统模式：按列名转换为对象数组
            // 获取表头
            const headers = jsonData[0] as string[]
            
            // 验证列名（如果提供了期望的列名）
            if (expectedColumns && expectedColumns.length > 0) {
              const missingColumns = expectedColumns.filter(col => !headers.includes(col))
              if (missingColumns.length > 0) {
                reject(new Error(`缺少必要的列: ${missingColumns.join(', ')}`))
                return
              }
            }
            
            // 转换数据为对象数组
            const result = jsonData.slice(1).map((row, index) => {
              const obj: any = {}
              headers.forEach((header, colIndex) => {
                if (header && String(header).trim()) {
                  let value = row[colIndex]
                  
                  // 处理空值
                  if (value === undefined || value === null || value === '') {
                    value = null
                  } else if (typeof value === 'string') {
                    value = value.trim()
                    // 尝试转换数字
                    if (!isNaN(Number(value)) && value !== '') {
                      value = Number(value)
                    }
                  }
                  
                  obj[String(header).trim()] = value
                }
              })
              
              // 添加行号用于错误定位
              obj._rowIndex = index + 2 // +2 因为Excel行号从1开始，且第一行是表头
              return obj
            })
            
            // 过滤掉完全空的行
            const filteredResult = result.filter(row => {
              const values = Object.values(row).filter(v => v !== null && v !== undefined && v !== '')
              return values.length > 1 // 至少有一个有效值（除了_rowIndex）
            })
            
            resolve(filteredResult)
          }
        } catch (parseError) {
          reject(new Error(`解析Excel文件失败: ${parseError}`))
        }
      }
      
      reader.onerror = () => {
        reject(new Error('读取文件失败'))
      }
      
      reader.readAsArrayBuffer(file)
    } catch (error) {
      reject(new Error(`导入Excel文件失败: ${error}`))
    }
  })
}



/**
 * 按列位置验证导入的传感器详细信息数据
 * @param data 导入的数据数组（原始行数据）
 * @returns { valid: any[], invalid: any[] } 验证结果
 */
export function validateSensorDetailDataByPosition(data: any[][]): {
  valid: any[],
  invalid: any[]
} {
  const valid: any[] = []
  const invalid: any[] = []
  
  // 定义期望的列顺序和对应的前端列名（按用户Excel格式：灭菌日期、传感器测试编号、探针编号...）
  const columnMapping = [
    { index: 0, field: 'sterilization_date', name: '灭菌日期', required: false },
    { index: 1, field: 'test_number', name: '传感器测试编号', required: true },
    { index: 2, field: 'probe_number', name: '探针编号', required: true },
    { index: 3, field: 'value_0', name: '测试值 (0.00)', required: false, numeric: true },
    { index: 4, field: 'value_2', name: '测试值 (2.00)', required: false, numeric: true },
    { index: 5, field: 'value_5', name: '测试值 (5.00)', required: false, numeric: true },
    { index: 6, field: 'value_25', name: '测试值 (25.00)', required: false, numeric: true },
    { index: 7, field: 'sensitivity', name: '初始灵敏度', required: false, numeric: true },
    { index: 8, field: 'r_value', name: 'R值', required: false, numeric: true },
    { index: 9, field: 'destination', name: '去向', required: false },
    { index: 10, field: 'remarks', name: '备注', required: false }
  ]
  
  data.forEach((row, rowIndex) => {
    const errors: string[] = []
    const normalizedRow: any = {
      _rowIndex: rowIndex + 2 // +2 因为Excel行号从1开始，且第一行是表头
    }
    
    // 按列位置处理数据
    columnMapping.forEach(column => {
      let value = row[column.index]
      
      // 处理空值
      if (value === undefined || value === null || value === '') {
        value = null
      } else if (typeof value === 'string') {
        value = value.trim()
        // 尝试转换数字
        if (column.numeric && !isNaN(Number(value)) && value !== '') {
          value = Number(value)
        }
      }
      
      // 验证必填字段
      if (column.required && (value === null || value === undefined || value === '')) {
        errors.push(`${column.name}不能为空`)
      }
      
      // 验证数值字段
      if (column.numeric && value !== null && value !== undefined && value !== '') {
        if (isNaN(Number(value))) {
          errors.push(`${column.name}必须是数字`)
        }
      }
      
      // 特殊处理日期格式
      if (column.field === 'sterilization_date' && value && typeof value === 'string') {
        // 只处理有效的日期格式（YYYY.MM.DD 或 YYYY-MM-DD 或 YYYY/MM/DD）
        const datePattern = /^\d{4}[.\-\/]\d{1,2}[.\-\/]\d{1,2}$/
        if (datePattern.test(value)) {
          // 将 "YYYY.MM.DD" 或 "YYYY/MM/DD" 格式转换为 "YYYY-MM-DD" 格式
          value = value.replace(/[.\/]/g, '-')
          
          // 对日期进行补零处理，确保格式为 YYYY-MM-DD
          const dateParts = value.split('-')
          if (dateParts.length === 3) {
            const year = dateParts[0]
            const month = dateParts[1].padStart(2, '0')
            const day = dateParts[2].padStart(2, '0')
            value = `${year}-${month}-${day}`
          }
        } else {
          // 对于无效的日期格式（如 "B070905"），设置为 null
          value = null
        }
      }
      
      // 处理字符串字段强制转换
      if (['probe_number', 'destination', 'remarks', 'test_number'].includes(column.field) && value !== null && value !== undefined) {
        value = String(value)
      }
      
      // 验证R值范围
      if (column.field === 'r_value' && value !== null && value !== undefined && value !== '') {
        const numRValue = Number(value)
        if (!isNaN(numRValue) && (numRValue < 0 || numRValue > 1)) {
          errors.push('R值必须在0-1之间')
        }
      }
      
      normalizedRow[column.field] = value
    })
    
    if (errors.length === 0) {
      valid.push(normalizedRow)
    } else {
      invalid.push({
        ...normalizedRow,
        _errors: errors
      })
    }
  })
  
  return { valid, invalid }
}

/**
 * 批量导出多个工作表到一个Excel文件
 * @param sheets 工作表数组，每个元素包含 { data, name }
 * @param filename 文件名（不包含扩展名）
 */
export function exportMultipleSheetsToExcel(
  sheets: Array<{ data: any[], name: string }>,
  filename: string
) {
  try {
    const wb = XLSX.utils.book_new()
    
    sheets.forEach(sheet => {
      const ws = XLSX.utils.json_to_sheet(sheet.data)
      
      // 设置列宽
      if (sheet.data.length > 0) {
        const colWidths = Object.keys(sheet.data[0]).map(key => {
          const maxLength = Math.max(
            key.length,
            ...sheet.data.map(row => String(row[key] || '').length)
          )
          return { wch: Math.min(maxLength + 2, 50) }
        })
        ws['!cols'] = colWidths
      }
      
      XLSX.utils.book_append_sheet(wb, ws, sheet.name)
    })
    
    // 导出文件
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')
    const fullFilename = `${filename}_${timestamp}.xlsx`
    XLSX.writeFile(wb, fullFilename)
    
    return true
  } catch (error) {
    console.error('Excel导出失败:', error)
    return false
  }
}