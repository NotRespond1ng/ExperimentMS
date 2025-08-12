<template>
  <div class="wear-record-management">
    <div class="page-header">
      <h2>佩戴记录管理</h2>
      <p>管理人员传感器佩戴记录信息</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索人员姓名"
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
          placeholder="筛选批次"
          clearable
          style="width: 150px; margin-right: 12px"
          @change="handleFilter"
        >
          <el-option
            v-for="batch in availableBatches"
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
            v-for="person in availablePersons"
            :key="person.person_id"
            :label="person.person_name"
            :value="person.person_id.toString()"
          />
        </el-select>
      </div>
      
      <div class="toolbar-right">
        <el-button 
          :disabled="!authStore.hasModulePermission('wear_records', 'read')"
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('wear_records', 'write')"
          type="success" 
          @click="handleBatchAdd"
        >
          <el-icon><Upload /></el-icon>
          批量添加
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('wear_records', 'write')"
          type="primary" 
          @click="handleAdd"
        >
          <el-icon><Plus /></el-icon>
          添加佩戴记录
        </el-button>
      </div>
    </div>
    
    
    <!-- 佩戴记录列表 -->
    <el-card>
      <template #header>
        <div class="card-header">
          <span>佩戴记录列表</span>
          <span class="data-count">共 {{ groupedWearRecords.length }} 人员，{{ filteredWearRecords.length }} 条记录</span>
        </div>
      </template>
      
      <el-table
        :data="paginatedPersonRecords"
        stripe
        style="width: 100%"
        v-loading="loading"
      >
        <el-table-column label="人员信息" width="180">
          <template #default="{ row }">
            <div class="person-info">
              <div class="person-avatar">
                {{ row.person_name.charAt(0) }}
              </div>
              <div class="person-details">
                <div class="person-name">{{ row.person_name }}</div>
                <div class="person-id">ID: {{ row.person_id }}</div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="批次" width="120">
          <template #default="{ row }">
            <el-tag type="primary" size="small">
              {{ row.batch_number }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="传感器信息" min-width="800">
          <template #default="{ row }">
            <div class="sensors-cell">
              <div v-if="row.sensors && row.sensors.length > 0" class="sensors-group">
                <div class="sensors-header">
                  <el-icon class="group-icon"><Monitor /></el-icon>
                  <span class="sensor-count">{{ row.sensors.length }}个传感器</span>
                </div>
                <div class="sensors-table">
                  <div class="sensors-table-header">
                    <div class="sensor-col sensor-col-name">传感器</div>
                    <div class="sensor-col sensor-col-field">敷贴器批号</div>
                    <div class="sensor-col sensor-col-field">传感器批号</div>
                    <div class="sensor-col sensor-col-field">传感器批次</div>
                    <div class="sensor-col sensor-col-field">传感器号</div>
                    <div class="sensor-col sensor-col-field">发射器号</div>
                    <div class="sensor-col sensor-col-time">佩戴时间</div>
                  </div>
                  <div 
                    v-for="(sensor, index) in row.sensors" 
                    :key="sensor.wear_record_id"
                    class="sensors-table-row"
                  >
                    <div class="sensor-col sensor-col-name">
                      <div class="sensor-item-compact">
                        <div class="sensor-avatar">
                          {{ sensor.sensor_detail?.test_number?.charAt(0) || 'S' }}
                        </div>
                        <div class="sensor-info-compact">
                          <div class="sensor-test">{{ sensor.sensor_detail?.test_number || '未知' }}</div>
                          <div class="sensor-probe">{{ sensor.sensor_detail?.probe_number || '未知' }}</div>
                        </div>
                      </div>
                    </div>
                    <div class="sensor-col sensor-col-field">
                      <span class="field-value">{{ sensor.applicator_lot_no || '-' }}</span>
                    </div>
                    <div class="sensor-col sensor-col-field">
                      <span class="field-value">{{ sensor.sensor_lot_no || '-' }}</span>
                    </div>
                    <div class="sensor-col sensor-col-field">
                      <span class="field-value">{{ sensor.sensor_batch || '-' }}</span>
                    </div>
                    <div class="sensor-col sensor-col-field">
                      <span class="field-value">{{ sensor.sensor_number || '-' }}</span>
                    </div>
                    <div class="sensor-col sensor-col-field">
                      <span class="field-value">{{ sensor.transmitter_id || '-' }}</span>
                    </div>
                    <div class="sensor-col sensor-col-time">
                      <span class="field-value">{{ formatSimpleDate(sensor.wear_time) }}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="no-sensors">
                <el-icon><Monitor /></el-icon>
                <span>暂无传感器</span>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button
              :disabled="!authStore.hasModulePermission('wear_records', 'write')"
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('wear_records', 'delete')"
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
      :title="isEdit ? '编辑佩戴记录' : '新建佩戴记录'"
      width="900px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="120px"
      >
        <el-row :gutter="24">
          <el-col :span="8">
            <el-form-item label="选择批次" prop="batch_id">
              <el-select
                v-model="form.batch_id"
                placeholder="请选择批次"
                style="width: 100%"
                filterable
                :disabled="isEdit"
                @change="onBatchChange"
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
          <el-col :span="8">
            <el-form-item label="选择人员" prop="person_id">
              <el-select
                v-model="form.person_id"
                placeholder="请选择人员"
                style="width: 100%"
                filterable
                :disabled="isEdit || !form.batch_id"
              >
                <el-option
                  v-for="person in filteredPersonsForForm"
                  :key="person.person_id"
                  :label="`${person.person_name} (ID: ${person.person_id})`"
                  :value="person.person_id"
                />
              </el-select>
              <div class="form-tip" v-if="!isEdit">
                {{ form.batch_id ? '显示该批次下的人员' : '请先选择批次' }}
              </div>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="佩戴时间" prop="wear_time" required>
              <el-date-picker
                v-model="form.wear_time"
                type="datetime"
                placeholder="选择佩戴时间"
                style="width: 100%"
                format="YYYY-MM-DD HH:mm:ss"
                value-format="YYYY-MM-DD HH:mm:ss"
              />
            </el-form-item>
          </el-col>
        </el-row>
        
        <el-row :gutter="24">
          <el-col :span="24">
            <el-form-item label="传感器详细信息" prop="sensor_detail_ids">
              <el-select
                v-model="form.sensor_detail_ids"
                placeholder="请选择传感器（支持多个传感器佩戴）"
                style="width: 100%"
                filterable
                multiple
                collapse-tags
                collapse-tags-tooltip
              >
                <el-option
                  v-for="sensor in currentAvailableSensorDetails"
                  :key="sensor.sensor_detail_id"
                  :label="`测试编号: ${sensor.test_number} | 探针编号: ${sensor.probe_number} | 灭菌日期: ${sensor.sterilization_date || '未设置'}`"
                  :value="sensor.sensor_detail_id"
                >
                  <div class="sensor-option">
                    <div class="sensor-main">测试编号: {{ sensor.test_number }} | 探针编号: {{ sensor.probe_number }}</div>
                    <div class="sensor-sub">
                      <span v-if="sensor.sterilization_date">灭菌日期: {{ sensor.sterilization_date }}</span>
                      <span v-if="sensor.sensitivity"> | 灵敏度: {{ sensor.sensitivity.toFixed(6) }}</span>
                    </div>
                  </div>
                </el-option>
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        
        <!-- 每个传感器的独立参数 -->
        <div v-if="form.sensor_detail_ids.length > 0" class="sensor-params-container">
          <div 
            v-for="(sensorParam, index) in form.sensor_params" 
            :key="sensorParam.sensor_detail_id"
            class="sensor-param-card"
          >
            <div class="sensor-param-header">
              <h4>{{ getSensorDisplayName(sensorParam.sensor_detail_id) }}</h4>
              <el-button 
                v-if="isEdit && form.sensor_params.length > 1"
                type="danger" 
                size="small" 
                @click="removeSensorFromEdit(index)"
                :icon="Delete"
              >
                删除传感器
              </el-button>
            </div>
            <div class="sensor-param-fields">
              <el-row :gutter="12">
                <el-col :span="12">
                  <el-form-item label="敷贴器批号">
                    <el-input 
                      v-model="sensorParam.applicator_lot_no" 
                      placeholder="请输入敷贴器批号" 
                      maxlength="255"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="传感器批号">
                    <el-input 
                      v-model="sensorParam.sensor_lot_no" 
                      placeholder="请输入传感器批号" 
                      maxlength="255"
                    />
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="12">
                <el-col :span="8">
                  <el-form-item label="传感器批次">
                    <el-input 
                      v-model="sensorParam.sensor_batch" 
                      placeholder="请输入传感器批次" 
                      maxlength="255"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="传感器号">
                    <el-input 
                      v-model="sensorParam.sensor_number" 
                      placeholder="请输入传感器号" 
                      maxlength="255"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="发射器号">
                    <el-input 
                      v-model="sensorParam.transmitter_id" 
                      placeholder="请输入发射器号" 
                      maxlength="255"
                    />
                  </el-form-item>
                </el-col>
              </el-row>
            </div>
          </div>
        </div>
        
        <el-row :gutter="24">
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input
                v-model="form.remarks"
                type="textarea"
                :rows="4"
                placeholder="请输入备注信息（支持一人佩戴多个传感器，可在备注中说明具体佩戴情况）"
                maxlength="300"
                show-word-limit
              />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 批量添加对话框 -->
    <el-dialog
      v-model="batchDialogVisible"
      title="批量添加佩戴记录"
      width="1200px"
      @close="resetBatchForm"
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
          
          <el-row :gutter="12">
            <el-col :span="6">
              <el-form-item label="批次" required>
                <el-select
                  v-model="item.batch_id"
                  placeholder="请选择批次"
                  size="small"
                  style="width: 100%"
                  filterable
                  @change="() => {}"
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
            <el-col :span="6">
              <el-form-item label="人员" required>
                <el-select
                  v-model="item.person_id"
                  placeholder="请选择人员"
                  size="small"
                  style="width: 100%"
                  filterable
                >
                  <el-option
                    v-for="person in getFilteredPersonsForBatch(item.batch_id)"
                    :key="person.person_id"
                    :label="`${person.person_name} (ID: ${person.person_id})`"
                    :value="person.person_id"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="传感器" required>
                <el-select
                  v-model="item.sensor_detail_ids"
                  placeholder="请选择传感器（支持多选）"
                  size="small"
                  style="width: 100%"
                  filterable
                  multiple
                  collapse-tags
                  collapse-tags-tooltip
                >
                  <el-option
                    v-for="sensor in availableSensorDetails"
                    :key="sensor.sensor_detail_id"
                    :label="`${sensor.test_number} | ${sensor.probe_number}`"
                    :value="sensor.sensor_detail_id"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="佩戴时间" required>
                <el-date-picker
                  v-model="item.wear_time"
                  type="datetime"
                  placeholder="选择佩戴时间"
                  size="small"
                  style="width: 100%"
                  format="YYYY-MM-DD HH:mm:ss"
                  value-format="YYYY-MM-DD HH:mm:ss"
                />
              </el-form-item>
            </el-col>
          </el-row>
          
          <!-- 传感器相关信息 -->
          <el-row :gutter="12">
            <el-col :span="8">
              <el-form-item label="敷贴器批号">
                <el-input
                  v-model="item.applicator_lot_no"
                  placeholder="敷贴器批号"
                  size="small"
                  maxlength="255"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="传感器批号">
                <el-input
                  v-model="item.sensor_lot_no"
                  placeholder="传感器批号"
                  size="small"
                  maxlength="255"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="传感器批次">
                <el-input
                  v-model="item.sensor_batch"
                  placeholder="传感器批次"
                  size="small"
                  maxlength="255"
                />
              </el-form-item>
            </el-col>
          </el-row>
          
          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="传感器号">
                <el-input
                  v-model="item.sensor_number"
                  placeholder="传感器号"
                  size="small"
                  maxlength="255"
                />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="发射器号">
                <el-input
                  v-model="item.transmitter_id"
                  placeholder="发射器号"
                  size="small"
                  maxlength="255"
                />
              </el-form-item>
            </el-col>
          </el-row>
          
          <el-row :gutter="12">
            <el-col :span="24">
              <el-form-item label="备注">
                <el-input
                  v-model="item.remarks"
                  placeholder="请输入备注信息"
                  size="small"
                  maxlength="200"
                />
              </el-form-item>
            </el-col>
          </el-row>
          
          <el-divider v-if="index < batchForm.length - 1" />
        </div>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="batchDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleBatchSubmit" :loading="loading">
            确定添加
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Download, Plus, User, UserFilled, Monitor, Calendar, Delete } from '@element-plus/icons-vue'
import { ApiService, type WearRecord, type Batch, type Person, type SensorDetail } from '../services/api'
import { useAuthStore } from '../stores/auth'
import { usePagination } from '../composables/usePagination'
import { formatDateTime, formatDate } from '../utils/formatters'
import { exportToExcel } from '../utils/excel'

