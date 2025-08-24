<template>
  <div class="sensor-management">
    <div class="page-header">
      <h2>传感器管理</h2>
      <p>管理实验中使用的各类传感器设备</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索传感器号/批号/发射器号"
          style="width: 250px; margin-right: 12px"
          clearable
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template> 
        </el-input>
        
        <el-select
          v-model="filterBatch"
          placeholder="筛选实验批次"
          clearable
          style="width: 150px; margin-right: 12px"
          @change="handleFilter"
        >
          <el-option
            v-for="batch in availableBatchesForFilter"
            :key="batch.batch_id"
            :label="batch.batch_number"
            :value="batch.batch_id.toString()"
          />
        </el-select>
        
        <el-select
          v-model="filterPerson"
          placeholder="筛选人员"
          clearable
          style="width: 150px; margin-right: 12px"
          @change="handleFilter"
        >
          <el-option
            v-for="person in filteredPersonsForFilter"
            :key="person.person_id"
            :label="person.person_name"
            :value="person.person_id.toString()"
          />
        </el-select>
        
        <el-select
          v-model="filterStatus"
          placeholder="筛选状态"
          clearable
          style="width: 120px"
          @change="handleFilter"
        >
          <el-option label="未开始" value="not_started" />
          <el-option label="进行中" value="running" />
          <el-option label="已结束" value="finished" />
        </el-select>
      </div>
      
      <div class="toolbar-right">
        <el-button 
          :disabled="!authStore.hasModulePermission('sensor_management', 'read')"
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('sensor_management', 'write')"
          type="primary" 
          @click="handleAdd"
        >
          <el-icon><Plus /></el-icon>
          添加传感器
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('sensor_management', 'write')"
          type="success" 
          @click="handleBatchAdd"
        >
          <el-icon><Plus /></el-icon>
          批量录入
        </el-button>
      </div>
    </div>
    
    <!-- 统计卡片 -->
    <div class="stats-cards">
      <el-card class="stat-card">
        <div class="stat-content">
          <div class="stat-number">{{ totalSensors }}</div>
          <div class="stat-label">传感器总数</div>
        </div>
        <div class="stat-icon total">
          <el-icon><Monitor /></el-icon>
        </div>
      </el-card>
      
      <el-card class="stat-card">
        <div class="stat-content">
          <div class="stat-number">{{ notStartedSensors }}</div>
          <div class="stat-label">未开始</div>
        </div>
        <div class="stat-icon not-started">
          <el-icon><Clock /></el-icon>
        </div>
      </el-card>
      
      <el-card class="stat-card">
        <div class="stat-content">
          <div class="stat-number">{{ runningSensors }}</div>
          <div class="stat-label">进行中</div>
        </div>
        <div class="stat-icon running">
          <el-icon><CircleCheck /></el-icon>
        </div>
      </el-card>
      
      <el-card class="stat-card">
        <div class="stat-content">
          <div class="stat-number">{{ finishedSensors }}</div>
          <div class="stat-label">已结束</div>
        </div>
        <div class="stat-icon finished">
          <el-icon><CircleClose /></el-icon>
        </div>
      </el-card>
    </div>
    
    <!-- 传感器列表 -->
    <el-card>
      <template #header>
        <div class="card-header">
          <span>传感器列表</span>
          <span class="data-count">共 {{ filteredSensors.length }} 个传感器</span>
        </div>
      </template>
      
      <el-table
        :data="paginatedSensors"
        stripe
        style="width: 100%"
        v-loading="loading"
      >
        <el-table-column prop="sensor_id" label="传感器ID" width="100" />
        <el-table-column prop="sensor_lot_no" label="传感器批号" width="140">
          <template #default="{ row }">
            <span>{{ row.sensor_lot_no || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="sensor_batch" label="传感器批次" width="140">
          <template #default="{ row }">
            <span>{{ row.sensor_batch || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="发射器号" width="120">
          <template #default="{ row }">
            <span class="transmitter-id">{{ row.transmitter_id || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="关联人员" width="150">
          <template #default="{ row }">
          <el-tag type="success">
            {{ getPersonName(row.person_id) }}
          </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="关联实验批次" width="150">
          <template #default="{ row }">
           <el-tag type="primary">
            {{ getBatchNumber(row.batch_id) }}
           </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="start_time" label="开始时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.start_time) }}
          </template>
        </el-table-column>
        <el-table-column prop="end_time" label="结束时间" width="180">
          <template #default="{ row }">
            {{ row.end_time ? formatDate(row.end_time) : getSensorStatus(row).label }}
          </template>
        </el-table-column>
        <el-table-column prop="end_reason" label="结束原因" width="150">
          <template #default="{ row }">
            <span v-if="row.end_reason" class="end-reason-text">{{ row.end_reason }}</span>
            <span v-else class="no-data">-</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getSensorStatus(row).type">{{ getSensorStatus(row).label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button
              :disabled="!authStore.hasModulePermission('sensor_management', 'write')"
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('sensor_management', 'delete')"
              type="danger"
              size="small"
              @click="handleDelete(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页组件 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="pageSizes"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
    
    <!-- 新建/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑传感器' : '添加传感器'"
      width="700px"
      @close="resetForm"
    >
      <div class="single-entry-container">
        <div class="section-header">
          <span>传感器信息</span>
        </div>
        
        <div class="single-entry-card">
          <el-form
            ref="formRef"
            :model="form"
            :rules="rules"
            label-width="120px"
            class="single-entry-form"
          >
        <!-- 优先选择实验批次和人员 -->
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="关联实验批次" prop="batch_id">
              <el-select
                v-model="form.batch_id"
                placeholder="请选择实验批次"
                style="width: 100%"
                filterable
                :disabled="isEdit"
              >
                <el-option
                  v-for="batch in batches"
                  :key="batch.batch_id"
                  :label="`${batch.batch_number} (ID: ${batch.batch_id})`"
                  :value="batch.batch_id"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="关联人员" prop="person_id">
              <el-select
                v-model="form.person_id"
                placeholder="请选择人员"
                style="width: 100%"
                filterable
                :disabled="isEdit || !form.batch_id"
              >
                <el-option
                  v-for="person in filteredPersonsForSensor"
                  :key="person.person_id"
                  :label="`${person.person_name} (ID: ${person.person_id})`"
                  :value="person.person_id"
                />
              </el-select>
              <div class="form-tip" v-if="!isEdit">
                {{ form.batch_id ? '显示该实验批次下的人员' : '请先选择实验批次' }}
              </div>
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="传感器批号" prop="sensor_lot_no">
              <el-input
                v-model="form.sensor_lot_no"
                placeholder="请输入传感器批号"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="传感器批次/号" prop="sensor_batch">
              <el-select
                v-model="form.sensor_batch"
                placeholder="请选择传感器批次/号"
                filterable
                style="width: 100%"
                @change="handleSensorBatchChange"
              >
                <el-option
                  v-for="detail in availableSensorDetails"
                  :key="detail.test_number"
                  :label="detail.test_number"
                  :value="detail.test_number"
                />
              </el-select>
              <div class="form-tip">
                从传感器详细信息中选择测试编号
              </div>
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="传感器号" prop="sensor_number">
              <el-input
                v-model="form.sensor_number"
                placeholder="传感器号将自动与批次保持一致"
                disabled
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="发射器号" prop="transmitter_id">
              <el-input
                v-model="form.transmitter_id"
                placeholder="请输入发射器号"
              />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="开始时间" prop="start_time">
              <el-date-picker
                v-model="form.start_time"
                type="date"
                placeholder="选择开始时间"
                style="width: 100%"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束时间">
              <el-date-picker
                v-model="form.end_time"
                type="date"
                placeholder="选择结束时间（可选）"
                style="width: 100%"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
              />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="20">
          <el-col :span="24">
            <el-form-item label="结束原因">
              <el-input
                v-model="form.end_reason"
                placeholder="请输入结束原因（可选）"
                maxlength="255"
                show-word-limit
              />
            </el-form-item>
          </el-col>
        </el-row>
          </el-form>
        </div>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 批量录入传感器对话框 -->
    <el-dialog
      v-model="batchDialogVisible"
      title="批量录入传感器"
      width="800px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="batchFormRef"
        :model="batchForm"
        :rules="batchRules"
        label-width="100px"
        label-position="left"
      >
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="选择实验批次" prop="batch_id">
              <el-select
                v-model="batchForm.batch_id"
                placeholder="请选择实验批次"
                style="width: 100%"
                clearable
              >
                <el-option
                  v-for="batch in batches"
                  :key="batch.batch_id"
                  :label="batch.batch_number"
                  :value="batch.batch_id"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="选择人员" prop="person_id">
              <el-select
                v-model="batchForm.person_id"
                placeholder="请选择人员"
                style="width: 100%"
                clearable
                :disabled="!batchForm.batch_id"
              >
                <el-option
                  v-for="person in filteredPersonsForBatchForm"
                  :key="person.person_id"
                  :label="`${person.person_name} (${person.gender === 'Male' ? '男' : person.gender === 'Female' ? '女' : '其他'}, ${person.age}岁)`"
                  :value="person.person_id"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <div class="sensor-section">
          <div class="section-header">
            <span>传感器数据</span>
            <el-button type="primary" size="small" @click="addSensorItem">
              <el-icon><Plus /></el-icon>
              添加传感器
            </el-button>
          </div>

          <div v-if="batchForm.sensorList.length === 0" class="empty-hint">
            暂无传感器数据，请点击"添加传感器"按钮添加
          </div>

          <div
            v-for="(sensor, index) in batchForm.sensorList"
            :key="index"
            class="sensor-item"
          >
            <div class="sensor-card">
              <div class="sensor-header">
                <span>传感器 {{ index + 1 }}</span>
                <el-button
                  type="danger"
                  size="small"
                  text
                  @click="removeSensorItem(index)"
                  :disabled="batchForm.sensorList.length <= 1"
                >
                  <el-icon><Delete /></el-icon>
                  删除
                </el-button>
              </div>
              <div class="sensor-form">
                <el-row :gutter="16">
                  <el-col :span="12">
                    <el-form-item
                      :prop="`sensorList.${index}.sensor_lot_no`"
                      label="传感器批号"
                    >
                      <el-input
                        v-model="sensor.sensor_lot_no"
                        placeholder="请输入传感器批号"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item
                      :prop="`sensorList.${index}.start_time`"
                      :rules="sensorRules.start_time"
                      label="开始时间"
                    >
                      <el-date-picker
                        v-model="sensor.start_time"
                        type="date"
                        placeholder="请选择开始时间"
                        style="width: 100%"
                        format="YYYY-MM-DD"
                        value-format="YYYY-MM-DD"
                      />
                    </el-form-item>
                  </el-col>
                </el-row>
                <el-row :gutter="16">
                  <el-col :span="12">
                    <el-form-item
                      :prop="`sensorList.${index}.sensor_batch`"
                      label="传感器批次/号"
                    >
                      <el-select
                        v-model="sensor.sensor_batch"
                        placeholder="请选择传感器批次/号"
                        filterable
                        style="width: 100%"
                        @change="(value) => handleBatchSensorChange(index, value)"
                      >
                        <el-option
                          v-for="detail in availableSensorDetails"
                          :key="detail.test_number"
                          :label="detail.test_number"
                          :value="detail.test_number"
                        />
                      </el-select>
                      <div class="form-tip">
                        从传感器详细信息中选择测试编号
                      </div>
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item
                      :prop="`sensorList.${index}.sensor_number`"
                      label="传感器号"
                    >
                      <el-input
                        v-model="sensor.sensor_number"
                        placeholder="传感器号将自动与批次保持一致"
                        disabled
                      />
                    </el-form-item>
                  </el-col>
                </el-row>
                <el-row :gutter="16">
                  <el-col :span="12">
                    <el-form-item
                      :prop="`sensorList.${index}.transmitter_id`"
                      label="发射器号"
                    >
                      <el-input
                        v-model="sensor.transmitter_id"
                        placeholder="请输入发射器号"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                  </el-col>
                </el-row>
                <el-row :gutter="16">
                  <el-col :span="12">
                    <el-form-item label="结束时间">
                      <el-date-picker
                        v-model="sensor.end_time"
                        type="date"
                        placeholder="请选择结束时间（选填）"
                        style="width: 100%"
                        format="YYYY-MM-DD"
                        value-format="YYYY-MM-DD"
                        clearable
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item label="结束原因">
                      <el-input
                        v-model="sensor.end_reason"
                        placeholder="请输入结束原因（选填）"
                      />
                    </el-form-item>
                  </el-col>
                </el-row>
              </div>
            </div>
          </div>
        </div>
      </el-form>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="batchDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleBatchSubmit">提交</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted, watch } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance } from 'element-plus'
import {
  Search,
  Download,
  Plus,
  Monitor,
  CircleCheck,
  CircleClose,
  Clock,
  Delete
} from '@element-plus/icons-vue'
import { useDataStore, type Sensor, type Person, type Batch } from '../stores/data'
import { ApiService, type SensorDetail } from '../services/api'
import { useAuthStore } from '../stores/auth'
import { usePagination } from '@/composables/usePagination'
import { formatDateTime, formatDate } from '@/utils/formatters'
import { exportToExcel } from '@/utils/excel'

const dataStore = useDataStore()
const authStore = useAuthStore()

// 人员、批次和传感器详细信息数据
const persons = ref<Person[]>([])
const batches = ref<Batch[]>([])
const sensorDetails = ref<SensorDetail[]>([])

// 本地格式化函数
const getPersonName = (personId: number): string => {
  const person = persons.value.find(p => p.person_id === personId)
  return person ? `${person.person_name} (ID: ${person.person_id})` : '未知人员'
}

const getBatchNumber = (batchId: number): string => {
  const batch = batches.value.find(b => b.batch_id === batchId)
  return batch?.batch_number || '未知批次'
}

// 根据传感器数据中实际存在的批次进行筛选
const availableBatchesForFilter = computed(() => {
  const batchIds = [...new Set(dataStore.sensors.map(sensor => sensor.batch_id))]
  return batches.value.filter(batch => batchIds.includes(batch.batch_id))
})

// 根据传感器数据中实际存在的人员进行筛选
const availablePersonsForFilter = computed(() => {
  const personIds = [...new Set(dataStore.sensors.map(sensor => sensor.person_id))]
  return persons.value.filter(person => personIds.includes(person.person_id))
})

// 页面可见性监听
const handleVisibilityChange = async () => {
  if (!document.hidden) {
    try {
      loading.value = true
      const [sensorsData, personsData, batchesData, sensorDetailsData] = await Promise.all([
        dataStore.loadSensors(),
        dataStore.loadPersons(),
        dataStore.loadBatches(),
        dataStore.loadSensorDetails()
      ])
      persons.value = personsData
      batches.value = batchesData
      sensorDetails.value = sensorDetailsData
    } catch (error) {
      console.error('Failed to load data:', error)
      ElMessage.error('加载数据失败')
    } finally {
      loading.value = false
    }
  }
}

// 组件挂载时获取最新数据
onMounted(async () => {
  try {
    loading.value = true
    
    // 强制清除所有相关缓存，确保获取最新数据
    dataStore.clearCache('sensors')
    dataStore.clearCache('persons')
    dataStore.clearCache('batches')
    dataStore.clearCache('sensorDetails')
    
    const [sensorsData, personsData, batchesData, sensorDetailsData] = await Promise.all([
      dataStore.loadSensors(),
      dataStore.loadPersons(),
      dataStore.loadBatches(),
      dataStore.loadSensorDetails()
    ])
    persons.value = personsData
    batches.value = batchesData
    sensorDetails.value = sensorDetailsData
  } catch (error) {
    console.error('Failed to load data:', error)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

// 组件卸载时清理监听器
onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const loading = ref(false)
const searchKeyword = ref('')
const filterBatch = ref('')
const filterPerson = ref('')
const filterStatus = ref('')
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()
const batchDialogVisible = ref(false)
const batchFormRef = ref<FormInstance>()

// 分页相关
const { currentPage, pageSize, pageSizes, handleSizeChange, handleCurrentChange, resetPagination } = usePagination()

const form = reactive({
  sensor_id: 0,
  sensor_lot_no: '',
  sensor_batch: '',
  sensor_number: '',
  transmitter_id: '',
  person_id: null,
  batch_id: null,
  start_time: '',
  end_time: '',
  end_reason: '',
  sensor_detail_id: null as number | null
})

// 批量录入表单数据
const batchForm = reactive({
  batch_id: null as number | null,
  person_id: null as number | null,
  sensorList: [
    {
      sensor_lot_no: '',
      sensor_batch: '',
      sensor_number: '',
      transmitter_id: '',
      start_time: '',
      end_time: '',
      end_reason: ''
    }
  ] as Array<{
    sensor_lot_no: string
    sensor_batch: string
    sensor_number: string
    transmitter_id: string
    start_time: string
    end_time: string
    end_reason: string
  }>
})

const rules = computed(() => {
  const baseRules = {
    start_time: [
      { required: true, message: '请选择开始时间', trigger: 'change' }
    ]
  }
  
  if (!isEdit.value) {
    return {
      ...baseRules,
      person_id: [
        { required: true, message: '请选择关联人员', trigger: 'change' }
      ],
      batch_id: [
        { required: true, message: '请选择关联实验批次', trigger: 'change' }
      ]
    }
  }
  
  return baseRules
})

// 批量录入表单验证规则
const batchRules = {
  batch_id: [
    { required: true, message: '请选择实验批次', trigger: 'change' }
  ],
  person_id: [
    { required: true, message: '请选择人员', trigger: 'change' }
  ]
}

// 传感器数据验证规则
const sensorRules = {
  start_time: [
    { required: true, message: '请选择开始时间', trigger: 'change' }
  ]
}

// 根据选择的批次过滤人员（传感器表单）
const filteredPersonsForSensor = computed(() => {
  if (isEdit.value) {
    if (form.person_id) {
      const currentPerson = persons.value.find(p => p.person_id === form.person_id)
      if (currentPerson) {
        const otherPersons = persons.value.filter(p => p.person_id !== form.person_id)
        return [currentPerson, ...otherPersons]
      }
    }
    return persons.value
  }
  if (!form.batch_id) {
    return []
  }
  return persons.value.filter(person => person.batch_id === form.batch_id)
})

// 根据选择的批次过滤人员（批量录入表单）
const filteredPersonsForBatchForm = computed(() => {
  if (!batchForm.batch_id) {
    return []
  }
  return persons.value.filter(person => person.batch_id === batchForm.batch_id)
})

// 根据选择的批次过滤人员（过滤区域）
const filteredPersonsForFilter = computed(() => {
  if (!filterBatch.value) {
    return availablePersonsForFilter.value
  }
  return availablePersonsForFilter.value.filter(person => person.batch_id.toString() === filterBatch.value)
})

// 过滤已使用的传感器详情
const availableSensorDetails = computed(() => {
  // 获取当前传感器列表中已使用的sensor_detail_id
  const usedSensorDetailIds = new Set(
    dataStore.sensors
      .map(sensor => sensor.sensor_detail_id)
      .filter(id => id !== null && id !== undefined)
  )
  
  // 返回未被使用的传感器详情
  return dataStore.sensorDetails.filter(detail => 
    !usedSensorDetailIds.has(detail.sensor_detail_id)
  )
})

// 处理传感器批次变更，同步更新传感器号和传感器详细信息ID
const handleSensorBatchChange = (value: string) => {
  // 传感器号与传感器批次保持一致
  form.sensor_number = value
  
  // 根据传感器批次查找对应的传感器详细信息ID
  if (value && availableSensorDetails.value.length > 0) {
    const matchingSensorDetail = availableSensorDetails.value.find(detail => 
      detail.test_number === value || detail.probe_number === value
    )
    if (matchingSensorDetail) {
      form.sensor_detail_id = matchingSensorDetail.sensor_detail_id
    } else {
      form.sensor_detail_id = null
    }
  } else {
    form.sensor_detail_id = null
  }
}

// 处理批量表单中传感器批次变更
const handleBatchSensorChange = (index: number, value: string) => {
  // 传感器号与传感器批次保持一致
  batchForm.sensorList[index].sensor_number = value
}

// 监听批次选择变化，清空人员选择（传感器表单）
watch(() => form.batch_id, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId && !isEdit.value) {
    form.person_id = null
  }
})

// 监听批量录入表单批次选择变化，清空人员选择
watch(() => batchForm.batch_id, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId) {
    batchForm.person_id = null
  }
})

// 监听过滤批次选择变化，清空人员过滤
watch(() => filterBatch.value, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId && newBatchId) {
    if (filterPerson.value) {
      const selectedPerson = availablePersonsForFilter.value.find(p => p.person_id.toString() === filterPerson.value)
      if (!selectedPerson || selectedPerson.batch_id.toString() !== newBatchId) {
        filterPerson.value = ''
      }
    }
  }
})

// 获取传感器状态
const getSensorStatus = (sensor: Sensor) => {
  const now = new Date()
  const startTime = new Date(sensor.start_time)
  const endTime = sensor.end_time ? new Date(sensor.end_time) : null
  
  if (endTime && now > endTime) {
    return { type: 'info', label: '已结束' }
  } else if (now >= startTime) {
    return { type: 'success', label: '进行中' }
  } else {
    return { type: 'warning', label: '未开始' }
  }
}

// 过滤后的传感器列表
const filteredSensors = computed(() => {
  let result = dataStore.sensors
  
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(sensor => 
      (sensor.sensor_number && sensor.sensor_number.toLowerCase().includes(keyword)) ||
      (sensor.sensor_lot_no && sensor.sensor_lot_no.toLowerCase().includes(keyword)) ||
      (sensor.transmitter_id && sensor.transmitter_id.toLowerCase().includes(keyword)) ||
      (sensor.sensor_batch && sensor.sensor_batch.toLowerCase().includes(keyword))
    )
  }
  
  if (filterBatch.value) {
    result = result.filter(sensor => sensor.batch_id.toString() === filterBatch.value)
  }
  
  if (filterPerson.value) {
    result = result.filter(sensor => sensor.person_id.toString() === filterPerson.value)
  }
  
  if (filterStatus.value) {
    const now = new Date()
    if (filterStatus.value === 'not_started') {
      result = result.filter(sensor => {
        const startTime = new Date(sensor.start_time)
        return now < startTime
      })
    } else if (filterStatus.value === 'running') {
      result = result.filter(sensor => {
        const startTime = new Date(sensor.start_time)
        const endTime = sensor.end_time ? new Date(sensor.end_time) : null
        return now >= startTime && (!endTime || now <= endTime)
      })
    } else if (filterStatus.value === 'finished') {
      result = result.filter(sensor => {
        const endTime = sensor.end_time ? new Date(sensor.end_time) : null
        return endTime && now > endTime
      })
    }
  }
  
  return result.sort((a, b) => b.sensor_id - a.sensor_id)
})

