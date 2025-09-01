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
        <el-table-column label="序号" width="80" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
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
        <el-table-column label="批次" width="150">
          <template #default="{ row }">
            <el-tag type="primary" size="small">
              {{ row.batch_number }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="传感器信息" min-width="800">
          <template #default="{ row }">
            <SensorInfoTable :sensors="row.sensors" />
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
    
    <!-- 佩戴记录对话框 -->
    <WearRecordDialog
      v-model:visible="dialogVisible"
      :is-edit="isEdit"
      :edit-data="editData"
      :batches="batches"
      :persons="persons"
      :sensor-details="sensorDetails"
      :sensors="sensors"
      :loading="submitLoading"
      :remove-sensor-from-edit="removeSensorFromEdit"
      @submit="handleDialogSubmit"
      @close="resetForm"
    />

    <!-- 批量添加对话框 -->
    <BatchAddDialog
      v-model:visible="batchDialogVisible"
      :batches="batches"
      :persons="persons"
      :available-sensor-details="sensorDetails"
      :sensors="sensors"
      :loading="loading"
      @submit="handleBatchSubmit"
      @close="resetBatchForm"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Download, Plus, User, UserFilled, Monitor, Calendar, Delete, Upload, Edit } from '@element-plus/icons-vue'
import { ApiService, type WearRecord, type Batch, type Person, type SensorDetail } from '../services/api'

// API函数通过ApiService调用
import { useAuthStore } from '../stores/auth'
import { usePagination } from '../composables/usePagination'
import { formatDateTime, formatDate } from '../utils/formatters'
import { exportToExcel } from '../utils/excel'
import SensorInfoTable from '@/components/SensorInfoTable.vue'
import WearRecordDialog from '@/components/WearRecordDialog.vue'
import BatchAddDialog from '@/components/BatchAddDialog.vue'

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
const sensors = ref<any[]>([]) // 传感器管理数据
const searchKeyword = ref('')
const filterBatch = ref('')
const filterPerson = ref('')

// 筛选后的数据
const filteredWearRecords = computed(() => {
  let result = wearRecords.value
  
  if (searchKeyword.value && searchKeyword.value.trim() !== '') {
    const keyword = searchKeyword.value.trim().toLowerCase()
    result = result.filter(item => 
      (item.person_name || '').toLowerCase().includes(keyword)
    )
  }
  
  if (filterBatch.value) {
    result = result.filter(record => record.batch_id.toString() === filterBatch.value)
  }
  
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
    sensor_id: number
    sensor_detail: any
    wear_time: string
    abnormal_situation?: string
    cause_analysis?: string
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
      sensor_id: record.sensor_id,
      sensor_detail: record.sensor_detail,
      test_number: record.sensor_detail?.test_number,
      probe_number: record.sensor_detail?.probe_number,
      wear_time: record.wear_time,
      wear_end_time: record.wear_end_time,
      wear_position: record.wear_position,
      user_name: record.user_name,
      nickname: record.nickname,
      abnormal_situation: record.abnormal_situation,
      cause_analysis: record.cause_analysis,
      applicator_lot_no: record.applicator_lot_no,
      sensor_lot_no: record.sensor_lot_no,
      sensor_batch: record.sensor_batch,
      sensor_number: record.sensor_number,
      transmitter_id: record.transmitter_id
    }
    


    personRecord.sensors.push(sensorData)
    

    
    if (record.wear_time) {
      if (!personRecord.earliest_wear_time || record.wear_time < personRecord.earliest_wear_time) {
        personRecord.earliest_wear_time = record.wear_time
      }
      if (!personRecord.latest_wear_time || record.wear_time > personRecord.latest_wear_time) {
        personRecord.latest_wear_time = record.wear_time
      }
    }
  })
  
  // 按照最新佩戴时间倒序排列，新增的记录显示在最前面
  return Array.from(grouped.values()).sort((a, b) => {
    const timeA = a.latest_wear_time || a.earliest_wear_time || ''
    const timeB = b.latest_wear_time || b.earliest_wear_time || ''
    return timeB.localeCompare(timeA) // 倒序排列
  })
})

