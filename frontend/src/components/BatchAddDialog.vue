<template>
  <el-dialog
    :model-value="visible"
    title="批量添加佩戴记录"
    width="1200px"
    @close="handleClose"
    @update:model-value="handleClose"
  >
    <div class="batch-form-header">
      <el-button type="primary" @click="addBatchRow">
        <el-icon><Plus /></el-icon>
        添加一行
      </el-button>
      <span class="batch-tip">提示：批次、人员、传感器、佩戴时间为必填项</span>
    </div>
    
    <div class="batch-form-container">
      <div class="batch-item" v-for="(item, index) in batchForm" :key="index">
        <div class="batch-item-header">
          <span class="item-number">第 {{ index + 1 }} 条</span>
          <el-button 
            type="danger" 
            size="small" 
            @click="removeBatchRow(index)"
            :disabled="batchForm.length <= 1"
          >
            删除
          </el-button>
        </div>
        
        <el-form :model="item" label-width="120px">
          <!-- 基本信息 -->
          <div class="form-section">
            <div class="section-title">
              <el-icon><InfoFilled /></el-icon>
              <span>基本信息</span>
            </div>
            <div class="form-row">
              <el-form-item label="批次" required class="form-item-half">
                <el-select
                  v-model="item.batch_id"
                  placeholder="请选择批次"
                  style="width: 100%"
                  filterable
                  @change="() => handleBatchPersonChange(index)"
                >
                  <el-option
                    v-for="batch in availableBatches"
                    :key="batch.batch_id"
                    :label="batch.batch_number"
                    :value="batch.batch_id"
                  />
                </el-select>
              </el-form-item>
              <el-form-item label="人员" required class="form-item-half">
                <el-select
                  v-model="item.person_id"
                  placeholder="请选择人员"
                  style="width: 100%"
                  filterable
                  @change="() => handleBatchPersonChange(index)"
                >
                  <el-option
                    v-for="person in getFilteredPersonsForBatch(item.batch_id)"
                    :key="person.person_id"
                    :label="person.person_name"
                    :value="person.person_id"
                  />
                </el-select>
              </el-form-item>
            </div>


          </div>
          
          <!-- 传感器信息 -->
          <div class="form-section">
            <div class="section-title">
              <el-icon><Monitor /></el-icon>
              <span>传感器信息</span>
            </div>
            <el-form-item label="传感器详情" required>
              <el-select
                v-model="item.sensor_detail_ids"
                placeholder="请选择传感器详情（支持多选）"
                style="width: 100%"
                filterable
                multiple
                collapse-tags
                collapse-tags-tooltip
                @change="(value) => handleSensorSelectionChange(value, index)"
              >
                <el-option
                  v-for="sensor in getAvailableSensorDetailsForBatchAndPerson(item.batch_id, item.person_id)"
                  :key="sensor.sensor_detail_id"
                  :label="`${sensor.test_number} - ${sensor.probe_number}`"
                  :value="sensor.sensor_detail_id"
                />
              </el-select>
            </el-form-item>
            
            <!-- 动态生成的传感器参数卡片 -->
            <div v-if="item.sensor_parameters.length > 0" class="sensor-params-container">
              <div 
                v-for="(param, paramIndex) in item.sensor_parameters" 
                :key="param.sensor_detail_id"
                class="sensor-param-card"
              >
                <div class="sensor-param-header">
                  <el-icon><Cpu /></el-icon>
                  <span>{{ getSensorDisplayName(param.sensor_detail_id) }} 参数</span>
                </div>
                <div class="param-form-grid">

                  <el-form-item label="用户名称">
                    <el-input
                      v-model="param.nickname"
                      placeholder="请输入用户名称"
                      maxlength="100"
                    />
                  </el-form-item>
                  <el-form-item label="佩戴位置">
                    <el-input
                      v-model="param.wear_position"
                      placeholder="请输入佩戴位置"
                      maxlength="100"
                    />
                  </el-form-item>
                  <el-form-item label="敷贴器批号">
                    <el-input
                      v-model="param.applicator_lot_no"
                      placeholder="请输入敷贴器批号"
                      maxlength="255"
                    />
                  </el-form-item>
                  <el-form-item label="传感器批号">
                    <el-input
                      v-model="param.sensor_lot_no"
                      placeholder="自动填充"
                      maxlength="255"
                      readonly
                      style="background-color: #f5f7fa;"
                    />
                  </el-form-item>
                  <el-form-item label="传感器批次">
                    <el-input
                      v-model="param.sensor_batch"
                      placeholder="自动填充"
                      maxlength="255"
                      readonly
                      style="background-color: #f5f7fa;"
                    />
                  </el-form-item>
                  <el-form-item label="传感器号">
                    <el-input
                      v-model="param.sensor_number"
                      placeholder="自动填充"
                      maxlength="255"
                      readonly
                      style="background-color: #f5f7fa;"
                    />
                  </el-form-item>
                  <el-form-item label="发射器号">
                    <el-input
                      v-model="param.transmitter_id"
                      placeholder="自动填充"
                      maxlength="255"
                      readonly
                      style="background-color: #f5f7fa;"
                    />
                  </el-form-item>
                  <el-form-item label="佩戴开始时间">
                    <el-date-picker
                      v-model="param.wear_time"
                      type="datetime"
                      placeholder="选择佩戴开始时间"
                      format="YYYY-MM-DD HH:mm"
                      value-format="YYYY-MM-DD HH:mm:ss"
                      style="width: 100%"
                    />
                  </el-form-item>
                  <el-form-item label="佩戴结束时间">
                    <el-date-picker
                      v-model="param.wear_end_time"
                      type="datetime"
                      placeholder="选择佩戴结束时间"
                      format="YYYY-MM-DD HH:mm"
                      value-format="YYYY-MM-DD HH:mm:ss"
                      style="width: 100%"
                    />
                  </el-form-item>
                  <el-form-item label="异常情况" class="form-item-full">
                    <el-input
                      v-model="param.abnormal_situation"
                      type="textarea"
                      :rows="2"
                      placeholder="请描述异常情况（如有）"
                      maxlength="500"
                    />
                  </el-form-item>
                  <el-form-item label="原因分析" class="form-item-full">
                    <el-input
                      v-model="param.reason_analysis"
                      type="textarea"
                      :rows="2"
                      placeholder="请输入原因分析（如有）"
                      maxlength="500"
                    />
                  </el-form-item>
                </div>
              </div>
            </div>
          </div>
        </el-form>
        
        <el-divider v-if="index < batchForm.length - 1" />
      </div>
    </div>
    
    <template #footer>
      <span class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="loading">
          确定添加
        </el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Plus, InfoFilled, Monitor, Cpu } from '@element-plus/icons-vue'