// 当前页数据
const paginatedSensors = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredSensors.value.slice(start, end)
})

// 总数据量
const total = computed(() => filteredSensors.value.length)

// 统计数据
const totalSensors = computed(() => dataStore.sensors.length)
const notStartedSensors = computed(() => {
  const now = new Date()
  return dataStore.sensors.filter(sensor => {
    const startTime = new Date(sensor.start_time)
    return now < startTime
  }).length
})
const runningSensors = computed(() => {
  const now = new Date()
  return dataStore.sensors.filter(sensor => {
    const startTime = new Date(sensor.start_time)
    const endTime = sensor.end_time ? new Date(sensor.end_time) : null
    return now >= startTime && (!endTime || now <= endTime)
  }).length
})
const finishedSensors = computed(() => {
  const now = new Date()
  return dataStore.sensors.filter(sensor => {
    const endTime = sensor.end_time ? new Date(sensor.end_time) : null
    return endTime && now > endTime
  }).length
})

// 搜索处理
const handleSearch = () => {
  resetPagination()
}

// 筛选处理
const handleFilter = () => {
  resetPagination()
}

// 导出数据
const handleExport = () => {
  try {
    const exportData = filteredSensors.value.map(sensor => ({
      '传感器ID': sensor.sensor_id,
      '传感器批号': sensor.sensor_lot_no || '-',
      '传感器批次': sensor.sensor_batch || '-',
      '传感器号': sensor.sensor_number || '-',
      '发射器号': sensor.transmitter_id || '-',
      '关联人员': getPersonName(sensor.person_id),
      '关联实验批次': getBatchNumber(sensor.batch_id),
      '开始时间': formatDateTime(sensor.start_time),
      '结束时间': formatDateTime(sensor.end_time),
      '结束原因': sensor.end_reason || '-',
      '状态': getSensorStatus(sensor).label
    }))
    
    let filename = '传感器数据'
    
    if (filterBatch.value || filterPerson.value) {
      const filters = []
      if (filterBatch.value) {
        const batchNumber = getBatchNumber(parseInt(filterBatch.value))
        filters.push(`批次${batchNumber}`)
      }
      if (filterPerson.value) {
        const personName = getPersonName(parseInt(filterPerson.value)).split(' ')[0]
        filters.push(`人员${personName}`)
      }
      filename = `传感器数据_${filters.join('_')}`
    }
    
    exportToExcel(exportData, filename, {
      '传感器ID': 12,
      '传感器批号': 15,
      '传感器批次': 15,
      '传感器号': 15,
      '发射器号': 15,
      '关联人员': 20,
      '关联实验批次': 15,
      '开始时间': 20,
      '结束时间': 20,
      '结束原因': 25,
      '状态': 10
    })
    
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('Export failed:', error)
    ElMessage.error('导出失败，请重试')
  }
}