// 对话框状态
const dialogVisible = ref(false)
const isEdit = ref(false)
const editData = ref(null)
const submitLoading = ref(false)
const formRef = ref()

// 批量添加对话框状态
const batchDialogVisible = ref(false)

// --- 重构与优化的核心逻辑 ---

// 1. 定义可复用的传感器参数接口，用于统一数据结构
interface SensorSpecificParams {
  user_name: string;
  nickname: string;
  wear_position: string;
  applicator_lot_no: string;
  sensor_lot_no: string;
  sensor_batch: string;
  sensor_number: string;
  transmitter_id: string;
  abnormal_situation: string;
  cause_analysis: string;
}

// 2. 创建一个生成默认参数的辅助函数，避免在多处重复定义空对象
const createDefaultSensorParams = (): SensorSpecificParams => ({
  user_name: '',
  nickname: '',
  wear_position: '',
  applicator_lot_no: '',
  sensor_lot_no: '',
  sensor_batch: '',
  sensor_number: '',
  transmitter_id: '',
  abnormal_situation: '',
  cause_analysis: ''
});

// 3. 抽象出构建API请求体的辅助函数，统一创建和更新时的数据格式
const buildRecordPayload = (baseInfo: any, sensorId: number, sensorParams: any) => {
  return {
    batch_id: baseInfo.batch_id,
    person_id: baseInfo.person_id,
    sensor_id: sensorId,
    wear_time: sensorParams.wear_time || baseInfo.wear_time,
    wear_end_time: sensorParams.wear_end_time || null,
    user_name: sensorParams.user_name,
    nickname: sensorParams.nickname,
    wear_position: sensorParams.wear_position,
    abnormal_situation: sensorParams.abnormal_situation,
    cause_analysis: sensorParams.reason_analysis !== undefined ? sensorParams.reason_analysis : (sensorParams.cause_analysis || ''),
    applicator_lot_no: sensorParams.applicator_lot_no,
    sensor_lot_no: sensorParams.sensor_lot_no,
    sensor_batch: sensorParams.sensor_batch,
    sensor_number: sensorParams.sensor_number,
    transmitter_id: sensorParams.transmitter_id
  };
};

// 传感器参数接口 (用于单个编辑表单)
interface SensorParams extends SensorSpecificParams {
  sensor_id: number;
  wear_record_id?: number; // 编辑模式下需要
}

// 表单数据
const form = ref<{
  batch_id?: number
  person_id?: number
  wear_time?: string
  sensor_detail_ids: number[]
  sensor_params: SensorParams[]
  wear_record_id?: number
}>({
  batch_id: undefined,
  person_id: undefined,
  wear_time: undefined,
  sensor_detail_ids: [],
  sensor_params: []
})



// 表单验证规则
const rules = {
  batch_id: [{ required: true, message: '请选择批次', trigger: 'change' }],
  person_id: [{ required: true, message: '请选择人员', trigger: 'change' }],
  sensor_detail_ids: [{ type: 'array', required: true, min: 1, message: '请至少选择一个传感器', trigger: 'change' }],
  wear_time: [{ required: true, message: '请选择佩戴开始时间', trigger: 'change' }]
};

// 分页
const {
  currentPage,
  pageSize,
  pageSizes,
  total,
  paginatedData: paginatedPersonRecords,
  handleSizeChange,
  handleCurrentChange
} = usePagination(groupedWearRecords);

// 计算属性 - 基于传感器管理数据过滤
const availableBatches = computed(() => {
  // 从传感器管理数据中获取已分配传感器的批次
  const sensorBatchIds = new Set(sensors.value.map(sensor => sensor.batch_id).filter(id => id));
  return batches.value.filter(batch => sensorBatchIds.has(batch.batch_id));
});

const availablePersons = computed(() => {
  // 从传感器管理数据中获取已分配传感器的人员
  const sensorPersonIds = new Set(sensors.value.map(sensor => sensor.person_id).filter(id => id));
  return persons.value.filter(person => sensorPersonIds.has(person.person_id));
});

