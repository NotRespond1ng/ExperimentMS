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
          style="width: 250px;"
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
          style="width: 150px;"
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
          style="width: 150px;"
          @change="handleFilter"
        >
          <el-option
            v-for="person in getFilteredPersons('filter')"
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
          <div class="stat-number">{{ sensorStatusCounts.notStarted }}</div>
          <div class="stat-label">未开始</div>
        </div>
        <div class="stat-icon not-started">
          <el-icon><Clock /></el-icon>
        </div>
      </el-card>
      
      <el-card class="stat-card">
        <div class="stat-content">
          <div class="stat-number">{{ sensorStatusCounts.running }}</div>
          <div class="stat-label">进行中</div>
        </div>
        <div class="stat-icon running">
          <el-icon><CircleCheck /></el-icon>
        </div>
      </el-card>
      
      <el-card class="stat-card">
        <div class="stat-content">
          <div class="stat-number">{{ sensorStatusCounts.finished }}</div>
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
        <el-table-column label="序号" width="80" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <!-- 隐藏原始sensor_id列，但保留数据用于后端传递 -->
        <!-- <el-table-column prop="sensor_id" label="传感器ID" width="100" /> -->
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
              :disabled="!authStore.hasModulePermission('sensor_data', 'write')"
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('sensor_data', 'delete')"
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
      width="900px"
      @close="resetForm"
    >
      <div class="form-container">
        <div class="section-header">
          <span>传感器信息</span>
        </div>
        
        <div class="form-content-wrapper">
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
                      v-for="person in getFilteredPersons('form')"
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
                    :locale="zhCn"
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
                    :locale="zhCn"
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
      width="1000px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="batchFormRef"
        :model="batchForm"
        :rules="batchRules"
        label-width="100px"
        label-position="top"
      >
        <el-row :gutter="20" class="batch-form-header">
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
                  v-for="person in getFilteredPersons('batch')"
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
            <div class="form-container">
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
              <div class="form-content-wrapper">
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
                        :locale="zhCn"
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
                        :locale="zhCn"
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
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

const dataStore = useDataStore()
const authStore = useAuthStore()

// 数据引用
const persons = ref<Person[]>([])
const batches = ref<Batch[]>([])
const sensorDetails = ref<SensorDetail[]>([])
const loading = ref(false)