// 格式化简单日期格式
const formatSimpleDate = (dateString: string) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const day = date.getDate()
  return `${year}.${month}.${day}`
}

const authStore = useAuthStore()

// 数据状态
const loading = ref(false)
const wearRecords = ref<WearRecord[]>([])
const batches = ref<Batch[]>([])
const persons = ref<Person[]>([])
const sensorDetails = ref<SensorDetail[]>([])
const usedSensorIds = ref<number[]>([])
const searchKeyword = ref('')
const filterBatch = ref('')
const filterPerson = ref('')

// 筛选后的数据
const filteredWearRecords = computed(() => {
  let result = wearRecords.value
  
  // 应用搜索筛选
  if (searchKeyword.value && searchKeyword.value.trim() !== '') {
    const keyword = searchKeyword.value.trim().toLowerCase()
    result = result.filter(item => 
      (item.person_name || '').toLowerCase().includes(keyword)
    )
  }
  
  // 应用批次筛选
  if (filterBatch.value) {
    result = result.filter(record => record.batch_id.toString() === filterBatch.value)
  }
  
  // 应用人员筛选
  if (filterPerson.value) {
    result = result.filter(record => record.person_id.toString() === filterPerson.value)
  }
  
  return result
})

// 按人员分组的佩戴记录数据
interface PersonWearRecord {
  person_id: number
  person_name: string
  batch_id: number
  batch_number: string
  earliest_wear_time?: string
  latest_wear_time?: string
  sensors: Array<{
    wear_record_id: number
    sensor_detail_id: number
    sensor_detail: any
    wear_time: string
    remarks?: string
    applicator_lot_no?: string
    sensor_lot_no?: string
    sensor_batch?: string
    sensor_number?: string
    transmitter_id?: string
  }>
}