const filteredPersonsForForm = computed(() => {
  if (!form.value.batch_id) return [];
  
  // 从传感器管理数据中获取指定批次的已分配传感器的人员
  const sensorPersonIds = new Set(
    sensors.value
      .filter(sensor => sensor.batch_id === form.value.batch_id)
      .map(sensor => sensor.person_id)
      .filter(id => id)
  );
  
  return persons.value.filter(person => 
    person.batch_id === form.value.batch_id && 
    sensorPersonIds.has(person.person_id)
  );
});

const availableSensorDetails = computed(() => {
  // 返回所有未被使用的传感器详情
  return sensorDetails.value.filter(sensor => 
    !usedSensorIds.value.includes(sensor.sensor_detail_id)
  );
});

const editModeAvailableSensorDetails = computed(() => {
  if (!isEdit.value || !editData.value?.person_id) return availableSensorDetails.value;
  
  const currentPersonSensorIds = wearRecords.value
    .filter(record => record.person_id === editData.value.person_id)
    .map(record => record.sensor_id);
    
  return sensorDetails.value.filter(sensor => 
    currentPersonSensorIds.includes(sensor.sensor_detail_id) || 
    !usedSensorIds.value.includes(sensor.sensor_detail_id)
  );
});

const currentAvailableSensorDetails = computed(() => {
  return isEdit.value ? editModeAvailableSensorDetails.value : availableSensorDetails.value;
})



// 获取传感器显示名称
const getSensorDisplayName = (sensorId: number) => {
  const sensor = sensorDetails.value.find(s => s.sensor_detail_id === sensorId);
  return sensor ? `传感器 ${sensor.test_number} - ${sensor.probe_number}` : `传感器 ${sensorId}`;
};

// 方法
const loadData = async () => {
  loading.value = true;
  try {
    const [wearRecordsData, batchesData, personsData, sensorDetailsData, usedSensorIdsData, sensorsData] = await Promise.all([
      ApiService.getWearRecords(),
      ApiService.getBatches(),
      ApiService.getPersons(),
      ApiService.getSensorDetails(),
      ApiService.getUsedSensors(),
      ApiService.getSensors()
    ]);
    
    wearRecords.value = wearRecordsData;
    batches.value = batchesData;
    persons.value = personsData;
    sensorDetails.value = sensorDetailsData;
    usedSensorIds.value = usedSensorIdsData;
    sensors.value = sensorsData;
    
    // 调试信息 - 基本统计
    console.log('数据加载完成 - 传感器详情:', sensorDetailsData?.length || 0, '条, 传感器管理:', sensorsData?.length || 0, '条');
  } catch (error) {
    console.error('加载数据失败:', error);
    ElMessage.error('数据加载失败，请刷新重试');
  } finally {
    loading.value = false;
  }
};

const handleSearch = () => { currentPage.value = 1; };
const handleFilter = () => { currentPage.value = 1; };

const handleAdd = () => {
  isEdit.value = false;
  editData.value = null;
  dialogVisible.value = true;
};

const handleEdit = (row: PersonWearRecord) => {
  const personWearRecords = wearRecords.value.filter(record => record.person_id === row.person_id);
  if (personWearRecords.length > 0) {
    const firstRecord = personWearRecords[0];
    isEdit.value = true;
    
    // 修复sensor_detail_id为null的问题
    const getSensorDetailId = (record: any) => {
      // 如果sensor_detail_id存在且不为null，直接使用
      if (record.sensor_detail_id != null) {
        return record.sensor_detail_id;
      }
      
      // 如果sensor_detail_id为null，从sensors数组中查找对应的sensor记录
      const sensor = sensors.value.find(s => s.sensor_id === record.sensor_id);
      return sensor?.sensor_detail_id || null;
    };
    
    editData.value = {
      batch_id: firstRecord.batch_id,
      person_id: firstRecord.person_id,
      wear_time: firstRecord.wear_time,
      sensor_detail_ids: personWearRecords.map(r => getSensorDetailId(r)),
      sensor_parameters: personWearRecords.map(r => ({
        sensor_detail_id: getSensorDetailId(r),
        sensor_id: r.sensor_id,
        wear_record_id: r.wear_record_id,
        wear_time: r.wear_time,
        wear_end_time: r.wear_end_time || '',
        user_name: r.user_name || '',
        nickname: r.nickname || '',
        wear_position: r.wear_position || '',
        applicator_lot_no: r.applicator_lot_no || '',
        sensor_lot_no: r.sensor_lot_no || '',
        sensor_batch: r.sensor_batch || '',
        sensor_number: r.sensor_number || '',
        transmitter_id: r.transmitter_id || '',
        abnormal_situation: r.abnormal_situation || '',
        reason_analysis: r.cause_analysis || ''
      }))
    };
    dialogVisible.value = true;
  }
};