// 接口定义
interface SensorParameter {
  sensor_detail_id: number
  nickname: string
  wear_position: string
  applicator_lot_no: string
  sensor_lot_no: string
  sensor_batch: string
  sensor_number: string
  transmitter_id: string
  abnormal_situation: string
  reason_analysis: string
  wear_time: string
  wear_end_time: string
}

interface BatchFormItem {
  batch_id: number | null
  person_id: number | null
  sensor_detail_ids: number[]
  sensor_parameters: SensorParameter[]
}

interface Batch {
  batch_id: number
  batch_number: string
}

interface Person {
  person_id: number
  person_name: string
  gender?: 'Male' | 'Female' | 'Other'
  age?: number
  batch_id?: number
  batch_number?: string
}

interface SensorDetail {
  sensor_detail_id: number
  sterilization_date?: string
  test_number: string
  probe_number: string
  value_0?: number
  value_2?: number
  value_5?: number
  value_25?: number
  sensitivity?: number
  r_value?: number
  destination?: string
  remarks?: string
  created_time?: string
}

interface Sensor {
  sensor_id: number
  batch_id: number
  person_id: number
  sensor_detail_id: number
  sensor_lot_no?: string
  sensor_batch?: string
  sensor_number?: string
  transmitter_id?: string
  batch_number?: string
  person_name?: string
  test_number?: string
  probe_number?: string
}