// -- 优化：将数据加载逻辑提取到单独的函数中 --
const loadAllData = async (forceRefresh = false) => {
  try {
    loading.value = true
    if (forceRefresh) {
      dataStore.clearCache('sensors')
      dataStore.clearCache('persons')
      dataStore.clearCache('batches')
      dataStore.clearCache('sensorDetails')
    }
    const [personsData, batchesData, sensorDetailsData] = await Promise.all([
      dataStore.loadPersons(),
      dataStore.loadBatches(),
      dataStore.loadSensorDetails(),
      dataStore.loadSensors() // 确保传感器数据也被加载
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


const getPersonName = (personId: number): string => {
  const person = persons.value.find(p => p.person_id === personId)
  return person ? `${person.person_name} (ID: ${person.person_id})` : '未知人员'
}

const getBatchNumber = (batchId: number): string => {
  const batch = batches.value.find(b => b.batch_id === batchId)
  return batch?.batch_number || '未知批次'
}

// 页面可见性监听
const handleVisibilityChange = () => {
  if (!document.hidden) {
    loadAllData(true); // 当页面重新可见时，强制刷新数据
  }
}

onMounted(() => {
  loadAllData(true);
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const searchKeyword = ref('')
const filterBatch = ref('')
const filterPerson = ref('')
const filterStatus = ref('')
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()
const batchDialogVisible = ref(false)
const batchFormRef = ref<FormInstance>()

// 分页
const { currentPage, pageSize, pageSizes, handleSizeChange, handleCurrentChange, resetPagination } = usePagination()

// 表单数据
const form = reactive({
  sensor_id: 0,
  sensor_lot_no: '',
  sensor_batch: '',
  sensor_number: '',
  transmitter_id: '',
  person_id: null as number | null,
  batch_id: null as number | null,
  start_time: '',
  end_time: '',
  end_reason: '',
  sensor_detail_id: null as number | null
})

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
  ]
})

// 表单验证规则
const rules = computed(() => ({
  start_time: [{ required: true, message: '请选择开始时间', trigger: 'change' }],
  person_id: [{ required: !isEdit.value, message: '请选择关联人员', trigger: 'change' }],
  batch_id: [{ required: !isEdit.value, message: '请选择关联实验批次', trigger: 'change' }]
}))

const batchRules = {
  batch_id: [{ required: true, message: '请选择实验批次', trigger: 'change' }],
  person_id: [{ required: true, message: '请选择人员', trigger: 'change' }]
}

const sensorRules = {
  start_time: [{ required: true, message: '请选择开始时间', trigger: 'change' }]
}

// -- 优化：合并人员筛选逻辑 --
const getFilteredPersons = (type: 'form' | 'batch' | 'filter') => {
  let batchId: number | null | string = null;
  let sourcePersons: Person[] = persons.value;

  if (type === 'form') {
    batchId = form.batch_id;
  } else if (type === 'batch') {
    batchId = batchForm.batch_id;
  } else if (type === 'filter') {
    batchId = filterBatch.value;
    // 对于筛选器，源数据是已经关联了传感器的人员
    const personIds = [...new Set(dataStore.sensors.map(sensor => sensor.person_id))];
    sourcePersons = persons.value.filter(person => personIds.includes(person.person_id));
  }
  
  if (isEdit.value && type === 'form' && form.person_id) {
    const currentPerson = persons.value.find(p => p.person_id === form.person_id);
    if (currentPerson) return [currentPerson, ...persons.value.filter(p => p.person_id !== form.person_id)];
    return persons.value;
  }
  
  if (!batchId) {
    return type === 'filter' ? sourcePersons : [];
  }

  return sourcePersons.filter(person => person.batch_id?.toString() === batchId?.toString());
}


// 根据传感器数据中实际存在的批次进行筛选
const availableBatchesForFilter = computed(() => {
  const batchIds = [...new Set(dataStore.sensors.map(sensor => sensor.batch_id))]
  return batches.value.filter(batch => batchIds.includes(batch.batch_id))
})

// 过滤已使用的传感器详情
const availableSensorDetails = computed(() => {
  const usedSensorDetailIds = new Set(
    dataStore.sensors
      .map(sensor => sensor.sensor_detail_id)
      .filter(id => id != null)
  )
  return dataStore.sensorDetails.filter(detail => !usedSensorDetailIds.has(detail.sensor_detail_id))
})

// 处理传感器批次变更
const handleSensorBatchChange = (value: string) => {
  form.sensor_number = value
  const matchingSensorDetail = availableSensorDetails.value.find(detail => detail.test_number === value)
  form.sensor_detail_id = matchingSensorDetail?.sensor_detail_id || null
}

const handleBatchSensorChange = (index: number, value: string) => {
  batchForm.sensorList[index].sensor_number = value
}

// 监听器
watch(() => form.batch_id, (newVal, oldVal) => {
  if (newVal !== oldVal && !isEdit.value) form.person_id = null
})
watch(() => batchForm.batch_id, (newVal, oldVal) => {
  if (newVal !== oldVal) batchForm.person_id = null
})
watch(() => filterBatch.value, () => {
  filterPerson.value = ''
})

// 获取传感器状态
const getSensorStatus = (sensor: Sensor) => {
  const now = new Date()
  const startTime = new Date(sensor.start_time)
  const endTime = sensor.end_time ? new Date(sensor.end_time) : null
  
  if (endTime && now > endTime) return { type: 'info', label: '已结束' }
  if (now >= startTime) return { type: 'success', label: '进行中' }
  return { type: 'warning', label: '未开始' }
}

// 过滤后的传感器列表
const filteredSensors = computed(() => {
  return dataStore.sensors.filter(sensor => {
    const keyword = searchKeyword.value.toLowerCase()
    const statusResult = getSensorStatus(sensor).label;
    
    const matchesKeyword = !searchKeyword.value || 
      (sensor.sensor_number?.toLowerCase().includes(keyword)) ||
      (sensor.sensor_lot_no?.toLowerCase().includes(keyword)) ||
      (sensor.transmitter_id?.toLowerCase().includes(keyword)) ||
      (sensor.sensor_batch?.toLowerCase().includes(keyword));

    const matchesBatch = !filterBatch.value || sensor.batch_id.toString() === filterBatch.value;
    const matchesPerson = !filterPerson.value || sensor.person_id.toString() === filterPerson.value;
    const matchesStatus = !filterStatus.value ||
      (filterStatus.value === 'not_started' && statusResult === '未开始') ||
      (filterStatus.value === 'running' && statusResult === '进行中') ||
      (filterStatus.value === 'finished' && statusResult === '已结束');
      
    return matchesKeyword && matchesBatch && matchesPerson && matchesStatus;
  }).sort((a, b) => b.sensor_id - a.sensor_id);
})

// 分页数据
const paginatedSensors = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredSensors.value.slice(start, end)
})
const total = computed(() => filteredSensors.value.length)

// 统计数据
const totalSensors = computed(() => dataStore.sensors.length)
// -- 优化：一次遍历计算所有状态的数量 --
const sensorStatusCounts = computed(() => {
  return dataStore.sensors.reduce((counts, sensor) => {
    const status = getSensorStatus(sensor).label;
    if (status === '未开始') counts.notStarted++;
    else if (status === '进行中') counts.running++;
    else if (status === '已结束') counts.finished++;
    return counts;
  }, { notStarted: 0, running: 0, finished: 0 });
});


// 事件处理
const handleSearch = () => resetPagination()
const handleFilter = () => resetPagination()

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
      '结束时间': sensor.end_time ? formatDateTime(sensor.end_time) : '-',
      '结束原因': sensor.end_reason || '-',
      '状态': getSensorStatus(sensor).label
    }))
    
    const filename = `传感器数据_${new Date().toLocaleDateString()}`;
    exportToExcel(exportData, filename);
    ElMessage.success('导出成功');
  } catch (error) {
    console.error('Export failed:', error);
    ElMessage.error('导出失败');
  }
}