// 处理对话框提交
const handleDialogSubmit = async (formData: any) => {
  submitLoading.value = true;
  try {
    const tasks: Promise<any>[] = [];
    
    if (isEdit.value && editData.value) {
      // 编辑模式：先处理删除操作
      if (formData.sensor_parameters && formData.sensor_parameters.length > 0) {
        // 找出被删除的传感器记录
        const currentSensorDetailIds = new Set(formData.sensor_parameters.map((p: any) => p.sensor_detail_id));
        const originalSensorParams = editData.value.sensor_parameters || [];
        
        // 删除被移除的传感器记录
        const deletePromises = [];
        for (const originalParam of originalSensorParams) {
          if (originalParam.wear_record_id && !currentSensorDetailIds.has(originalParam.sensor_detail_id)) {
            deletePromises.push(ApiService.deleteWearRecord(originalParam.wear_record_id));
          }
        }
        
        // 先执行删除操作
        if (deletePromises.length > 0) {
          await Promise.all(deletePromises);
        }
        
        // 然后处理更新和创建操作
        for (const sensorParam of formData.sensor_parameters) {
          const payload = buildRecordPayload(formData, sensorParam.sensor_id, sensorParam);
          if (sensorParam.wear_record_id) {
            tasks.push(ApiService.updateWearRecord(sensorParam.wear_record_id, payload));
          } else {
            tasks.push(ApiService.createWearRecord(payload));
          }
        }
      } else {
        // 兼容旧的单记录更新方式
        await ApiService.updateWearRecord(editData.value.wear_record_id, formData);
      }
    } else {
      // 创建模式：为每个传感器创建单独的佩戴记录
      if (formData.sensor_parameters && formData.sensor_parameters.length > 0) {
        for (const sensorParam of formData.sensor_parameters) {
          const payload = buildRecordPayload(formData, sensorParam.sensor_id, sensorParam);
          tasks.push(ApiService.createWearRecord(payload));
        }
      } else if (formData.sensor_detail_ids && formData.sensor_detail_ids.length > 0) {
        // 兼容旧的数组格式
        for (let i = 0; i < formData.sensor_detail_ids.length; i++) {
          const sensorDetailId = formData.sensor_detail_ids[i];
          // 根据sensor_detail_id找到对应的sensor_id
          const sensor = sensors.value.find(s => s.sensor_detail_id === sensorDetailId);
          if (!sensor) {
            throw new Error(`未找到sensor_detail_id为${sensorDetailId}的传感器记录`);
          }
          const sensorParam = formData.sensor_parameters?.[i] || createDefaultSensorParams();
          const payload = buildRecordPayload(formData, sensor.sensor_id, sensorParam);
          tasks.push(ApiService.createWearRecord(payload));
        }
      } else {
        // 兼容单个传感器的情况
        await ApiService.createWearRecord(formData);
      }
    }
    
    if (tasks.length > 0) {
      await Promise.all(tasks);
    }
    
    dialogVisible.value = false;
    await loadData();
    ElMessage.success(isEdit.value ? '更新成功' : '创建成功');
  } catch (error: any) {
    console.error('提交失败:', error);
    const msg = error.response?.data?.detail || (isEdit.value ? '更新失败' : '创建失败');
    ElMessage.error(msg);
  } finally {
    submitLoading.value = false;
  }
};

const handleDelete = async (row: PersonWearRecord) => {
  try {
    await ElMessageBox.confirm(`确定要删除人员 "${row.person_name}" 的所有 ${row.sensors.length} 条佩戴记录吗？`, '确认删除', { type: 'warning' });
    await Promise.all(row.sensors.map(s => ApiService.deleteWearRecord(s.wear_record_id)));
    ElMessage.success(`成功删除 ${row.sensors.length} 条记录`);
    await loadData();
  } catch (error) {
    if (error !== 'cancel') ElMessage.error('删除失败');
  }
};