const groupedWearRecords = computed(() => {
  const grouped = new Map<number, PersonWearRecord>()
  
  filteredWearRecords.value.forEach(record => {
    if (!grouped.has(record.person_id)) {
      grouped.set(record.person_id, {
        person_id: record.person_id,
        person_name: record.person_name || `人员${record.person_id}`,
        batch_id: record.batch_id,
        batch_number: record.batch_number || `批次${record.batch_id}`,
        sensors: [],
        earliest_wear_time: record.wear_time,
        latest_wear_time: record.wear_time
      })
    }
    
    const personRecord = grouped.get(record.person_id)!
    const sensorData = {
      wear_record_id: record.wear_record_id,
      sensor_detail_id: record.sensor_detail_id,
      sensor_detail: record.sensor_detail,
      wear_time: record.wear_time,
      remarks: record.remarks,
      applicator_lot_no: record.applicator_lot_no,
      sensor_lot_no: record.sensor_lot_no,
      sensor_batch: record.sensor_batch,
      sensor_number: record.sensor_number,
      transmitter_id: record.transmitter_id
    }

    personRecord.sensors.push(sensorData)
    
    // 更新时间范围
    if (record.wear_time) {
      if (!personRecord.earliest_wear_time || record.wear_time < personRecord.earliest_wear_time) {
        personRecord.earliest_wear_time = record.wear_time
      }
      if (!personRecord.latest_wear_time || record.wear_time > personRecord.latest_wear_time) {
        personRecord.latest_wear_time = record.wear_time
      }
    }
  })
  
  const result = Array.from(grouped.values())

  return result
})

// 对话框状态
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref()

