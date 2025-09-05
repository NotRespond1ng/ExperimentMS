<template>
  <el-dialog
    :model-value="visible"
    :title="isEdit ? '编辑佩戴记录' : '新建佩戴记录'"
    width="800px"
    @update:model-value="handleClose"
    @close="handleClose"
  >
    <el-form
      ref="formRef"
      :model="formData"
      :rules="formRules"
      label-width="120px"
      class="wear-record-form"
    >
      <!-- 基本信息 -->
      <div class="form-section">
        <div class="section-title">
          <el-icon><InfoFilled /></el-icon>
          <span>基本信息</span>
        </div>
        <div class="form-row">
          <el-form-item label="批次" prop="batch_id" class="form-item-half">
            <el-select
              v-model="formData.batch_id"
              placeholder="请选择批次"
              filterable
              clearable
              @change="handleBatchChange"
            >
              <el-option
                v-for="batch in availableBatches"
                :key="batch.batch_id"
                :label="batch.batch_number"
                :value="batch.batch_id"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="人员" prop="person_id" class="form-item-half">
            <el-select
              v-model="formData.person_id"
              placeholder="请选择人员"
              filterable
              clearable
            >
              <el-option
                v-for="person in availablePersons"
                :key="person.person_id"
                :label="person.person_name"
                :value="person.person_id"
              />
            </el-select>
          </el-form-item>
        </div>

        <div class="form-row">
        </div>


      </div>

      <!-- 传感器信息 -->
      <div class="form-section">
        <div class="section-title">
          <el-icon><Monitor /></el-icon>
          <span>传感器信息</span>
        </div>
        <el-form-item label="传感器详情" prop="sensor_detail_ids">
          <el-select
            v-model="formData.sensor_detail_ids"
            multiple
            placeholder="请选择传感器详情"
            filterable
            style="width: 100%"
            @change="handleSensorSelectionChange"
          >
            <el-option
              v-for="sensor in availableSensorDetails"
              :key="sensor.sensor_detail_id"
              :label="getSensorDisplayName(sensor)"
              :value="sensor.sensor_detail_id"
            />
          </el-select>
        </el-form-item>

        <!-- 传感器参数 -->
        <div v-if="formData.sensor_parameters.length > 0" class="sensor-params-section">
          <div class="params-header">
            <span>传感器参数配置</span>
          </div>
          <div class="sensor-params-list">
            <div
              v-for="(param, index) in formData.sensor_parameters"
              :key="param.sensor_detail_id"
              class="sensor-param-card"
            >
              <div class="param-card-header">
                <span class="sensor-name">{{ getSensorNameById(param.sensor_detail_id) }}</span>
                <el-button
                  type="danger"
                  size="small"
                  text
                  @click="removeSensorParam(index)"
                >
                  <el-icon><Delete /></el-icon>
                </el-button>
              </div>
              <div class="param-form-grid">

                <el-form-item :label="`用户名称`">
                  <el-input v-model="param.nickname" placeholder="请输入用户名称" />
                </el-form-item>
                <el-form-item :label="`敷贴器批号`">
                  <el-input v-model="param.applicator_lot_no" placeholder="请输入敷贴器批号" />
                </el-form-item>
                <el-form-item :label="`传感器批号`">
                  <el-input v-model="param.sensor_lot_no" placeholder="请输入传感器批号" readonly class="readonly-field" />
                </el-form-item>
                <el-form-item :label="`传感器批次`">
                  <el-input v-model="param.sensor_batch" placeholder="请输入传感器批次" readonly class="readonly-field" />
                </el-form-item>
                <el-form-item :label="`传感器号`">
                  <el-input v-model="param.sensor_number" placeholder="请输入传感器号" readonly class="readonly-field" />
                </el-form-item>
                <el-form-item :label="`发射器号`">
                  <el-input v-model="param.transmitter_id" placeholder="请输入发射器号" readonly class="readonly-field" />
                </el-form-item>
                <el-form-item :label="`佩戴位置`">
                  <el-input v-model="param.wear_position" placeholder="请输入佩戴位置" maxlength="20" />
                </el-form-item>
                <el-form-item :label="`佩戴开始时间`">
                  <el-date-picker
                    v-model="param.wear_time"
                    type="date"
                    placeholder="选择佩戴开始时间"
                    format="YYYY-MM-DD"
                    value-format="YYYY-MM-DD"
                    style="width: 100%"
                  />
                </el-form-item>
                <el-form-item :label="`佩戴结束时间`">
                  <el-date-picker
                    v-model="param.wear_end_time"
                    type="date"
                    placeholder="选择佩戴结束时间（可选）"
                    format="YYYY-MM-DD"
                    value-format="YYYY-MM-DD"
                    style="width: 100%"
                  />
                </el-form-item>
                <el-form-item :label="`异常情况`" class="form-item-full">
                  <el-input v-model="param.abnormal_situation" type="textarea" :rows="2" placeholder="请描述异常情况（如有）" />
                </el-form-item>
                <el-form-item :label="`原因分析`" class="form-item-full">
                  <el-input v-model="param.reason_analysis" type="textarea" :rows="2" placeholder="请输入原因分析（如有）" />
                </el-form-item>
              </div>
            </div>
          </div>
        </div>
      </div>
    </el-form>

    <template #footer>
      <div class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" :loading="loading" @click="handleSubmit">
          {{ isEdit ? '更新' : '创建' }}
        </el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { InfoFilled, Document, Monitor, Delete } from '@element-plus/icons-vue'

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