const removeSensorFromEdit = async (wearRecordId: number) => {
  try {
    await ElMessageBox.confirm('确定要删除这个已保存的传感器记录吗？此操作不可撤销。', '确认删除', { type: 'warning' });
    await ApiService.deleteWearRecord(wearRecordId);
    ElMessage.success('传感器记录删除成功');
    // 从表单数据中移除对应的记录
    const index = form.value.sensor_params.findIndex(param => param.wear_record_id === wearRecordId);
    if (index !== -1) {
      form.value.sensor_params.splice(index, 1);
      form.value.sensor_detail_ids.splice(index, 1);
    }
    await loadData();
  } catch (error) {
    if (error !== 'cancel') ElMessage.error('删除传感器失败');
  }
};

const handleSubmit = async () => {
  try {
    await formRef.value?.validate();
    const tasks: Promise<any>[] = [];

    if (isEdit.value) {
      for (const sensorParam of form.value.sensor_params) {
        const payload = buildRecordPayload(form.value, sensorParam.sensor_id, sensorParam);
        if (sensorParam.wear_record_id) {
          tasks.push(ApiService.updateWearRecord(sensorParam.wear_record_id, payload));
        } else {
          tasks.push(ApiService.createWearRecord(payload));
        }
      }
    } else {
      for (const sensorParam of form.value.sensor_params) {
        const payload = buildRecordPayload(form.value, sensorParam.sensor_id, sensorParam);
        tasks.push(ApiService.createWearRecord(payload));
      }
    }
    
    await Promise.all(tasks);
    ElMessage.success(isEdit.value ? '更新成功' : '添加成功');
    dialogVisible.value = false;
    await loadData();
  } catch (error: any) {
    const msg = error.response?.data?.detail || '操作失败';
    ElMessage.error(msg);
  }
};

const resetForm = () => {
  editData.value = null;
};

const onBatchChange = () => { form.value.person_id = undefined; };