// 批量添加对话框状态
const batchDialogVisible = ref(false)
const batchFormRef = ref()

// 传感器参数接口
interface SensorParams {
  sensor_detail_id: number
  wear_record_id?: number // 编辑模式下需要的记录ID
  applicator_lot_no: string
  sensor_lot_no: string
  sensor_batch: string
  sensor_number: string
  transmitter_id: string
}

// 表单数据
const form = ref<{
  batch_id?: number
  person_id?: number
  wear_time?: string
  remarks?: string
  sensor_detail_ids: number[]
  sensor_params: SensorParams[]
  wear_record_id?: number
}>({
  batch_id: undefined,
  person_id: undefined,
  wear_time: undefined,
  remarks: '',
  sensor_detail_ids: [],
  sensor_params: []
})

// 批量表单数据
interface BatchFormItem {
  batch_id?: number
  person_id?: number
  sensor_detail_ids: number[]
  wear_time?: string
  remarks?: string
  applicator_lot_no?: string
  sensor_lot_no?: string
  sensor_batch?: string
  sensor_number?: string
  transmitter_id?: string
}

const batchForm = ref<BatchFormItem[]>([{
  batch_id: undefined,
  person_id: undefined,
  sensor_detail_ids: [],
  wear_time: new Date().toISOString().slice(0, 19).replace('T', ' '),
  remarks: '',
  applicator_lot_no: '',
  sensor_lot_no: '',
  sensor_batch: '',
  sensor_number: '',
  transmitter_id: ''
}])

// 表单验证规则
const rules = {
  batch_id: [
    { required: true, message: '请选择批次', trigger: 'change' }
  ],
  person_id: [
    { required: true, message: '请选择人员', trigger: 'change' }
  ],
  sensor_detail_ids: [
    { required: true, message: '请选择传感器', trigger: 'change' },
    { type: 'array', min: 1, message: '请至少选择一个传感器', trigger: 'change' }
  ]
}

// 筛选和搜索逻辑已在上面的computed中实现

// 分页
const {
  currentPage,
  pageSize,
  pageSizes,
  total,
  paginatedData: paginatedPersonRecords,
  handleSizeChange,
  handleCurrentChange
} = usePagination(groupedWearRecords)

// 计算属性
const totalWearRecords = computed(() => wearRecords.value.length)

const uniquePersonsCount = computed(() => {
  const personIds = new Set(wearRecords.value.map(record => record.person_id))
  return personIds.size
})

const uniqueSensorsCount = computed(() => {
  const sensorIds = new Set(wearRecords.value.map(record => record.sensor_detail_id))
  return sensorIds.size
})

const todayRecordsCount = computed(() => {
  const today = new Date().toDateString()
  return wearRecords.value.filter(record => {
    if (!record.wear_time) return false
    return new Date(record.wear_time).toDateString() === today
  }).length
})

const availableBatches = computed(() => {
  const batchIds = new Set(wearRecords.value.map(record => record.batch_id))
  return batches.value.filter(batch => batchIds.has(batch.batch_id))
})

const availablePersons = computed(() => {
  const personIds = new Set(wearRecords.value.map(record => record.person_id))
  return persons.value.filter(person => personIds.has(person.person_id))
})

const filteredPersonsForForm = computed(() => {
  if (!form.value.batch_id) return []
  return persons.value.filter(person => person.batch_id === form.value.batch_id)
})

// 过滤可用传感器（排除已被使用的）
const availableSensorDetails = computed(() => {
  return sensorDetails.value.filter(sensor => !usedSensorIds.value.includes(sensor.sensor_detail_id))
})

// 编辑模式下的可用传感器（包含该人员已佩戴的传感器和其他未使用的传感器）
const editModeAvailableSensorDetails = computed(() => {
  if (!isEdit.value || !form.value.person_id || !form.value.batch_id) {
    return availableSensorDetails.value
  }
  
  // 获取该人员当前已佩戴的传感器ID
  const currentPersonSensorIds = wearRecords.value
    .filter(record => record.person_id === form.value.person_id && record.batch_id === form.value.batch_id)
    .map(record => record.sensor_detail_id)
  
  // 返回该人员已佩戴的传感器 + 其他未使用的传感器
  return sensorDetails.value.filter(sensor => 
    currentPersonSensorIds.includes(sensor.sensor_detail_id) || 
    !usedSensorIds.value.includes(sensor.sensor_detail_id)
  )
})

// 当前使用的传感器详细信息（根据编辑模式选择）
const currentAvailableSensorDetails = computed(() => {
  return isEdit.value ? editModeAvailableSensorDetails.value : availableSensorDetails.value
})

// 监听筛选条件变化
watch([filterBatch, filterPerson], () => {
  handleFilter()
})

// 监听传感器选择变化，同步参数数组
watch(() => form.value.sensor_detail_ids, (newIds, oldIds) => {
  if (!newIds) return
  
  // 获取当前已有的参数
  const existingParams = new Map(form.value.sensor_params.map(p => [p.sensor_detail_id, p]))
  
  // 创建新的参数数组
  form.value.sensor_params = newIds.map(sensorId => {
    // 如果已存在参数，保留原有值
    if (existingParams.has(sensorId)) {
      return existingParams.get(sensorId)!
    }
    // 否则创建新的空参数
    return {
      sensor_detail_id: sensorId,
      applicator_lot_no: '',
      sensor_lot_no: '',
      sensor_batch: '',
      sensor_number: '',
      transmitter_id: ''
    }
  })
}, { deep: true })