// 新建传感器
const handleAdd = () => {
  isEdit.value = false
  dialogVisible.value = true
  resetForm()
}

// 批量录入传感器
const handleBatchAdd = () => {
  batchDialogVisible.value = true
  resetBatchForm()
}

// 添加传感器项
const addSensorItem = () => {
  batchForm.sensorList.push({
    sensor_lot_no: '',
    sensor_batch: '',
    sensor_number: '',
    transmitter_id: '',
    start_time: '',
    end_time: '',
    end_reason: ''
  })
}

// 删除传感器项
const removeSensorItem = (index: number) => {
  if (batchForm.sensorList.length > 1) {
    batchForm.sensorList.splice(index, 1)
  }
}

// 重置批量录入表单
const resetBatchForm = () => {
  if (batchFormRef.value) {
    batchFormRef.value.resetFields()
  }
  Object.assign(batchForm, {
    batch_id: null,
    person_id: null,
    sensorList: [
      {
        sensor_lot_no: '',
        sensor_batch: '',
        sensor_number: '',
        transmitter_id: '',
        start_time: '',
        end_time: '',
        end_reason: ''
      }
    ]
  })
}

// 编辑传感器
const handleEdit = (row: Sensor) => {
  isEdit.value = true
  dialogVisible.value = true
  Object.assign(form, {
    sensor_id: row.sensor_id,
    sensor_lot_no: row.sensor_lot_no || '',
    sensor_batch: row.sensor_batch || '',
    sensor_number: row.sensor_number || '',
    transmitter_id: row.transmitter_id || '',
    person_id: row.person_id,
    batch_id: row.batch_id,
    start_time: row.start_time,
    end_time: row.end_time || '',
    end_reason: row.end_reason || ''
  })
}