const handleExport = () => {
  try {
    // 准备导出数据，将分组数据展开为平铺结构
    const exportData = filteredWearRecords.value.map(record => ({
      '佩戴记录ID': record.wear_record_id,
      '人员姓名': record.person_name || '',
      '人员ID': record.person_id,
      '用户名称': record.nickname || '',
      '批次号': record.batch_number || '',
      '批次ID': record.batch_id,
      '传感器测试编号': record.sensor_detail?.test_number || '',
      '探针编号': record.sensor_detail?.probe_number || '',
      '敷贴器批号': record.applicator_lot_no || '',
      '传感器批号': record.sensor_lot_no || '',
      '传感器批次': record.sensor_batch || '',
      '传感器编号': record.sensor_number || '',
      '发射器ID': record.transmitter_id || '',
      '佩戴位置': record.wear_position || '',
      '佩戴时间': record.wear_time ? formatDate(record.wear_time) : '',
      '异常情况': record.abnormal_situation || '',
      '原因分析': record.cause_analysis || '',
      '0.00': record.sensor_detail?.value_0 !== null && record.sensor_detail?.value_0 !== undefined ? record.sensor_detail.value_0.toFixed(2) : '',
      '2.00': record.sensor_detail?.value_2 !== null && record.sensor_detail?.value_2 !== undefined ? record.sensor_detail.value_2.toFixed(2) : '',
      '5.00': record.sensor_detail?.value_5 !== null && record.sensor_detail?.value_5 !== undefined ? record.sensor_detail.value_5.toFixed(2) : '',
      '25.00': record.sensor_detail?.value_25 !== null && record.sensor_detail?.value_25 !== undefined ? record.sensor_detail.value_25.toFixed(2) : '',
      '初始灵敏度': record.sensor_detail?.sensitivity !== null && record.sensor_detail?.sensitivity !== undefined ? record.sensor_detail.sensitivity.toFixed(6) : '',
      'R值': record.sensor_detail?.r_value !== null && record.sensor_detail?.r_value !== undefined ? record.sensor_detail.r_value.toFixed(4) : ''
    }))

    // 生成文件名
    let filename = '佩戴记录数据'
    
    // 如果有筛选条件，添加到文件名中
    const filters = []
    if (filterBatch.value) {
      const batch = batches.value.find(b => b.batch_id.toString() === filterBatch.value)
      if (batch) {
        filters.push(`批次${batch.batch_number}`)
      }
    }
    if (filterPerson.value) {
      const person = persons.value.find(p => p.person_id.toString() === filterPerson.value)
      if (person) {
        filters.push(`人员${person.person_name}`)
      }
    }
    if (searchKeyword.value) {
      filters.push(`关键词${searchKeyword.value}`)
    }
    
    if (filters.length > 0) {
      filename += `_${filters.join('_')}`
    }
    
    // 添加时间戳
    const now = new Date()
    const timestamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`
    filename += `_${timestamp}`

    // 导出Excel文件
    const success = exportToExcel(exportData, filename, '佩戴记录数据')
    if (success) {
      ElMessage.success('导出成功')
    }
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败，请重试')
  }
};

// 批量添加相关方法
const handleBatchAdd = () => {
  batchDialogVisible.value = true;
};

const resetBatchForm = () => {
  // 重置逻辑由BatchAddDialog组件处理
};

const handleBatchSubmit = async (batchData: any[]) => {
  try {
    const tasks: Promise<any>[] = [];
    for (const item of batchData) {
      const wearTime = item.wear_time || new Date().toISOString().slice(0, 19).replace('T', ' ');
      for (const sensorParam of item.sensor_parameters) {
        const payload = buildRecordPayload({ ...item, wear_time: wearTime }, sensorParam.sensor_id, sensorParam);
        tasks.push(ApiService.createWearRecord(payload));
      }
    }
    await Promise.all(tasks);
    ElMessage.success(`成功批量添加 ${tasks.length} 条佩戴记录`);
    batchDialogVisible.value = false;
    await loadData();
  } catch (error: any) {
    const msg = error.response?.data?.detail || '批量添加失败';
    ElMessage.error(msg);
  }
};

// 生命周期
onMounted(loadData);
</script>

<style scoped>
.wear-record-management {
  padding: 24px;
  background-color: #f7f8fa;
  min-height: 100vh;
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

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.data-count {
  color: #909399;
  font-size: 14px;
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

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

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

/* 传感器表格样式已移至 SensorInfoTable 组件 */

.batch-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.batch-tip {
  color: #909399;
  font-size: 13px;
}

.batch-form-container {
  max-height: 500px;
  overflow-y: auto;
  padding-right: 10px;
}

.batch-item {
  background: #fafafa;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
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
}

.sensor-params-container {
  margin-top: 20px;
  margin-bottom: 20px;
}

.sensor-param-card {
  margin-bottom: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #ffffff;
}

.sensor-param-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: #f5f7fa;
  border-bottom: 1px solid #e4e7ed;
  border-radius: 8px 8px 0 0;
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

.el-dialog .el-form-item {
  margin-bottom: 18px;
}

.wear-record-name {
  font-weight: 500;
}

.user-name {
  color: #409eff;
  font-weight: 500;
}

.wear-end-time {
  color: #67c23a;
  font-weight: 500;
}

.abnormal-tag {
  background: #fef0f0;
  color: #f56c6c;
  border: 1px solid #fbc4c4;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.reason-analysis {
  color: #606266;
}

.time-not-ended {
  color: #e6a23c;
  font-style: italic;
}

.form-section {
  margin-bottom: 24px;
  padding: 16px;
  background: #fafbfc;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.form-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 16px;
  padding-bottom: 8px;
  border-bottom: 2px solid #409eff;
  display: flex;
  align-items: center;
  gap: 8px;
}

.form-section-icon {
  color: #409eff;
}

.field-tip {
  color: #909399;
  font-size: 12px;
  margin-top: 4px;
  line-height: 1.4;
}

.required-field .el-form-item__label::before {
  content: '*';
  color: #f56c6c;
  margin-right: 4px;
}
</style>