// Props
interface Props {
  visible: boolean
  batches: Batch[]
  persons: Person[]
  availableSensorDetails: SensorDetail[]
  sensors: Sensor[]
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

// Emits
interface Emits {
  'update:visible': [value: boolean]
  'submit': [data: BatchFormItem[]]
  'close': []
}

const emit = defineEmits<Emits>()

// 响应式数据
const batchForm = ref<BatchFormItem[]>([createEmptyBatchItem()])

// 计算属性：可用批次
const availableBatches = computed(() => {
  // 从传感器管理数据中获取已分配传感器的批次
  const sensorBatchIds = new Set(props.sensors?.map(sensor => sensor.batch_id).filter(id => id) || [])
  return props.batches.filter(batch => sensorBatchIds.has(batch.batch_id))
})

// 计算属性：根据批次和人员过滤传感器详情
const getAvailableSensorDetailsForBatchAndPerson = (batchId: number | null, personId: number | null) => {
  if (!batchId || !personId) {
    return [];
  }
  
  // 从传感器管理数据(sensors)中筛选出与当前批次和人员匹配的记录
  const relatedSensors = props.sensors?.filter(sensor => 
    sensor.batch_id === batchId && 
    sensor.person_id === personId &&
    sensor.sensor_detail_id !== null
  ) || [];
  
  // 提取这些记录关联的 sensor_detail_id
  const relatedSensorDetailIds = new Set(relatedSensors.map(sensor => sensor.sensor_detail_id));
  
  // 使用提取出的ID集合来过滤总的传感器详情列表(availableSensorDetails)
  const result = props.availableSensorDetails?.filter(detail => 
    relatedSensorDetailIds.has(detail.sensor_detail_id)
  ) || [];
  
  return result;
}

// 创建空的批量表单项
function createEmptyBatchItem(): BatchFormItem {
  return {
    batch_id: null,
    person_id: null,
    sensor_detail_ids: [],
    sensor_parameters: []
  }
}

// 创建传感器参数
function createSensorParameter(sensorDetailId: number): SensorParameter {
  // 获取当前本地时间
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  const seconds = String(now.getSeconds()).padStart(2, '0')
  const beijingTimeStr = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}` // YYYY-MM-DD HH:mm:ss格式
  
  return {
    sensor_detail_id: sensorDetailId,
    nickname: '',
    wear_position: '',
    applicator_lot_no: '',
    sensor_lot_no: '',
    sensor_batch: '',
    sensor_number: '',
    transmitter_id: '',
    abnormal_situation: '',
    reason_analysis: '',
    wear_time: beijingTimeStr,
    wear_end_time: ''
  }
}

// 添加批量行
const addBatchRow = () => {
  batchForm.value.push(createEmptyBatchItem())
}

// 删除批量行
const removeBatchRow = (index: number) => {
  if (batchForm.value.length > 1) {
    batchForm.value.splice(index, 1)
  }
}

// 根据批次过滤人员
const getFilteredPersonsForBatch = (batchId: number | null) => {
  if (!batchId) return []
  
  // 从传感器管理数据中获取指定批次的已分配传感器的人员
  const sensorPersonIds = new Set(
    props.sensors?.filter(sensor => sensor.batch_id === batchId)
      .map(sensor => sensor.person_id)
      .filter(id => id) || []
  )
  
  return props.persons.filter(person => 
    person.batch_id === batchId && sensorPersonIds.has(person.person_id)
  )
}

// 当批次或人员变化时，清空已选的传感器
const handleBatchPersonChange = (index: number) => {
    batchForm.value[index].sensor_detail_ids = [];
    batchForm.value[index].sensor_parameters = [];
};


// 处理传感器选择变化
const handleSensorSelectionChange = (sensorIds: number[], itemIndex: number) => {
  const item = batchForm.value[itemIndex]
  const currentParams = item.sensor_parameters
  
  // 移除未选中的传感器参数
  item.sensor_parameters = currentParams.filter(param => 
    sensorIds.includes(param.sensor_detail_id)
  )
  
  // 为新选中的传感器添加参数
  sensorIds.forEach(sensorId => {
    const exists = item.sensor_parameters.find(param => 
      param.sensor_detail_id === sensorId
    )
    if (!exists) {
      const newParam = createSensorParameter(sensorId)
      // 自动填充传感器数据，优先查找匹配批次和人员的传感器
      const sensor = props.sensors?.find(s => 
        s.sensor_detail_id === sensorId &&
        s.batch_id === item.batch_id &&
        s.person_id === item.person_id
      ) || props.sensors?.find(s => s.sensor_detail_id === sensorId)
      
      if (sensor) {
        newParam.sensor_lot_no = sensor.sensor_lot_no || ''
        newParam.sensor_batch = sensor.sensor_batch || ''
        newParam.sensor_number = sensor.sensor_number || ''
        newParam.transmitter_id = sensor.transmitter_id || ''
      }
      
      item.sensor_parameters.push(newParam)
    }
  })
}

// 获取传感器显示名称
const getSensorDisplayName = (sensorDetailId: number) => {
  // 首先在可用的传感器详情中查找
  const sensor = props.availableSensorDetails?.find(s => s.sensor_detail_id === sensorDetailId)
  return sensor ? `${sensor.test_number} - ${sensor.probe_number}` : '未知传感器'
}

// 处理关闭
const handleClose = () => {
  emit('update:visible', false)
  emit('close')
}

// 处理提交
const handleSubmit = () => {
  // 验证必填项
  const isValid = batchForm.value.every(item => 
    item.batch_id && 
    item.person_id && 
    item.sensor_detail_ids.length > 0 && 
    item.sensor_parameters.length === item.sensor_detail_ids.length &&
    item.sensor_parameters.every(param => param.wear_time) // 只验证佩戴开始时间
  )
  
  if (!isValid) {
    return
  }
  
  // 构建提交数据，将sensor_detail_id转换为sensor_id
  const submitData = batchForm.value.map(item => {
    const sensorParams = item.sensor_parameters.map(param => {
      // 从sensor_detail_id获取对应的sensor_id
      const sensorDetail = props.availableSensorDetails.find(s => s.sensor_detail_id === param.sensor_detail_id)
      const sensor = props.sensors?.find(s => s.sensor_detail_id === param.sensor_detail_id)
      const sensorId = sensor?.sensor_id || sensorDetail?.sensor_detail_id || param.sensor_detail_id
      
      return {
        sensor_detail_id: param.sensor_detail_id,
        sensor_id: sensorId, // 使用sensor_id而不是sensor_detail_id
        nickname: param.nickname,
        wear_position: param.wear_position,
        applicator_lot_no: param.applicator_lot_no,
        sensor_lot_no: param.sensor_lot_no,
        sensor_batch: param.sensor_batch,
        sensor_number: param.sensor_number,
        transmitter_id: param.transmitter_id,
        abnormal_situation: param.abnormal_situation,
        reason_analysis: param.reason_analysis,
        wear_time: param.wear_time,
        wear_end_time: param.wear_end_time
      }
    })
    
    return {
      batch_id: item.batch_id,
      person_id: item.person_id,
      sensor_detail_ids: item.sensor_detail_ids,
      sensor_parameters: sensorParams
    }
  })
  
  emit('submit', submitData)
}

// 重置表单
const resetForm = () => {
  batchForm.value = [createEmptyBatchItem()]
}

// 监听visible变化，重置表单
watch(() => props.visible, (newVal) => {
  if (newVal) {
    resetForm()
  }
})
</script>

<style lang="scss" scoped>
.batch-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 16px;
  background-color: #f8f9fa;
  border-radius: 8px;
  
  .batch-tip {
    color: #666;
    font-size: 14px;
  }
}

.batch-form-container {
  max-height: 60vh;
  overflow-y: auto;
  padding: 0 4px;
}

.batch-item {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  background-color: #fafafa;
  
  &:last-child {
    margin-bottom: 0;
  }
}

.batch-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 8px;
  border-bottom: 1px solid #e4e7ed;
}

.item-number {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.form-section {
  margin-bottom: 20px;
  
  &:last-child {
    margin-bottom: 0;
  }
}

.section-title {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
  padding: 8px 0;
  border-bottom: 1px solid #e4e7ed;
  
  .el-icon {
    margin-right: 8px;
    color: #409eff;
    font-size: 16px;
  }
  
  span {
    font-size: 14px;
    font-weight: 600;
    color: #303133;
  }
}

.form-row {
  display: flex;
  gap: 16px;
  
  .form-item-half {
    flex: 1;
  }
}

.form-item-full {
  width: 100%;
  
  .el-textarea {
    width: 100%;
  }
  
  .el-textarea__inner {
    min-height: 80px;
    resize: vertical;
  }
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

:deep(.el-form-item) {
  margin-bottom: 16px;
  
  .el-form-item__label {
    font-size: 14px;
    font-weight: 500;
    color: #606266;
  }
  
  .el-form-item__content {
    font-size: 14px;
  }
}

:deep(.param-form-grid .el-form-item) {
  margin-bottom: 0;
}

:deep(.el-input__inner),
:deep(.el-select .el-input__inner),
:deep(.el-date-editor .el-input__inner) {
  font-size: 14px;
}

:deep(.el-button--small) {
  font-size: 12px;
}

:deep(.el-divider) {
  margin: 20px 0;
}

.sensor-params-container {
  margin-top: 16px;
}

.sensor-param-card {
  border: 1px solid #dcdfe6;
  border-radius: 6px;
  padding: 16px;
  margin-bottom: 12px;
  background-color: #f9f9f9;
  
  &:last-child {
    margin-bottom: 0;
  }
}

.sensor-param-header {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #e4e7ed;
  
  .el-icon {
    margin-right: 8px;
    color: #67c23a;
    font-size: 14px;
  }
  
  span {
    font-size: 13px;
    font-weight: 600;
    color: #303133;
  }
}

.param-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  
  .el-form-item {
    margin-bottom: 0;
  }
  
  .form-item-full {
    grid-column: 1 / -1;
  }
}
</style>