// 获取传感器显示名称
const getSensorDisplayName = (sensorId: number) => {
  const sensor = currentAvailableSensorDetails.value.find(s => s.sensor_detail_id === sensorId)
  return sensor ? `传感器 ${sensor.test_number} - ${sensor.probe_number}` : `传感器 ${sensorId}`
}

// 方法
const loadWearRecords = async () => {
  try {
    loading.value = true
    wearRecords.value = await ApiService.getWearRecords()

  } catch (error) {
    console.error('加载佩戴记录失败:', error)
    ElMessage.error('加载佩戴记录失败')
  } finally {
    loading.value = false
  }
}

const loadBatches = async () => {
  try {
    batches.value = await ApiService.getBatches()
  } catch (error) {
    console.error('加载批次数据失败:', error)
  }
}

const loadPersons = async () => {
  try {
    persons.value = await ApiService.getPersons()
  } catch (error) {
    console.error('加载人员数据失败:', error)
  }
}

const loadSensorDetails = async () => {
  try {
    sensorDetails.value = await ApiService.getSensorDetails()
  } catch (error) {
    console.error('加载传感器详细信息失败:', error)
  }
}

const loadUsedSensors = async () => {
  try {
    usedSensorIds.value = await ApiService.getUsedSensors()
  } catch (error: any) {
    console.error('加载已使用传感器失败:', error)
    ElMessage.error(`加载已使用传感器失败: ${error.response?.data?.detail || error.message || '未知错误'}`)
  }
}

const handleSearch = () => {
  currentPage.value = 1
}

const handleFilter = () => {
  currentPage.value = 1
  // 筛选逻辑通过computed属性自动处理
}

const handleAdd = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

const handleEdit = (row: PersonWearRecord) => {
  // 编辑人员的所有传感器记录
  if (row.sensors && row.sensors.length > 0) {
    // 获取该人员的所有传感器记录
    const personWearRecords = wearRecords.value.filter(record => 
      record.person_id === row.person_id && record.batch_id === row.batch_id
    )
    
    if (personWearRecords.length > 0) {
      // 使用第一条记录的基本信息（批次、人员、佩戴时间、备注）
      const firstRecord = personWearRecords[0]
      
      isEdit.value = true
      form.value = {
        batch_id: firstRecord.batch_id,
        person_id: firstRecord.person_id,
        wear_time: firstRecord.wear_time,
        remarks: firstRecord.remarks || '',
        wear_record_id: firstRecord.wear_record_id, // 保留第一条记录的ID作为主记录
        sensor_detail_ids: personWearRecords.map(record => record.sensor_detail_id),
        sensor_params: personWearRecords.map(record => ({
          sensor_detail_id: record.sensor_detail_id,
          wear_record_id: record.wear_record_id, // 保存每个传感器记录的ID
          applicator_lot_no: record.applicator_lot_no || '',
          sensor_lot_no: record.sensor_lot_no || '',
          sensor_batch: record.sensor_batch || '',
          sensor_number: record.sensor_number || '',
          transmitter_id: record.transmitter_id || ''
        }))
      }
      dialogVisible.value = true
    }
  } else {
    ElMessage.warning('该人员暂无传感器记录可编辑')
  }
}