const handleAdd = () => {
  isEdit.value = false
  dialogVisible.value = true
  resetForm()
}

const handleBatchAdd = () => {
  batchDialogVisible.value = true
  resetBatchForm()
}

const addSensorItem = () => {
  batchForm.sensorList.push({ sensor_lot_no: '', sensor_batch: '', sensor_number: '', transmitter_id: '', start_time: '', end_time: '', end_reason: '' })
}

const removeSensorItem = (index: number) => {
  if (batchForm.sensorList.length > 1) {
    batchForm.sensorList.splice(index, 1)
  }
}

const resetBatchForm = () => {
  batchFormRef.value?.resetFields()
  Object.assign(batchForm, {
    batch_id: null,
    person_id: null,
    sensorList: [{ sensor_lot_no: '', sensor_batch: '', sensor_number: '', transmitter_id: '', start_time: '', end_time: '', end_reason: '' }]
  })
}

const handleEdit = (row: Sensor) => {
  isEdit.value = true
  dialogVisible.value = true
  Object.assign(form, row, {
      end_time: row.end_time || '',
      end_reason: row.end_reason || ''
  })
}

const handleDelete = async (row: Sensor) => {
  try {
    const sensorName = row.sensor_number || row.sensor_lot_no || `传感器${row.sensor_id}`
    await ElMessageBox.confirm(`确定要删除传感器 "${sensorName}" 吗？`, '删除确认', { type: 'warning' })
    await dataStore.deleteSensor(row.sensor_id)
    ElMessage.success('删除成功')
  } catch (error) {
    if (error !== 'cancel') {
      // 检查是否是HTTP错误响应
      if (error && typeof error === 'object' && 'response' in error) {
        const errorResponse = error as any
        const errorMessage = errorResponse.response?.data?.detail || '删除失败'
        ElMessage.error(errorMessage)
      } else {
        ElMessage.error('删除失败')
      }
    }
  }
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        const payload = {
          ...form,
          sensor_lot_no: form.sensor_lot_no || null,
          sensor_batch: form.sensor_batch || null,
          sensor_number: form.sensor_number || null,
          transmitter_id: form.transmitter_id || null,
          end_time: form.end_time || null,
          end_reason: form.end_reason || null,
          sensor_detail_id: form.sensor_detail_id || null
        }
        if (isEdit.value) {
          await dataStore.updateSensor(form.sensor_id, payload)
          ElMessage.success('更新成功')
        } else {
          await dataStore.addSensor(payload)
          ElMessage.success('添加成功')
        }
        dialogVisible.value = false
      } catch (error) {
        ElMessage.error(isEdit.value ? '更新失败' : '添加失败')
      }
    }
  })
}