interface SensorParameter {
  sensor_detail_id: number
  sensor_id: number
  user_name: string
  nickname: string
  applicator_lot_no: string
  sensor_lot_no: string
  sensor_batch: string
  sensor_number: string
  transmitter_id: string
  wear_position: string
  abnormal_situation: string
  reason_analysis: string
  wear_time: string
  wear_end_time: string
  wear_record_id?: number
}

interface WearRecordForm {
  wear_record_id?: number
  batch_id: number | null
  person_id: number | null
  sensor_detail_ids: number[]
  sensor_parameters: SensorParameter[]
}

interface Sensor {
  sensor_id: number
  sensor_lot_no?: string
  sensor_batch?: string
  sensor_number?: string
  transmitter_id?: string
  person_id: number
  batch_id: number
  sensor_detail_id?: number
  start_time: string
  end_time?: string
  end_reason?: string
  person_name?: string
  batch_number?: string
}

interface Props {
  visible: boolean
  isEdit: boolean
  editData?: any
  batches: Batch[]
  persons: Person[]
  sensorDetails: SensorDetail[]
  sensors: Sensor[]
  usedSensorIds?: number[]
  loading: boolean
  removeSensorFromEdit?: (wearRecordId: number) => Promise<void>
}

interface Emits {
  (e: 'update:visible', value: boolean): void
  (e: 'submit', data: WearRecordForm): void
  (e: 'close'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const formRef = ref()

const formData = reactive<WearRecordForm>({
  batch_id: null,
  person_id: null,
  sensor_detail_ids: [],
  sensor_parameters: []
})

const formRules = {
  batch_id: [{ required: true, message: '请选择批次', trigger: 'change' }],
  person_id: [{ required: true, message: '请选择人员', trigger: 'change' }],
  sensor_detail_ids: [{ required: true, message: '请选择至少一个传感器详情', trigger: 'change' }]
}

// 计算属性
const availableBatches = computed(() => {
  // 仅显示传感器管理模块中已分配传感器的批次
  const assignedBatchIds = new Set(props.sensors?.map(s => s.batch_id) || [])
  const filteredBatches = props.batches?.filter(batch => assignedBatchIds.has(batch.batch_id)) || []
  // 按批次ID倒序排列，新建的批次显示在前面
  return [...filteredBatches].sort((a, b) => b.batch_id - a.batch_id)
})

const availablePersons = computed(() => {
  if (!formData.batch_id) return []
  // 仅显示选定批次中在传感器管理模块中已分配传感器的人员
  const assignedPersonIds = new Set(
    props.sensors?.filter(s => s.batch_id === formData.batch_id).map(s => s.person_id) || []
  )
  return props.persons?.filter(person => {
    return person.batch_id === formData.batch_id && assignedPersonIds.has(person.person_id)
  }) || []
})

const availableSensorDetails = computed(() => {
  if (!formData.batch_id || !formData.person_id) {
    return [];
  }
  
  // 从传感器管理数据(sensors)中筛选出与当前批次和人员匹配的记录
  const relatedSensors = props.sensors?.filter(sensor => 
    sensor.batch_id === formData.batch_id && 
    sensor.person_id === formData.person_id &&
    sensor.sensor_detail_id !== null
  ) || [];
  
  // 提取这些记录关联的 sensor_detail_id
  const relatedSensorDetailIds = new Set(relatedSensors.map(sensor => sensor.sensor_detail_id));
  
  // 使用提取出的ID集合来过滤总的传感器详情列表(sensorDetails)
  let result = props.sensorDetails?.filter(detail => 
    relatedSensorDetailIds.has(detail.sensor_detail_id)
  ) || [];
  
  // 在新建模式下，排除已佩戴的传感器详情
  if (!props.isEdit && props.usedSensorIds && props.usedSensorIds.length > 0) {
    result = result.filter(detail => 
      !props.usedSensorIds!.includes(detail.sensor_detail_id)
    );
  }
  
  return result;
})

// 方法
const createDefaultSensorParam = (sensorDetailId: number): SensorParameter => {
  // 获取佩戴开始时间和结束时间
  let wearTime = ''
  let wearEndTime = ''
  
  if (props.isEdit && props.editData?.sensor_parameters) {
    // 编辑模式：从 editData 中查找对应传感器的数据
    const existingParam = props.editData.sensor_parameters.find(
      (param: SensorParameter) => param.sensor_detail_id === sensorDetailId
    )
    if (existingParam) {
      wearTime = existingParam.wear_time || ''
      wearEndTime = existingParam.wear_end_time || ''
    } else {
      // 如果编辑模式下没有找到对应的数据，使用当前日期（用于编辑时添加新传感器的情况）
      const now = new Date()
      const year = now.getFullYear()
      const month = String(now.getMonth() + 1).padStart(2, '0')
      const day = String(now.getDate()).padStart(2, '0')
      wearTime = `${year}-${month}-${day}`
      wearEndTime = ''
    }
  } else {
    // 新建模式：使用当前本地时间，格式为 YYYY-MM-DD
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    wearTime = `${year}-${month}-${day}`
    wearEndTime = ''
  }
  
  // 从传感器管理数据中查找对应的sensor_id
  const relatedSensor = props.sensors?.find(sensor => 
    sensor.sensor_detail_id === sensorDetailId &&
    sensor.batch_id === formData.batch_id &&
    sensor.person_id === formData.person_id
  )
  
  // 在编辑模式下，从现有数据中获取其他字段的值
  let defaultParam: SensorParameter = {
    sensor_detail_id: sensorDetailId,
    sensor_id: relatedSensor?.sensor_id || 0,
    user_name: '', // 用户名称（用户手动输入）
    nickname: '', // 用户名称（用户手动输入的昵称）
    applicator_lot_no: '',
    sensor_lot_no: relatedSensor?.sensor_lot_no || '',
    sensor_batch: relatedSensor?.sensor_batch || '',
    sensor_number: relatedSensor?.sensor_number || '',
    transmitter_id: relatedSensor?.transmitter_id || '',
    wear_position: '',
    abnormal_situation: '',
    reason_analysis: '',
    wear_time: wearTime,
    wear_end_time: wearEndTime
  }
  
  // 如果是编辑模式，从现有数据中填充其他字段
  if (props.isEdit && props.editData?.sensor_parameters) {
    const existingParam = props.editData.sensor_parameters.find(
      (param: SensorParameter) => param.sensor_detail_id === sensorDetailId
    )
    if (existingParam) {
      defaultParam = {
        ...defaultParam,
        wear_record_id: existingParam.wear_record_id,
        nickname: existingParam.nickname || '',
        applicator_lot_no: existingParam.applicator_lot_no || '',
        sensor_lot_no: existingParam.sensor_lot_no || relatedSensor?.sensor_lot_no || '',
        sensor_batch: existingParam.sensor_batch || relatedSensor?.sensor_batch || '',
        sensor_number: existingParam.sensor_number || '',
        transmitter_id: existingParam.transmitter_id || relatedSensor?.transmitter_id || '',
        wear_position: existingParam.wear_position || '',
        abnormal_situation: existingParam.abnormal_situation || '',
        reason_analysis: existingParam.reason_analysis || '',
        wear_end_time: existingParam.wear_end_time || wearEndTime
      }
    }
  }
  
  return defaultParam
}

const getSensorDisplayName = (sensor: SensorDetail): string => {
  return `传感器 ${sensor.test_number} - ${sensor.probe_number}`
}

const getSensorNameById = (sensorDetailId: number | null | undefined): string => {
  if (sensorDetailId === null || sensorDetailId === undefined) {
    return '未知传感器'
  }

  // 首先在props.sensorDetails中查找
  const sensor = props.sensorDetails?.find(s => s.sensor_detail_id === sensorDetailId)
  if (sensor) {
    return `${sensor.test_number} - ${sensor.probe_number}`
  }
  
  // 如果没找到，在availableSensorDetails中查找
  const availableSensor = availableSensorDetails.value?.find(s => s.sensor_detail_id === sensorDetailId)
  if (availableSensor) {
    return `${availableSensor.test_number} - ${availableSensor.probe_number}`
  }
  
  return '未知传感器'
}

const handleBatchChange = () => {
  formData.person_id = null
  formData.sensor_detail_ids = []
  formData.sensor_parameters = []
}

const handleSensorSelectionChange = () => {
  const currentIds = new Set(formData.sensor_parameters.map(p => p.sensor_detail_id))
  const selectedIds = new Set(formData.sensor_detail_ids)
  
  // 移除未选中的传感器参数
  formData.sensor_parameters = formData.sensor_parameters.filter(p => 
    selectedIds.has(p.sensor_detail_id)
  )
  
  // 添加新选中的传感器参数
  formData.sensor_detail_ids.forEach(id => {
    if (!currentIds.has(id)) {
      formData.sensor_parameters.push(createDefaultSensorParam(id))
    }
  })
}

const removeSensorParam = async (index: number) => {
  const param = formData.sensor_parameters[index];
  
  // 在编辑模式下，如果传感器参数有wear_record_id，需要调用父组件的删除方法
  if (props.isEdit && param.wear_record_id !== undefined && props.removeSensorFromEdit) {
    try {
      await props.removeSensorFromEdit(param.wear_record_id);
      // 成功删除后从前端数据中移除
      formData.sensor_parameters.splice(index, 1);
      formData.sensor_detail_ids = formData.sensor_detail_ids.filter((_, i) => i !== index);
      
      // 检查是否还有剩余传感器，如果没有则关闭对话框
      if (formData.sensor_parameters.length === 0) {
        handleClose();
      }
    } catch (error) {
      // 删除失败，不从前端移除
      return;
    }
  } else {
    // 新建模式或未保存的记录，直接从前端移除
    formData.sensor_parameters.splice(index, 1);
    formData.sensor_detail_ids = formData.sensor_detail_ids.filter((_, i) => i !== index);
    
    // 检查是否还有剩余传感器，如果没有则关闭对话框
    if (formData.sensor_parameters.length === 0) {
      handleClose();
    }
  }
}

const resetForm = () => {
  Object.assign(formData, {
    wear_record_id: undefined,
    batch_id: null,
    person_id: null,
    sensor_detail_ids: [],
    sensor_parameters: []
  })
  formRef.value?.clearValidate()
}

const handleClose = () => {
  emit('update:visible', false)
  emit('close')
}

const handleSubmit = async () => {
  try {
    await formRef.value?.validate()
    emit('submit', { ...formData })
  } catch (error) {
    ElMessage.error('请检查表单填写是否完整')
  }
}

// 监听编辑数据变化
watch(
  () => props.editData,
  (newData) => {
    if (newData && props.isEdit) {
      Object.assign(formData, {
        wear_record_id: newData.wear_record_id,
        batch_id: newData.batch_id,
        person_id: newData.person_id,
        sensor_detail_ids: newData.sensor_detail_ids || [],
        sensor_parameters: newData.sensor_parameters || []
      })
    }
  },
  { immediate: true }
)

// 监听对话框显示状态
watch(
  () => props.visible,
  (visible) => {
    if (!visible) {
      resetForm()
    }
  }
)
</script>

<style scoped lang="scss">
.wear-record-form {
  .form-section {
    margin-bottom: 20px;
    
    &:last-child {
      margin-bottom: 0;
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
  }
  
  .form-row {
    display: flex;
    gap: 16px;
    
    .form-item-half {
      flex: 1;
    }
  }
}

.sensor-params-section {
  margin-top: 16px;
  
  .params-header {
    font-weight: 600;
    color: #303133;
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 1px solid #f0f0f0;
  }
}

.sensor-params-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sensor-param-card {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  background-color: #fafafa;
  
  .param-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    
    .sensor-name {
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
      
      .el-textarea {
        width: 100%;
      }
      
      .el-textarea__inner {
        min-height: 80px;
        resize: vertical;
      }
    }
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
    width: 120px;
  }
  
  .el-form-item__content {
    font-size: 14px;
  }
}

:deep(.el-input__inner),
:deep(.el-select .el-input__inner),
:deep(.el-date-editor .el-input__inner) {
  font-size: 14px;
}

:deep(.el-button--small) {
  font-size: 12px;
}

// 只读字段样式
:deep(.readonly-field) {
  .el-input__wrapper {
    background-color: #f5f7fa;
    cursor: not-allowed;
    box-shadow: 0 0 0 1px #dcdfe6 inset;
  }
  
  .el-input__inner {
    background-color: transparent;
    color: #909399;
    cursor: not-allowed;
  }
  
  .el-input__wrapper:hover {
    box-shadow: 0 0 0 1px #dcdfe6 inset;
  }
  
  .el-input__wrapper.is-focus {
    box-shadow: 0 0 0 1px #dcdfe6 inset;
  }
}
</style>