const handleDelete = async (row: PersonWearRecord) => {
  try {
    if (!row.sensors || row.sensors.length === 0) {
      ElMessage.warning('该人员暂无传感器记录可删除')
      return
    }
    
    await ElMessageBox.confirm(
      `确定要删除人员 "${row.person_name}" 的所有 ${row.sensors.length} 条佩戴记录吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    // 删除该人员的所有传感器记录
    for (const sensor of row.sensors) {
      await ApiService.deleteWearRecord(sensor.wear_record_id)
    }
    
    ElMessage.success(`成功删除 ${row.sensors.length} 条记录`)
    await Promise.all([loadWearRecords(), loadUsedSensors()])
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除佩戴记录失败:', error)
      ElMessage.error('删除失败')
    }
  }
}



const handleAddSensorToPerson = (personRecord: PersonWearRecord) => {
  // 为指定人员添加传感器
  isEdit.value = false
  form.value = {
    batch_id: personRecord.batch_id,
    person_id: personRecord.person_id,
    wear_time: undefined,
    remarks: '',
    sensor_detail_ids: [],
    sensor_params: []
  }
  dialogVisible.value = true
}

// 编辑模式下删除传感器
const removeSensorFromEdit = async (index: number) => {
  try {
    const sensorParam = form.value.sensor_params[index]
    
    if (sensorParam.wear_record_id) {
      // 如果有wear_record_id，说明是已存在的记录，需要从数据库删除
      await ElMessageBox.confirm(
        '确定要删除这个传感器记录吗？此操作不可撤销。',
        '确认删除',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
      
      await ApiService.deleteWearRecord(sensorParam.wear_record_id)
      ElMessage.success('传感器记录删除成功')
      
      // 重新加载数据
      await Promise.all([loadWearRecords(), loadUsedSensors()])
    }
    
    // 从表单中移除
    form.value.sensor_params.splice(index, 1)
    form.value.sensor_detail_ids.splice(index, 1)
    
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除传感器失败:', error)
      ElMessage.error('删除传感器失败')
    }
  }
}



const handleSubmit = async () => {
  try {
    await formRef.value?.validate()
    
    if (isEdit.value) {
      // 编辑模式：更新该人员的所有传感器记录
      if (form.value.sensor_params.length === 0) {
        ElMessage.warning('请填写传感器参数')
        return
      }
      
      // 更新每个传感器记录
      for (const sensorParam of form.value.sensor_params) {
        if (!sensorParam.wear_record_id) {
          ElMessage.warning('传感器记录ID缺失，无法更新')
          return
        }
        
        const updateData = {
          batch_id: form.value.batch_id,
          person_id: form.value.person_id,
          sensor_detail_id: sensorParam.sensor_detail_id,
          wear_time: form.value.wear_time,
          remarks: form.value.remarks,
          applicator_lot_no: sensorParam.applicator_lot_no,
          sensor_lot_no: sensorParam.sensor_lot_no,
          sensor_batch: sensorParam.sensor_batch,
          sensor_number: sensorParam.sensor_number,
          transmitter_id: sensorParam.transmitter_id
        }
        
        await ApiService.updateWearRecord(sensorParam.wear_record_id, updateData)
      }
      
      ElMessage.success(`成功更新 ${form.value.sensor_params.length} 条传感器记录`)
    } else {
      // 新增模式：为每个传感器创建一条记录，使用各自的参数
      if (form.value.sensor_params.length === 0) {
        ElMessage.warning('请至少选择一个传感器')
        return
      }
      
      for (const sensorParam of form.value.sensor_params) {
        const recordData = {
          batch_id: form.value.batch_id!,
          person_id: form.value.person_id!,
          sensor_detail_id: sensorParam.sensor_detail_id,
          wear_time: form.value.wear_time,
          remarks: form.value.remarks,
          applicator_lot_no: sensorParam.applicator_lot_no,
          sensor_lot_no: sensorParam.sensor_lot_no,
          sensor_batch: sensorParam.sensor_batch,
          sensor_number: sensorParam.sensor_number,
          transmitter_id: sensorParam.transmitter_id
        }
        
        await ApiService.createWearRecord(recordData)
      }
      
      ElMessage.success(`成功添加 ${form.value.sensor_params.length} 条佩戴记录`)
    }
    
    dialogVisible.value = false
    await Promise.all([loadWearRecords(), loadUsedSensors()])
  } catch (error: any) {
    console.error('保存佩戴记录失败:', error)
    const errorMessage = error.response?.data?.detail || error.message || '未知错误'
    ElMessage.error(`保存失败: ${errorMessage}`)
  }
}

const resetForm = () => {
  form.value = {
    batch_id: undefined,
    person_id: undefined,
    wear_time: undefined,
    remarks: '',
    sensor_detail_ids: [],
    sensor_params: []
  }
  formRef.value?.clearValidate()
}

const onBatchChange = () => {
  // 当批次改变时，清空人员选择
  form.value.person_id = undefined
}

const handleExport = async () => {
  try {
    loading.value = true
    
    // 获取当前筛选后的数据
    const recordsToExport = groupedWearRecords.value
    
    if (recordsToExport.length === 0) {
      ElMessage.warning('没有可导出的数据')
      return
    }
    
    // 构建导出数据
    const exportData: any[] = []
    
    for (const personRecord of recordsToExport) {
      const person = persons.value.find(p => p.person_id === personRecord.person_id)
      const batch = batches.value.find(b => b.batch_id === personRecord.batch_id)
      
      if (!person || !personRecord.sensors || personRecord.sensors.length === 0) {
        continue
      }
      
      // 为每个传感器创建一行数据
      for (let i = 0; i < personRecord.sensors.length; i++) {
        const sensor = personRecord.sensors[i]
        const sensorDetail = sensorDetails.value.find(s => s.sensor_detail_id === sensor.sensor_detail_id)
        
        // 格式化佩戴时间
        const formatWearTime = (dateStr: string) => {
          if (!dateStr) return ''
          const date = new Date(dateStr)
          const year = date.getFullYear()
          const month = String(date.getMonth() + 1).padStart(2, '0')
          const day = String(date.getDate()).padStart(2, '0')
          return `${year}.${month}.${day}`
        }
        
        const rowData = {
          '佩戴人员': i === 0 ? person.person_name : '', // 第一行显示姓名，后续行空白
          '佩戴记录': `传感器${i + 1}`, // 使用传感器序号作为佩戴记录
          '敷贴器批号': sensor.applicator_lot_no || '',
          '传感器批号': sensor.sensor_lot_no || '',
          '传感器批次': sensor.sensor_batch || '',
          '传感器号': sensor.sensor_number || '',
          '发射器号': sensor.transmitter_id || '',
          '佩戴开始时间': formatWearTime(sensor.wear_time),
          '0.00': (sensorDetail?.value_0 !== null && sensorDetail?.value_0 !== undefined) ? sensorDetail.value_0.toFixed(2) : '',
          '2.00': (sensorDetail?.value_2 !== null && sensorDetail?.value_2 !== undefined) ? sensorDetail.value_2.toFixed(2) : '',
          '5.00': (sensorDetail?.value_5 !== null && sensorDetail?.value_5 !== undefined) ? sensorDetail.value_5.toFixed(2) : '',
          '25.00': (sensorDetail?.value_25 !== null && sensorDetail?.value_25 !== undefined) ? sensorDetail.value_25.toFixed(2) : '',
          '初始灵敏度': (sensorDetail?.sensitivity !== null && sensorDetail?.sensitivity !== undefined) ? sensorDetail.sensitivity.toFixed(2) : '',
          'R': (sensorDetail?.r_value !== null && sensorDetail?.r_value !== undefined) ? sensorDetail.r_value.toFixed(4) : ''
        }
        
        exportData.push(rowData)
      }
    }
    
    if (exportData.length === 0) {
      ElMessage.warning('没有可导出的有效数据')
      return
    }
    
    // 生成文件名
    const now = new Date()
    const timestamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`
    const filename = `佩戴记录_${timestamp}`
    
    // 导出Excel
    const success = exportToExcel(exportData, filename, '佩戴记录')
    if (success) {
      ElMessage.success(`成功导出 ${exportData.length} 条记录`)
    } else {
      ElMessage.error('导出失败')
    }
    
  } catch (error: any) {
    console.error('导出失败:', error)
    ElMessage.error(`导出失败: ${error.message || '未知错误'}`)
  } finally {
    loading.value = false
  }
}

// 批量添加相关方法
const handleBatchAdd = () => {
  resetBatchForm()
  batchDialogVisible.value = true
}

const addBatchRow = () => {
  batchForm.value.push({
    batch_id: undefined,
    person_id: undefined,
    sensor_detail_ids: [],
    wear_time: new Date().toISOString().slice(0, 19).replace('T', ' '),
    remarks: '',
    applicator_lot_no: '',
    sensor_lot_no: '',
    sensor_batch: '',
    sensor_number: '',
    transmitter_id: ''
  })
}

const removeBatchRow = (index: number) => {
  if (batchForm.value.length > 1) {
    batchForm.value.splice(index, 1)
  }
}

const resetBatchForm = () => {
  batchForm.value = [{
    batch_id: undefined,
    person_id: undefined,
    sensor_detail_ids: [],
    wear_time: new Date().toISOString().slice(0, 19).replace('T', ' '),
    remarks: '',
    applicator_lot_no: '',
    sensor_lot_no: '',
    sensor_batch: '',
    sensor_number: '',
    transmitter_id: ''
  }]
}

const handleBatchSubmit = async () => {
  try {
    await batchFormRef.value?.validate()
    
    let totalRecords = 0
    
    for (const item of batchForm.value) {
      if (!item.batch_id || !item.person_id || !item.sensor_detail_ids.length) {
        ElMessage.warning('请完整填写所有必填项')
        return
      }
      
      // 如果佩戴时间为空，设置为当前时间
      const wearTime = item.wear_time || new Date().toISOString().slice(0, 19).replace('T', ' ')
      
      // 为每个传感器创建一条记录
      for (const sensorId of item.sensor_detail_ids) {
        const recordData = {
          batch_id: item.batch_id,
          person_id: item.person_id,
          sensor_detail_id: sensorId,
          wear_time: wearTime,
          remarks: item.remarks,
          applicator_lot_no: item.applicator_lot_no,
          sensor_lot_no: item.sensor_lot_no,
          sensor_batch: item.sensor_batch,
          sensor_number: item.sensor_number,
          transmitter_id: item.transmitter_id
        }

        await ApiService.createWearRecord(recordData)
        totalRecords++
      }
    }
    
    ElMessage.success(`成功批量添加 ${totalRecords} 条佩戴记录`)
    batchDialogVisible.value = false
    await Promise.all([loadWearRecords(), loadUsedSensors()])
  } catch (error: any) {
    console.error('批量添加佩戴记录失败:', error)
    const errorMessage = error.response?.data?.detail || error.message || '未知错误'
    ElMessage.error(`批量添加失败: ${errorMessage}`)
  }
}

const getFilteredPersonsForBatch = (batchId?: number) => {
  if (!batchId) return []
  return persons.value.filter(person => person.batch_id === batchId)
}

// 生命周期
onMounted(async () => {
  try {
    loading.value = true
    
    // 优先加载关键数据
    await Promise.all([
      loadWearRecords(),
      loadBatches(),
      loadPersons()
    ])
    
    // 延迟加载非关键数据，避免阻塞页面渲染
    setTimeout(async () => {
      await Promise.all([
        loadSensorDetails(),
        loadUsedSensors()
      ])
    }, 100)
  } catch (error) {
    console.error('页面初始化失败:', error)
    ElMessage.error('页面加载失败，请刷新重试')
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.wear-record-management {
  padding: 20px;
}

.page-header {
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 24px;
  font-weight: 600;
}

.page-header p {
  margin: 0;
  color: #606266;
  font-size: 14px;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 16px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.toolbar-left {
  display: flex;
  align-items: center;
}

.toolbar-right {
  display: flex;
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
  font-weight: 600;
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
  color: #fff;
}

.stat-icon.total {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.persons {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-icon.sensors {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-icon.today {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.data-count {
  color: #909399;
  font-size: 14px;
}

.sensor-detail-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.sensor-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.sensor-item .label {
  color: #909399;
  min-width: 60px;
}

.sensor-item .value {
  color: #303133;
  font-weight: 500;
}

.sensor-option {
  display: flex;
  flex-direction: column;
}

.sensor-main {
  font-weight: 500;
  color: #303133;
}

.sensor-sub {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.no-data {
  color: #c0c4cc;
  font-style: italic;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

/* 人员信息样式 */
.person-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.person-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: bold;
  flex-shrink: 0;
}

.person-details {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.person-name {
  font-weight: 500;
  color: #303133;
  font-size: 14px;
}

.person-id {
  color: #909399;
  font-size: 12px;
}

.batch-tag {
  margin-top: 2px;
}

/* 传感器展示样式 */
.sensors-cell {
  padding: 8px 0;
}

.sensors-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.sensors-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f0f0f0;
}

.group-icon {
  color: #409eff;
  font-size: 16px;
}

.sensor-count {
  color: #409eff;
  font-size: 14px;
  font-weight: 500;
}

/* 新的表格样式 */
.sensors-table {
  background: #ffffff;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
}

.sensors-table-header {
  display: flex;
  background: #f5f7fa;
  border-bottom: 1px solid #e4e7ed;
  font-weight: 600;
  color: #303133;
  font-size: 12px;
}

.sensors-table-row {
  display: flex;
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.3s ease;
}

.sensors-table-row:last-child {
  border-bottom: none;
}

.sensors-table-row:hover {
  background: #f5f7fa;
}

.sensor-col {
  padding: 8px 12px;
  display: flex;
  align-items: center;
  border-right: 1px solid #f0f0f0;
  min-height: 40px;
}

.sensor-col:last-child {
  border-right: none;
}

.sensor-col-name {
  flex: 0 0 180px;
  min-width: 180px;
}

.sensor-col-field {
  flex: 0 0 100px;
  min-width: 100px;
  justify-content: center;
}

.sensor-col-time {
  flex: 0 0 120px;
  min-width: 120px;
  justify-content: center;
}

.sensor-item-compact {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.sensor-info-compact {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  flex: 1;
}

.field-value {
  font-size: 12px;
  color: #303133;
  text-align: center;
  padding: 2px 6px;
  background: transparent;
  border-radius: 4px;
  min-height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* 保留原有的传感器项样式用于其他地方 */
.sensors-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sensor-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 8px;
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  transition: all 0.3s ease;
  max-width: 280px;
}

.sensor-item:hover {
  background: #e3f2fd;
  border-color: #90caf9;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.sensor-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: bold;
  flex-shrink: 0;
  margin-top: 2px;
}

.sensor-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.sensor-main {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.sensor-test {
  font-weight: 500;
  color: #303133;
  font-size: 13px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sensor-probe {
  color: #409EFF;
  font-size: 13px;
  font-weight: 600;
  background: #ecf5ff;
  padding: 3px 8px;
  border-radius: 4px;
  border: 1px solid #b3d8ff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sensor-time {
  color: #909399;
  font-size: 11px;
}

.sensor-sensitivity {
  color: #67c23a;
  font-size: 11px;
  font-weight: 500;
}

.sensor-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin-top: 4px;
  padding-top: 4px;
  border-top: 1px solid #e9ecef;
}

.sensor-field {
  font-size: 10px;
  color: #606266;
  background: #f5f7fa;
  padding: 1px 4px;
  border-radius: 3px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sensor-actions {
  display: flex;
  gap: 6px;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.sensor-item:hover .sensor-actions {
  opacity: 1;
}

.no-sensors {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 20px;
  color: #c0c4cc;
  font-size: 14px;
  background: #fafafa;
  border-radius: 8px;
  border: 1px dashed #e4e7ed;
}

.field-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-item {
  font-size: 12px;
  color: #303133;
  padding: 2px 4px;
  background: #f5f7fa;
  border-radius: 3px;
  text-align: center;
  min-height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.no-data {
  color: #c0c4cc;
  font-size: 12px;
  text-align: center;
}

.wear-time-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.time-range {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
}

.time-label {
  color: #909399;
  font-weight: 500;
  min-width: 32px;
}

.time-value {
  color: #303133;
  font-weight: 400;
}

/* 批量添加样式 */
.batch-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid #e4e7ed;
}

.batch-tip {
  color: #909399;
  font-size: 13px;
}

.batch-form-container {
  max-height: 500px;
  overflow-y: auto;
}

.batch-item {
  background: #fafafa;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
}

.batch-item:last-child {
  margin-bottom: 0;
}

.batch-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.item-number {
  font-weight: 500;
  color: #303133;
  font-size: 14px;
}

/* 传感器参数容器样式 */
.sensor-params-container {
  margin-top: 20px;
  margin-bottom: 20px;
}

.sensor-param-card {
  margin-bottom: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
}

.sensor-param-card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  border-color: #409eff;
}

.sensor-param-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: linear-gradient(135deg, #409eff 0%, #67c23a 100%);
  border-radius: 8px 8px 0 0;
  color: white;
  font-weight: 500;
}

.sensor-param-header h4 {
  margin: 0;
  font-size: 14px;
  font-weight: 500;
}



.sensor-param-fields {
  padding: 16px;
}

.sensor-param-fields .el-form-item {
  margin-bottom: 12px;
}

.sensor-param-fields .el-form-item:last-child {
  margin-bottom: 0;
}

/* 表单对话框样式优化 */
.el-dialog .el-form {
  padding: 0 8px;
}

.el-dialog .el-form-item {
  margin-bottom: 18px;
}

.el-dialog .el-form-item__label {
  font-weight: 500;
  color: #303133;
}

.el-dialog .el-input {
  border-radius: 6px;
}

.el-dialog .el-select {
  border-radius: 6px;
}

/* 按钮样式优化 */
.el-button {
  border-radius: 6px;
  font-weight: 500;
}

.el-button--primary {
  background: linear-gradient(135deg, #409eff 0%, #67c23a 100%);
  border: none;
}

.el-button--primary:hover {
  background: linear-gradient(135deg, #66b1ff 0%, #85ce61 100%);
}

/* 表格样式优化 */
.el-table {
  border-radius: 8px;
  overflow: hidden;
}

.el-table th {
  background: #f8f9fa;
  font-weight: 600;
  color: #303133;
}

.el-table td {
  border-bottom: 1px solid #f0f0f0;
}

.el-table tr:hover td {
  background: #f5f7fa;
}
</style>