// 删除传感器
const handleDelete = async (row: Sensor) => {
  try {
    const sensorName = row.sensor_number || row.sensor_lot_no || `传感器${row.sensor_id}`
    await ElMessageBox.confirm(
      `确定要删除传感器 "${sensorName}" 吗？`,
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await dataStore.deleteSensor(row.sensor_id)
    ElMessage.success('删除成功')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Delete failed:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (isEdit.value) {
          await dataStore.updateSensor(form.sensor_id, {
            sensor_lot_no: form.sensor_lot_no || null,
            sensor_batch: form.sensor_batch || null,
            sensor_number: form.sensor_number || null,
            transmitter_id: form.transmitter_id || null,
            person_id: form.person_id,
            batch_id: form.batch_id,
            start_time: form.start_time,
            end_time: form.end_time || null,
            end_reason: form.end_reason || null,
            sensor_detail_id: form.sensor_detail_id || null
          })
          ElMessage.success('更新成功')
        } else {
          await dataStore.addSensor({
            sensor_lot_no: form.sensor_lot_no || null,
            sensor_batch: form.sensor_batch || null,
            sensor_number: form.sensor_number || null,
            transmitter_id: form.transmitter_id || null,
            person_id: form.person_id,
            batch_id: form.batch_id,
            start_time: form.start_time,
            end_time: form.end_time || null,
            end_reason: form.end_reason || null,
            sensor_detail_id: form.sensor_detail_id || null
          })
          ElMessage.success('添加成功')
        }
        
        dataStore.clearCache('sensors')
        dialogVisible.value = false
        resetForm()
      } catch (error) {
        console.error('Submit failed:', error)
        ElMessage.error(isEdit.value ? '更新失败' : '添加失败')
      }
    }
  })
}

