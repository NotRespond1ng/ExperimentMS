<template>
  <div class="wear-record-management">
    <div class="page-header">
      <h2>佩戴记录管理</h2>
      <p>管理传感器佩戴记录和异常情况</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchQuery"
          placeholder="请输入受试者姓名"
          style="width: 300px; margin-right: 12px"
          clearable
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-input
          v-model="transmitterSearchQuery"
          placeholder="请输入发射器号"
          style="width: 200px; margin-right: 12px"
          clearable
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-select v-model="filterBatchId" placeholder="筛选实验批次" clearable style="width: 180px; margin-right: 12px" @change="handleSearch">
          <el-option
            v-for="batch in batches"
            :key="batch.batch_id"
            :label="batch.batch_number"
            :value="batch.batch_id"
          />
        </el-select>
        
        <el-select v-model="filterStatus" placeholder="状态筛选" clearable style="width: 150px">
          <el-option label="全部" value="" />
          <el-option label="正常" value="正常" />
          <el-option label="异常" value="异常" />
        </el-select>
      </div>

      <div class="toolbar-right">
        <el-button @click="exportData">
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button type="primary" @click="showAddDialog = true">
          <el-icon><Plus /></el-icon>
          添加记录
        </el-button>
      </div>
    </div>

    <!-- 数据表格 -->
    <el-card>
      <el-table
        :data="paginatedData"
        v-loading="loading"
        stripe
        style="width: 100%"
        @sort-change="handleSortChange"
      >
        <el-table-column prop="wear_record_id" label="ID" width="80" sortable />
        <el-table-column prop="person_name" label="受试者姓名" width="120" />
        <el-table-column prop="batch_number" label="实验批次号" width="120" />
        <el-table-column prop="sensor_id" label="传感器ID" width="120" />
        <el-table-column prop="applicator_lot_no" label="敷贴器批号" width="140" />
        <el-table-column prop="transmitter_id" label="发射器号" width="120" />
        <el-table-column prop="sensor_lot_no" label="传感器批号" width="140" />
        <el-table-column prop="sensor_batch" label="传感器批次" width="140" />
        <el-table-column prop="value_0" label="0.00" width="120">
          <template #default="{ row }">
            <span>{{ 
              (() => {
                const detail = getSensorDetailBySensorBatch(row.sensor_batch);
                return detail && detail.value_0 !== null && detail.value_0 !== undefined && detail.value_0 !== '' 
                  ? detail.value_0 
                  : '-';
              })()
            }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="value_2" label="2.00" width="120">
          <template #default="{ row }">
            <span>{{ 
              (() => {
                const detail = getSensorDetailBySensorBatch(row.sensor_batch);
                return detail && detail.value_2 !== null && detail.value_2 !== undefined && detail.value_2 !== '' 
                  ? detail.value_2 
                  : '-';
              })()
            }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="value_5" label="5.00" width="120">
          <template #default="{ row }">
            <span>{{ 
              (() => {
                const detail = getSensorDetailBySensorBatch(row.sensor_batch);
                return detail && detail.value_5 !== null && detail.value_5 !== undefined && detail.value_5 !== '' 
                  ? detail.value_5 
                  : '-';
              })()
            }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="value_25" label="25.00" width="130">
          <template #default="{ row }">
            <span>{{ 
              (() => {
                const detail = getSensorDetailBySensorBatch(row.sensor_batch);
                return detail && detail.value_25 !== null && detail.value_25 !== undefined && detail.value_25 !== '' 
                  ? detail.value_25 
                  : '-';
              })()
            }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="sensitivity" label="初始灵敏度" width="120">
          <template #default="{ row }">
            <span>{{ 
              (() => {
                const detail = getSensorDetailBySensorBatch(row.sensor_batch);
                return detail && detail.sensitivity !== null && detail.sensitivity !== undefined && detail.sensitivity !== '' 
                  ? detail.sensitivity 
                  : '-';
              })()
            }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="wear_position" label="佩戴位置" width="100">
          <template #default="{ row }">
            <el-tag :type="getPositionTagType(row.wear_position)">
              {{ getWearPositionLabel(row.wear_position) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="wear_time" label="佩戴时间" width="180" sortable>
          <template #default="{ row }">
            {{ formatDateTime(row.wear_time) }}
          </template>
        </el-table-column>
        <el-table-column prop="abnormal_situation" label="异常情况" width="150">
          <template #default="{ row }">
            <span v-if="row.abnormal_situation" class="text-red-600">{{ row.abnormal_situation }}</span>
            <span v-else class="text-gray-400">无</span>
          </template>
        </el-table-column>
        <el-table-column prop="cause_analysis" label="原因分析" width="200">
          <template #default="{ row }">
            <span v-if="row.cause_analysis" class="text-sm">{{ row.cause_analysis }}</span>
            <span v-else class="text-gray-400">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="remarks" label="备注" width="150" show-overflow-tooltip />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="editRecord(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteRecord(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页组件 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="filteredData.length"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 添加/编辑对话框 -->
    <el-dialog
      v-model="showAddDialog"
      :title="editingRecord ? '编辑佩戴记录' : '添加佩戴记录'"
      width="600px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        label-width="120px"
      >
        <el-form-item label="批次" prop="batch_id">
          <el-select v-model="formData.batch_id" placeholder="选择批次" style="width: 100%" @change="handleBatchChange">
            <el-option
              v-for="batch in batches"
              :key="batch.batch_id"
              :label="batch.batch_number"
              :value="batch.batch_id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="受试者" prop="person_id">
          <el-select v-model="formData.person_id" placeholder="选择受试者" style="width: 100%" :disabled="!formData.batch_id">
            <el-option
              v-for="person in filteredPersons"
              :key="person.person_id"
              :label="person.person_name"
              :value="person.person_id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="敷贴器批号">
          <el-input v-model="formData.applicator_lot_no" placeholder="敷贴器批号" />
        </el-form-item>

        <el-form-item label="传感器批号">
          <el-input
            v-model="formData.sensor_lot_no"
            placeholder="传感器批号将根据选择自动填充"
            disabled
          />
        </el-form-item>

        <el-form-item label="传感器" prop="sensor_id">
          <el-select v-model="formData.sensor_id" placeholder="选择传感器" style="width: 100%" @change="handleSensorChange">
            <el-option
              v-for="sensor in sensors"
              :key="sensor.sensor_id"
              :label="`${sensor.sensor_batch || sensor.sensor_number} (ID: ${sensor.sensor_id}) - ${sensor.person_name}`"
              :value="sensor.sensor_id.toString()"
            />
          </el-select>
          <div class="form-tip">
            选择已配置的传感器
          </div>
        </el-form-item>

        <el-form-item label="传感器批次">
          <el-input
            v-model="formData.sensor_batch"
            placeholder="传感器批次将根据选择自动填充"
            disabled
          />
        </el-form-item>

        <el-form-item label="传感器号">
          <el-input
            v-model="formData.sensor_number"
            placeholder="传感器号将根据选择自动填充"
            disabled
          />
        </el-form-item>

        <el-form-item label="发射器号">
          <el-input
            v-model="formData.transmitter_id"
            placeholder="发射器号将根据选择自动填充或手动输入"
          />
        </el-form-item>

        <el-form-item label="佩戴位置" prop="wear_position">
          <el-select v-model="formData.wear_position" placeholder="选择佩戴位置" style="width: 100%">
            <el-option label="左一" value="LEFT_ONE" />
            <el-option label="左二" value="LEFT_TWO" />
            <el-option label="右一" value="RIGHT_ONE" />
            <el-option label="右二" value="RIGHT_TWO" />
          </el-select>
        </el-form-item>

        <el-form-item label="异常情况">
          <el-input
            v-model="formData.abnormal_situation"
            placeholder="如有异常情况请描述"
            type="textarea"
            :rows="2"
          />
        </el-form-item>

        <el-form-item label="原因分析">
          <el-input
            v-model="formData.cause_analysis"
            placeholder="异常原因分析"
            type="textarea"
            :rows="2"
          />
        </el-form-item>

        <el-form-item label="备注">
          <el-input
            v-model="formData.remarks"
            placeholder="其他备注信息"
            type="textarea"
            :rows="2"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="showAddDialog = false">取消</el-button>
          <el-button type="primary" @click="submitForm">确定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { Search, Plus, Download } from '@element-plus/icons-vue'
import { ApiService } from '@/services/api'
import { formatDateTime } from '@/utils/formatters'
import { exportToExcel } from '@/utils/excel'

// 响应式数据
const loading = ref(false)
const searchQuery = ref('')
const transmitterSearchQuery = ref('')
const filterStatus = ref('')
const filterBatchId = ref('')
const currentPage = ref(1)
const pageSize = ref(20)
const showAddDialog = ref(false)
const editingRecord = ref<any>(null)
const formRef = ref<FormInstance>()

// 数据列表
const wearRecords = ref<any[]>([])
const persons = ref<any[]>([])
const batches = ref<any[]>([])
const sensors = ref<any[]>([])
const sensorDetails = ref<any[]>([])

// 表单数据
const formData = reactive({
  batch_id: '',
  person_id: '',
  sensor_id: '',
  applicator_lot_no: '',
  sensor_lot_no: '',
  sensor_batch: '',
  sensor_number: '',
  transmitter_id: '',
  wear_position: '',
  abnormal_situation: '',
  cause_analysis: '',
  remarks: ''
})

// 表单验证规则
const formRules: FormRules = {
  batch_id: [{ required: true, message: '请选择批次', trigger: 'change' }],
  person_id: [{ required: true, message: '请选择受试者', trigger: 'change' }],
  sensor_number: [{ required: true, message: '请选择传感器号', trigger: 'change' }],
  wear_position: [{ required: true, message: '请选择佩戴位置', trigger: 'change' }]
}

// 计算属性
const filteredData = computed(() => {
  let filtered = wearRecords.value

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(record =>
      record.person_name?.toLowerCase().includes(query)
    )
  }

  if (transmitterSearchQuery.value) {
    const query = transmitterSearchQuery.value.toLowerCase()
    filtered = filtered.filter(record =>
      record.transmitter_id?.toLowerCase().includes(query)
    )
  }

  if (filterBatchId.value) {
    filtered = filtered.filter(record => 
      record.batch_id === filterBatchId.value
    )
  }

  if (filterStatus.value) {
    filtered = filtered.filter(record => {
      if (filterStatus.value === '正常') {
        return !record.abnormal_situation
      } else if (filterStatus.value === '异常') {
        return record.abnormal_situation
      }
      return true
    })
  }

  return filtered
})

const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// 获取唯一的传感器批号列表
const uniqueSensorLotNos = computed(() => {
  const lotNos = sensors.value
    .map(sensor => sensor.sensor_lot_no)
    .filter(lotNo => lotNo && lotNo.trim() !== '')
  return [...new Set(lotNos)]
})

// 获取唯一的传感器批次列表
const uniqueSensorBatches = computed(() => {
  const batches = sensors.value
    .map(sensor => sensor.sensor_batch)
    .filter(batch => batch && batch.trim() !== '')
  return [...new Set(batches)]
})

// 获取唯一的发射器号列表
const uniqueTransmitterIds = computed(() => {
  const transmitterIds = sensors.value
    .map(sensor => sensor.transmitter_id)
    .filter(id => id && id.trim() !== '')
  return [...new Set(transmitterIds)]
})

// 根据选择的批次过滤受试者
const filteredPersons = computed(() => {
  if (!formData.batch_id) {
    return []
  }
  return persons.value.filter(person => person.batch_id === formData.batch_id)
})

// 根据sensor_batch获取对应的传感器详细信息
const getSensorDetailBySensorBatch = (sensorBatch: string) => {
  if (!sensorBatch || !sensorDetails.value.length) return null
  return sensorDetails.value.find(detail => detail.test_number === sensorBatch)
}

// 佩戴位置映射函数
const getWearPositionLabel = (value: string) => {
  const positionMap: Record<string, string> = {
    'LEFT_ONE': '左一',
    'LEFT_TWO': '左二',
    'RIGHT_ONE': '右一',
    'RIGHT_TWO': '右二'
  }
  return positionMap[value] || value
}

const getPositionTagType = (position: string) => {
  const typeMap: Record<string, string> = {
    'LEFT_ONE': 'primary',
    'LEFT_TWO': 'success',
    'RIGHT_ONE': 'warning',
    'RIGHT_TWO': 'danger'
  }
  return typeMap[position] || ''
}

// 数据加载方法
const loadWearRecords = async () => {
  try {
    loading.value = true
    const response = await ApiService.getWearRecords()
    wearRecords.value = response
  } catch (error) {
    console.error('加载佩戴记录失败:', error)
    ElMessage.error('加载佩戴记录失败')
  } finally {
    loading.value = false
  }
}

const loadPersons = async () => {
  try {
    const response = await ApiService.getPersons()
    persons.value = response
  } catch (error) {
    console.error('加载受试者列表失败:', error)
  }
}

const loadBatches = async () => {
  try {
    const response = await ApiService.getBatches()
    batches.value = response
  } catch (error) {
    console.error('加载批次列表失败:', error)
  }
}

const loadSensors = async () => {
  try {
    const response = await ApiService.getSensors()
    sensors.value = response
  } catch (error) {
    console.error('加载传感器列表失败:', error)
  }
}

const loadSensorDetails = async () => {
  try {
    const response = await ApiService.getSensorDetails()
    sensorDetails.value = response
  } catch (error) {
    console.error('加载传感器详细信息失败:', error)
  }
}

// 事件处理方法
const handleSearch = () => {
  currentPage.value = 1
}

const handleSortChange = ({ column, prop, order }: any) => {
  if (order === 'ascending') {
    wearRecords.value.sort((a, b) => a[prop] > b[prop] ? 1 : -1)
  } else if (order === 'descending') {
    wearRecords.value.sort((a, b) => a[prop] < b[prop] ? 1 : -1)
  }
}

const handleSizeChange = (val: number) => {
  pageSize.value = val
  currentPage.value = 1
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
}

const handleBatchChange = () => {
  // 当批次改变时，清空受试者选择
  formData.person_id = ''
}

const handleSensorChange = (sensorId: string) => {
  // 根据选择的传感器ID找到对应的传感器信息
  const selectedSensor = sensors.value.find(sensor => sensor.sensor_id.toString() === sensorId)
  if (selectedSensor) {
    formData.sensor_batch = selectedSensor.sensor_batch || ''
    formData.sensor_number = selectedSensor.sensor_number || ''
    formData.sensor_lot_no = selectedSensor.sensor_lot_no || ''
    formData.transmitter_id = selectedSensor.transmitter_id || ''
  }
}

const editRecord = (record: any) => {
  editingRecord.value = record
  Object.assign(formData, {
    batch_id: record.batch_id.toString(),
    person_id: record.person_id.toString(),
    sensor_id: record.sensor_id?.toString() || '',
    applicator_lot_no: record.applicator_lot_no || '',
    sensor_lot_no: record.sensor_lot_no || '',
    sensor_batch: record.sensor_batch || '',
    sensor_number: record.sensor_number || '',
    transmitter_id: record.transmitter_id || '',
    wear_position: record.wear_position,
    abnormal_situation: record.abnormal_situation || '',
    cause_analysis: record.cause_analysis || '',
    remarks: record.remarks || ''
  })
  showAddDialog.value = true
}

const deleteRecord = async (record: any) => {
  try {
    await ElMessageBox.confirm('确定要删除这条佩戴记录吗？', '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    await ApiService.deleteWearRecord(record.wear_record_id)
    ElMessage.success('删除成功')
    await loadWearRecords()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除佩戴记录失败:', error)
      ElMessage.error('删除失败')
    }
  }
}

const submitForm = async () => {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    
    // 准备提交的数据，确保数据类型正确
    const submitData = {
      batch_id: parseInt(formData.batch_id),
      person_id: parseInt(formData.person_id),
      sensor_id: parseInt(formData.sensor_id), // 这里的sensor_id对应sensors表的sensor_id
      applicator_lot_no: formData.applicator_lot_no || undefined,
      sensor_lot_no: formData.sensor_lot_no || undefined,
      sensor_batch: formData.sensor_batch || undefined,
      sensor_number: formData.sensor_number || undefined,
      transmitter_id: formData.transmitter_id || undefined,
      wear_position: formData.wear_position || undefined,
      abnormal_situation: formData.abnormal_situation || undefined,
      cause_analysis: formData.cause_analysis || undefined,
      remarks: formData.remarks || undefined
    }
    
    if (editingRecord.value) {
      await ApiService.updateWearRecord(editingRecord.value.wear_record_id, submitData)
      ElMessage.success('更新成功')
    } else {
      await ApiService.createWearRecord(submitData)
      ElMessage.success('添加成功')
    }

    showAddDialog.value = false
    await loadWearRecords()
  } catch (error: any) {
    console.error('提交表单失败:', error)
    
    // 处理后端返回的具体错误信息
    let errorMessage = '操作失败'
    
    if (error?.response?.data?.detail) {
      errorMessage = error.response.data.detail
    } else if (error?.message) {
      errorMessage = error.message
    }
    
    // 显示友好的错误提示
    ElMessage.error(errorMessage)
  }
}

const resetForm = () => {
  editingRecord.value = null
  Object.assign(formData, {
    batch_id: '',
    person_id: '',
    sensor_id: '',
    applicator_lot_no: '',
    sensor_lot_no: '',
    sensor_batch: '',
    sensor_number: '',
    transmitter_id: '',
    wear_position: '',
    abnormal_situation: '',
    cause_analysis: '',
    remarks: ''
  })
  formRef.value?.resetFields()
}

const exportData = () => {
  const exportData = filteredData.value.map(record => {
    const detail = getSensorDetailBySensorBatch(record.sensor_batch)
    return {
      'ID': record.wear_record_id,
      '受试者姓名': record.person_name,
      '实验批次号': record.batch_number,
      '传感器ID': record.sensor_id,
      '敷贴器批号': record.applicator_lot_no || '',
      '发射器号': record.transmitter_id || '',
      '传感器批号': record.sensor_lot_no || '',
      '传感器批次': record.sensor_batch || '',
      '0.00': detail && detail.value_0 !== null && detail.value_0 !== undefined && detail.value_0 !== '' ? detail.value_0 : '',
      '2.00': detail && detail.value_2 !== null && detail.value_2 !== undefined && detail.value_2 !== '' ? detail.value_2 : '',
      '5.00': detail && detail.value_5 !== null && detail.value_5 !== undefined && detail.value_5 !== '' ? detail.value_5 : '',
      '25.00': detail && detail.value_25 !== null && detail.value_25 !== undefined && detail.value_25 !== '' ? detail.value_25 : '',
      '初始灵敏度': detail && detail.sensitivity !== null && detail.sensitivity !== undefined && detail.sensitivity !== '' ? detail.sensitivity : '',
      '佩戴位置': getWearPositionLabel(record.wear_position),
      '佩戴时间': formatDateTime(record.wear_time),
      '异常情况': record.abnormal_situation || '',
      '原因分析': record.cause_analysis || '',
      '备注': record.remarks || ''
    }
  })

  exportToExcel(exportData, '佩戴记录数据')
}

// 生命周期
onMounted(async () => {
  await Promise.all([
    loadWearRecords(),
    loadPersons(),
    loadBatches(),
    loadSensors(),
    loadSensorDetails()
  ])
})
</script>

<style scoped>
.wear-record-management {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 24px;
}

.page-header h2 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 24px;
  font-weight: 600;
}

.page-header p {
  margin: 0;
  color: #909399;
  font-size: 14px;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 16px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
  padding: 20px 0;
}

:deep(.el-table) {
  font-size: 14px;
}

:deep(.el-table th) {
  background-color: #fafafa;
  color: #606266;
  font-weight: 600;
}
</style>