const handleBatchSubmit = async () => {
  if (!batchFormRef.value) return
  await batchFormRef.value.validate(async (valid) => {
    if (valid) {
      if(batchForm.sensorList.some(s => !s.start_time)) {
          ElMessage.error('所有传感器都必须填写开始时间');
          return;
      }
      try {
        const promises = batchForm.sensorList.map(sensor => {
            const matchingDetail = dataStore.sensorDetails.find(d => d.test_number === sensor.sensor_batch);
            return dataStore.addSensor({
                ...sensor,
                person_id: batchForm.person_id!,
                batch_id: batchForm.batch_id!,
                sensor_detail_id: matchingDetail?.sensor_detail_id || null,
                sensor_lot_no: sensor.sensor_lot_no || null,
                sensor_batch: sensor.sensor_batch || null,
                sensor_number: sensor.sensor_number || null,
                transmitter_id: sensor.transmitter_id || null,
                end_time: sensor.end_time || null,
                end_reason: sensor.end_reason || null,
            });
        });
        await Promise.all(promises);
        ElMessage.success(`成功批量添加 ${promises.length} 个传感器`);
        batchDialogVisible.value = false
      } catch (error) {
        ElMessage.error('批量添加失败')
      }
    }
  })
}

const resetForm = () => {
  formRef.value?.resetFields()
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
  padding: 24px;
  background-color: #f7f8fa;
  min-height: 100vh;
}

.page-header {
  margin-bottom: 24px;
}

.page-header h2 {
  margin: 0 0 8px 0;
  color: #1d2129;
  font-size: 26px;
  font-weight: 600;
}

.page-header p {
  margin: 0;
  color: #86909c;
  font-size: 14px;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding: 16px 20px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  flex-wrap: wrap;
  gap: 12px;
}

.toolbar-left,
.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.stat-card {
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.stat-card :deep(.el-card__body) {
  padding: 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.stat-content { flex: 1; }
.stat-number { font-size: 28px; font-weight: 700; color: #303133; margin-bottom: 4px; }
.stat-label { font-size: 14px; color: #909399; }
.stat-icon { width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 24px; color: white; }
.stat-icon.total { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
.stat-icon.running { background: linear-gradient(135deg, #67C23A 0%, #85ce61 100%); }
.stat-icon.not-started { background: linear-gradient(135deg, #E6A23C 0%, #eebe77 100%); }
.stat-icon.finished { background: linear-gradient(135deg, #F56C6C 0%, #f89898 100%); }

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: 500;
  color: #1d2129;
}

.data-count {
  font-size: 14px;
  color: #86909c;
  font-weight: normal;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 24px;
}

.end-reason-text { color: #606266; font-size: 13px; }
.no-data { color: #C0C4CC; font-style: italic; }
.dialog-footer { display: flex; justify-content: flex-end; gap: 12px; }

.form-tip {
  margin-top: 4px;
  color: #909399;
  font-size: 12px;
  line-height: 1.5;
}

/* -- 优化：统一表单容器样式 -- */
.form-container {
  border: 1px solid #e5e6eb;
  border-radius: 8px;
  padding: 20px;
  background: #fafafa;
}

.form-content-wrapper {
  background: white;
  padding: 24px 16px 8px 16px;
  border-radius: 6px;
}

.sensor-section { margin-top: 20px; }

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

.sensor-item { margin-bottom: 16px; }

.sensor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-weight: 600;
  color: #303133;
}

.batch-form-header {
  padding: 10px 20px;
  background-color: #f7f8fa;
  border-radius: 8px;
  margin-bottom: 20px;
}

:deep(.el-dialog__header) {
  padding: 20px 24px;
  margin-right: 0;
  border-bottom: 1px solid #e5e6eb;
}

:deep(.el-dialog__title) {
  font-size: 20px;
  font-weight: 600;
  color: #1d2129;
}

:deep(.el-dialog__body) {
  padding: 20px 24px;
}

:deep(.el-form-item) {
  margin-bottom: 20px;
  /* -- 优化：使用Flex进行对齐 -- */
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

:deep(.el-form-item__label) {
  font-size: 14px !important;
  color: #4e5969 !important;
  margin-bottom: 8px !important;
  line-height: 1.5 !important;
  justify-content: flex-start;
}
:deep(.el-form-item__content) {
  width: 100%;
}


:deep(.el-input__inner),
:deep(.el-input-number) {
  font-size: 14px;
  height: 36px;
}

:deep(.el-button) { font-size: 14px; }
:deep(.el-table) { font-size: 14px; }
:deep(.el-table th) { background-color: #f2f3f5 !important; font-weight: 500; color: #4e5969; }
:deep(.el-tag) { font-size: 13px; padding: 0 10px; height: 28px; line-height: 26px; }

@media (max-width: 768px) {
  .toolbar { flex-direction: column; align-items: stretch; }
  .toolbar-left, .toolbar-right { justify-content: center; }
  .stats-cards { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 480px) {
  .stats-cards { grid-template-columns: 1fr; }
}
</style>