// 批量提交传感器
const handleBatchSubmit = async () => {
  if (!batchFormRef.value) return
  
  await batchFormRef.value.validate(async (valid) => {
    if (valid) {
      try {
        let successCount = 0
        let failCount = 0
        
        for (let i = 0; i < batchForm.sensorList.length; i++) {
          const sensor = batchForm.sensorList[i]
          if (!sensor.start_time) {
            ElMessage.error(`第${i + 1}个传感器开始时间不能为空`)
            return
          }
        }
        
        for (const sensor of batchForm.sensorList) {
          try {
            // 根据sensor_batch查找对应的sensor_detail_id
            let sensorDetailId = null
            if (sensor.sensor_batch) {
              const matchingSensorDetail = dataStore.sensorDetails.find(
                detail => detail.test_number === sensor.sensor_batch
              )
              if (matchingSensorDetail) {
                sensorDetailId = matchingSensorDetail.sensor_detail_id
              }
            }
            
            await dataStore.addSensor({
              sensor_lot_no: sensor.sensor_lot_no || null,
              sensor_batch: sensor.sensor_batch || null,
              sensor_number: sensor.sensor_number || null,
              transmitter_id: sensor.transmitter_id || null,
              person_id: batchForm.person_id!,
              batch_id: batchForm.batch_id!,
              start_time: sensor.start_time,
              end_time: sensor.end_time || null,
              end_reason: sensor.end_reason || null,
              sensor_detail_id: sensorDetailId
            })
            successCount++
          } catch (error) {
            console.error('Add sensor failed:', error)
            failCount++
          }
        }
        
        if (successCount > 0) {
          ElMessage.success(`成功添加 ${successCount} 个传感器${failCount > 0 ? `，失败 ${failCount} 个` : ''}`)
        }
        if (failCount > 0 && successCount === 0) {
          ElMessage.error('批量添加失败')
        }
        
        if (successCount > 0) {
          dataStore.clearCache('sensors')
          batchDialogVisible.value = false
          resetBatchForm()
        }
      } catch (error) {
        console.error('Batch submit failed:', error)
        ElMessage.error('批量添加失败')
      }
    }
  })
}

// 重置表单
const resetForm = () => {
  if (formRef.value) {
    formRef.value.resetFields()
  }
  Object.assign(form, {
    sensor_id: 0,
    sensor_lot_no: '',
    sensor_batch: '',
    sensor_number: '',
    transmitter_id: '',
    person_id: null,
    batch_id: null,
    start_time: '',
    end_time: '',
    end_reason: '',
    sensor_detail_id: null
  })
}
</script>

<style scoped>
.sensor-management {
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
  flex-wrap: wrap;
  gap: 12px;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.stat-card {
  border-radius: 8px;
  overflow: hidden;
}

.stat-card :deep(.el-card__body) {
  padding: 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.stat-content {
  flex: 1;
}

.stat-number {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: white;
}

.stat-icon.total {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.running {
  background: linear-gradient(135deg, #67C23A 0%, #85ce61 100%);
}

.stat-icon.not-started {
  background: linear-gradient(135deg, #E6A23C 0%, #eebe77 100%);
}

.stat-icon.finished {
  background: linear-gradient(135deg, #F56C6C 0%, #f89898 100%);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.data-count {
  font-size: 14px;
  color: #909399;
  font-weight: normal;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
  padding: 20px 0;
}

.end-reason-text {
  color: #606266;
  font-size: 13px;
}

.no-data {
  color: #C0C4CC;
  font-style: italic;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.form-tip {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  padding: 8px 12px;
  background: #F0F9FF;
  border: 1px solid #BAE6FD;
  border-radius: 6px;
  color: #0369A1;
  font-size: 12px;
}

/* 单次录入样式 */
.single-entry-container {
  margin-top: 8px;
}

.single-entry-card {
  border: 1px solid #EBEEF5;
  border-radius: 8px;
  padding: 16px;
  background: #FAFAFA;
}

.single-entry-form {
  background: white;
  padding: 16px;
  border-radius: 6px;
}

/* 批量录入样式 */
.sensor-section {
  margin-top: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-weight: 600;
  color: #303133;
}

.empty-hint {
  text-align: center;
  color: #909399;
  padding: 40px 0;
  font-style: italic;
}

.sensor-item {
  margin-bottom: 16px;
}

.sensor-card {
  border: 1px solid #EBEEF5;
  border-radius: 8px;
  padding: 16px;
  background: #FAFAFA;
}

.sensor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-weight: 600;
  color: #303133;
}

.sensor-form {
  background: white;
  padding: 16px;
  border-radius: 6px;
}

:deep(.el-table) {
  font-size: 14px;
}

:deep(.el-table th) {
  background-color: #fafafa;
  color: #606266;
  font-weight: 600;
}

@media (max-width: 768px) {
  .toolbar {
    flex-direction: column;
    align-items: stretch;
  }
  
  .toolbar-left {
    justify-content: center;
  }
  
  .toolbar-right {
    justify-content: center;
  }
  
  .stats-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 480px) {
  .stats-cards {
    grid-template-columns: 1fr;
  }
}
</style>
