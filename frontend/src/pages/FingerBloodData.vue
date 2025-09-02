<template>
  <div class="sensor-detail-management">
    <div class="page-header">
      <h2>指尖血数据管理</h2>
      <p>管理血糖数据的录入、查询和可视化展示</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-select
          v-model="filterBatchId"
          placeholder="筛选实验批次"
          clearable
          style="width: 130px; margin-right: 12px"
          @change="handleFilter"
        >
          <el-option
            v-for="batch in availableBatchesForFilter"
            :key="batch.batch_id"
            :label="batch.batch_number"
            :value="batch.batch_id"
          />
        </el-select>
        
        <el-select
          v-model="filterPersonId"
          placeholder="筛选人员"
          clearable
          style="width: 130px; margin-right: 12px"
          @change="handleFilter"
        >
          <el-option
            v-for="person in filteredPersonsForFilter"
            :key="person.person_id"
            :label="`${person.person_name} (ID: ${person.person_id})`"
            :value="person.person_id"
          />
        </el-select>
        
        <el-date-picker
          v-model="dateRange"
          type="datetimerange"
          range-separator="至"
          start-placeholder="开始时间"
          end-placeholder="结束时间"
          format="YYYY-MM-DD HH:mm:ss"
          value-format="YYYY-MM-DD HH:mm:ss"
          :locale="zhCn"
          style="width: 280px"
          @change="handleFilter"
        />
      </div>
      
      <div class="toolbar-right">
        <el-button 
          type="primary" 
          @click="handleAdd"
          :disabled="!authStore.hasModulePermission('finger_blood_data', 'write')"
        >
          <el-icon><Plus /></el-icon>
          录入数据
        </el-button>
        <el-button 
          type="success" 
          @click="handleBatchAdd"
          :disabled="!authStore.hasModulePermission('finger_blood_data', 'write')"
        >
          <el-icon><Plus /></el-icon>
          批量录入
        </el-button>
        <el-button @click="toggleChartView">
          <el-icon><TrendCharts /></el-icon>
          {{ showChart ? '隐藏图表' : '显示图表' }}
        </el-button>
        <el-button 
          @click="handleExport" 
          :loading="exportLoading"
          :disabled="!authStore.hasModulePermission('finger_blood_data', 'read')"
        >
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
      </div>
    </div>
    
    <!-- 图表展示 -->
    <el-card v-if="showChart" class="chart-card">
      <template #header>
        <div class="card-header">
          <span>血糖值变化趋势</span>
        </div>
      </template>
      <div class="chart-container">
        <v-chart
          class="chart"
          :option="chartOption"
          :loading="chartLoading"
        />
      </div>
    </el-card>
    
    <!-- 数据表格 -->
    <el-card class="data-card">
      <template #header>
        <div class="card-header">
          <span>血糖数据列表</span>
          <span class="data-count">共 {{ filteredData.length }} 条记录</span>
        </div>
      </template>
      
      <el-table
        :data="paginatedData"
        stripe
        style="width: 100%"
        v-loading="loading"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column label="序号" width="80" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <el-table-column prop="collection_time" label="采集时间" min-width="180" />
        <el-table-column prop="blood_glucose_value" label="血糖值(mmol/L)" min-width="200">
          <template #default="{ row }">
            <el-tag
              :type="getGlucoseLevel(row.blood_glucose_value).type"
              class="glucose-tag"
            >
              {{ row.blood_glucose_value }}
            </el-tag>
            <span class="glucose-level">
              {{ getGlucoseLevel(row.blood_glucose_value).label }}
            </span>
          </template>
        </el-table-column>
        <el-table-column label="关联实验批次" min-width="150">
          <template #default="{ row }">
            <el-tag type="primary">
              {{ getBatchNumber(row.batch_id) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="关联人员" min-width="120">
          <template #default="{ row }">
            <el-tag type="success">
              {{ getPersonName(row.person_id) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="240" fixed="right">
          <template #header>
            <div style="display: flex; align-items: center; gap: 8px;">
              <span>操作</span>
              <el-button
                v-if="selectedRows.length > 0"
                type="danger"
                size="small"
                @click="handleBatchDelete"
                :disabled="!authStore.hasModulePermission('finger_blood_data', 'delete')"
              >
                批量删除({{ selectedRows.length }})
              </el-button>
            </div>
          </template>
          <template #default="{ row }">
            <el-button
              type="primary"
              size="small"
              @click="handleEdit(row)"
              :disabled="!authStore.hasModulePermission('finger_blood_data', 'write')"
            >
              编辑
            </el-button>
            <el-button
              type="danger"
              size="small"
              @click="handleDelete(row)"
              :disabled="!authStore.hasModulePermission('finger_blood_data', 'delete')"
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
      :title="isEdit ? '编辑血糖数据' : '录入血糖数据'"
      width="1000px"
      @close="resetForm"
    >
      <div class="unified-form-layout">
        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
        >
        <el-form-item label="关联实验批次" prop="batch_id">
          <el-select
            v-model="form.batch_id"
            placeholder="请选择实验批次"
            style="width: 100%"
          >
            <el-option
              v-for="batch in dataStore.batches"
              :key="batch.batch_id"
              :label="`${batch.batch_number} (${batch.start_time})`"
              :value="batch.batch_id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="关联人员" prop="person_id">
          <el-select
            v-model="form.person_id"
            placeholder="请选择人员"
            style="width: 100%"
          >
            <el-option
              v-for="person in filteredPersonsForForm"
              :key="person.person_id"
              :label="`${person.person_name} (ID: ${person.person_id})`"
              :value="person.person_id"
            />
          </el-select>
          <div class="form-tip">
            {{ form.batch_id ? '显示该实验批次下的人员' : '请先选择实验批次' }}
          </div>
        </el-form-item>
        
        <el-form-item label="采集时间" prop="collection_time">
          <el-date-picker
            v-model="form.collection_time"
            type="datetime"
            placeholder="选择采集时间"
            style="width: 100%"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
            :locale="zhCn"
          />
        </el-form-item>
        
        <el-form-item label="血糖值(mmol/L)" prop="blood_glucose_value">
          <el-input-number
            v-model="form.blood_glucose_value"
            :min="0"
            :max="30"
            :precision="1"
            :step="0.1"
            placeholder="请输入血糖值"
            style="width: 100%"
          />
          <div class="glucose-hint">
            正常范围：3.9-6.1 mmol/L（空腹）
          </div>
        </el-form-item>
        </el-form>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 批量录入对话框 -->
    <el-dialog
      v-model="batchDialogVisible"
      title="批量录入血糖数据"
      width="900px"
      :close-on-click-modal="false"
      @close="resetBatchForm"
    >
      <el-form
        ref="batchFormRef"
        :model="batchForm"
        :rules="batchRules"
        label-width="120px"
        label-position="left"
      >
        <el-form-item label="关联实验批次" prop="batch_id">
          <el-select
            v-model="batchForm.batch_id"
            placeholder="请选择实验批次"
            style="width: 100%"
          >
            <el-option
              v-for="batch in dataStore.batches"
              :key="batch.batch_id"
              :label="`${batch.batch_number} (${batch.start_time})`"
              :value="batch.batch_id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="关联人员" prop="person_id">
          <el-select
            v-model="batchForm.person_id"
            placeholder="请选择人员"
            style="width: 100%"
          >
            <el-option
              v-for="person in filteredPersonsForBatchForm"
              :key="person.person_id"
              :label="`${person.person_name} (ID: ${person.person_id})`"
              :value="person.person_id"
            />
          </el-select>
          <div class="form-tip">
            {{ batchForm.batch_id ? '显示该实验批次下的人员' : '请先选择实验批次' }}
          </div>
        </el-form-item>

        <div class="data-section">
          <div class="section-header">
            <h4>血糖数据</h4>
            <el-button type="primary" size="small" @click="addDataItem">
              <el-icon><Plus /></el-icon>
              添加数据
            </el-button>
          </div>

          <div v-if="batchForm.dataList.length === 0" class="empty-hint">
            <p>暂无数据，请点击"添加数据"按钮添加</p>
          </div>

          <div v-for="(dataItem, index) in batchForm.dataList" :key="index" class="data-item">
            <el-card class="data-card" shadow="never">
              <div class="data-form">
                <el-form-item
                  :prop="`dataList.${index}.collection_time`"
                  :rules="commonDataRules.collection_time"
                  label="采集时间"
                >
                  <el-date-picker
                    v-model="dataItem.collection_time"
                    type="datetime"
                    placeholder="选择采集时间"
                    style="width: 100%"
                    format="YYYY-MM-DD HH:mm:ss"
                    value-format="YYYY-MM-DD HH:mm:ss"
                    :locale="zhCn"
                  />
                </el-form-item>

                <el-form-item
                  :prop="`dataList.${index}.blood_glucose_value`"
                  :rules="commonDataRules.blood_glucose_value"
                  label="血糖值(mmol/L)"
                >
                  <el-input-number
                    v-model="dataItem.blood_glucose_value"
                    :min="0"
                    :max="30"
                    :precision="1"
                    :step="0.1"
                    placeholder="请输入血糖值"
                    style="width: 100%"
                  />
                </el-form-item>

                <div class="data-actions">
                  <el-button
                    type="danger"
                    size="small"
                    @click="removeDataItem(index)"
                  >
                    <el-icon><Delete /></el-icon>
                    删除
                  </el-button>
                </div>
              </div>
            </el-card>
          </div>
        </div>
      </el-form>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="batchDialogVisible = false">取消</el-button>
          <el-button
            type="primary"
            :loading="loading"
            @click="handleBatchSubmit"
          >
            确定
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance } from 'element-plus'
import { TrendCharts, Plus, Download, Delete } from '@element-plus/icons-vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  DataZoomComponent,
  MarkLineComponent
} from 'echarts/components'
import { useDataStore, type FingerBloodData } from '../stores/data'
import { useAuthStore } from '../stores/auth'
import { ApiService } from '../services/api'
import { usePagination } from '@/composables/usePagination'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

import { getBatchNumber, getPersonName } from '@/utils/formatters'
import { exportMultipleSheetsToExcel } from '@/utils/excel'

// 注册ECharts组件
use([
  CanvasRenderer,
  LineChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  DataZoomComponent,
  MarkLineComponent
])

const dataStore = useDataStore()
const authStore = useAuthStore()

const loading = ref(false)
const exportLoading = ref(false)

// 批量删除相关
const selectedRows = ref<FingerBloodData[]>([])

// 组件挂载时获取最新数据
onMounted(async () => {
  try {
    loading.value = true
    // 使用缓存机制加载数据
    await Promise.all([
      dataStore.loadFingerBloodData(),
      dataStore.loadBatches(),
      dataStore.loadPersons()
    ])
  } catch (error) {
    console.error('Failed to load data:', error)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
})
const chartLoading = ref(false)
const showChart = ref(true)

// 筛选相关
const filterBatchId = ref<number | undefined>()
const filterPersonId = ref<number | undefined>()
const dateRange = ref<[string, string] | null>(null)

// 对话框相关
const dialogVisible = ref(false)
const batchDialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()
const batchFormRef = ref<FormInstance>()

// 分页相关
const { currentPage, pageSize, total, handleSizeChange, handleCurrentChange, resetPagination } = usePagination()
const pageSizes = [10, 20, 50, 100]

// 表单数据模型
const form = reactive({
  finger_blood_file_id: 0,
  batch_id: undefined as number | undefined,
  person_id: undefined as number | undefined,
  collection_time: '',
  blood_glucose_value: undefined as number | undefined
})

const batchForm = reactive({
  batch_id: undefined as number | undefined,
  person_id: undefined as number | undefined,
  dataList: [] as Array<{
    collection_time: string,
    blood_glucose_value: number | undefined
  }>
})

// [代码优化] 提取可复用的表单校验规则
const commonDataRules = {
  collection_time: [
    { required: true, message: '请选择采集时间', trigger: 'change' }
  ],
  blood_glucose_value: [
    { required: true, message: '请输入血糖值', trigger: 'blur' },
    { type: 'number', min: 0, max: 30, message: '血糖值应在0-30之间', trigger: 'blur' }
  ]
}

// 单个录入/编辑表单的校验规则
const rules = {
  batch_id: [{ required: true, message: '请选择关联批次', trigger: 'change' }],
  person_id: [{ required: true, message: '请选择关联人员', trigger: 'change' }],
  ...commonDataRules
}

// 批量录入表单的校验规则
const batchRules = {
  batch_id: [{ required: true, message: '请选择关联批次', trigger: 'change' }],
  person_id: [{ required: true, message: '请选择关联人员', trigger: 'change' }]
}

// [代码优化] 提取根据批次ID筛选人员的通用函数
const getFilteredPersonsByBatch = (batchId: number | undefined) => {
  if (!batchId) {
    return []
  }
  return dataStore.persons.filter(person => person.batch_id === batchId)
}

// 计算属性
// 顶部筛选器可用选项
const availableBatchesForFilter = computed(() => {
  const batchIds = [...new Set(dataStore.fingerBloodData.map(data => data.batch_id))]
  return dataStore.batches.filter(batch => batchIds.includes(batch.batch_id))
})

const availablePersonsForFilter = computed(() => {
  const personIds = [...new Set(dataStore.fingerBloodData.map(data => data.person_id))]
  return dataStore.persons.filter(person => personIds.includes(person.person_id))
})

const filteredPersonsForFilter = computed(() => {
  if (!filterBatchId.value) {
    return availablePersonsForFilter.value
  }
  return availablePersonsForFilter.value.filter(person => person.batch_id === filterBatchId.value)
})

// 表单内人员选项
const filteredPersonsForForm = computed(() => getFilteredPersonsByBatch(form.batch_id))
const filteredPersonsForBatchForm = computed(() => getFilteredPersonsByBatch(batchForm.batch_id))

// 过滤后的表格数据
const filteredData = computed(() => {
  let result = dataStore.fingerBloodData
  
  if (filterBatchId.value) {
    result = result.filter(data => data.batch_id === filterBatchId.value)
  }
  
  if (filterPersonId.value) {
    result = result.filter(data => data.person_id === filterPersonId.value)
  }
  
  if (dateRange.value && dateRange.value[0] && dateRange.value[1]) {
    result = result.filter(data => {
      const collectionTime = new Date(data.collection_time).getTime()
      const startTime = new Date(dateRange.value![0]).getTime()
      const endTime = new Date(dateRange.value![1]).getTime()
      return collectionTime >= startTime && collectionTime <= endTime
    })
  }
  
  return result.sort((a, b) => b.finger_blood_file_id - a.finger_blood_file_id)
})

// 当前页数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// [问题修复] 恢复原有的图表数据计算逻辑，避免意外修改共享数据状态
const chartData = computed(() => {
  let data = dataStore.fingerBloodData
  
  // 如果有筛选条件，使用筛选后的数据
  if (filterBatchId.value || filterPersonId.value || (dateRange.value && dateRange.value[0] && dateRange.value[1])) {
    data = filteredData.value
  } else {
    // 默认展示最新批次的数据
    if (data.length > 0) {
      // 找到最新的批次ID
      const latestBatchId = Math.max(...data.map(item => item.batch_id))
      data = data.filter(item => item.batch_id === latestBatchId)
      
      // 找到该批次数据的最新时间点
      const latestTime = Math.max(...data.map(item => new Date(item.collection_time).getTime()))
      const latestDate = new Date(latestTime)
      
      // 从最新时间点往前推15天
      const fifteenDaysAgo = new Date(latestDate.getTime() - 15 * 24 * 60 * 60 * 1000)
      data = data.filter(item => {
        const collectionTime = new Date(item.collection_time)
        return collectionTime >= fifteenDaysAgo && collectionTime <= latestDate
      })
    }
  }
  
  return data.sort((a, b) => new Date(a.collection_time).getTime() - new Date(b.collection_time).getTime())
})

// [问题修复] 恢复原有的图表配置，特别是 tooltip 的 formatter
const chartOption = computed(() => {
  const data = chartData.value
  
  if (data.length === 0) {
    return {
      title: { text: '暂无数据', left: 'center', top: 'center' }
    }
  }
  
  const groupedData = data.reduce((acc, item) => {
    const personName = getPersonName(item.person_id)
    if (!acc[personName]) {
      acc[personName] = []
    }
    acc[personName].push({
      time: item.collection_time,
      value: item.blood_glucose_value
    })
    return acc
  }, {} as Record<string, Array<{ time: string; value: number }>>)
  
  const series = Object.entries(groupedData).map(([personName, personData]) => ({
    name: personName,
    type: 'line',
    data: personData.map(item => [item.time, item.value]),
    smooth: true
  }))
  
  return {
    tooltip: {
      trigger: 'axis',
      formatter: (params: any) => {
        const formatTime = (timestamp: string | number) => new Date(timestamp).toLocaleString()
        let result = `<div>${formatTime(params[0].axisValue)}</div>`
        params.forEach((param: any) => {
          const level = getGlucoseLevel(param.value[1])
          result += `<div>${param.seriesName}: ${param.value[1]} (${level.label})</div>`
        })
        return result
      }
    },
    legend: {
      data: Object.keys(groupedData)
    },
    grid: { left: '3%', right: '4%', bottom: '15%', containLabel: true },
    xAxis: { type: 'time', boundaryGap: false },
    yAxis: { type: 'value', name: '血糖值 (mmol/L)' },
    dataZoom: [{ type: 'slider', show: true, start: 0, end: 100 }],
    series,
    markLine: {
      data: [
        { yAxis: 3.9, lineStyle: { color: '#67C23A' }, label: { formatter: '正常下限' } },
        { yAxis: 6.1, lineStyle: { color: '#67C23A' }, label: { formatter: '正常上限' } }
      ]
    }
  }
})


// 监听器
watch(() => filterBatchId.value, () => {
  filterPersonId.value = undefined
  resetPagination()
})
watch(() => form.batch_id, () => form.person_id = undefined)
watch(() => batchForm.batch_id, () => batchForm.person_id = undefined)
watch(() => filteredData.value.length, (newTotal) => total.value = newTotal, { immediate: true })

// 方法
// 获取血糖水平标签
const getGlucoseLevel = (value: number) => {
  if (value < 3.9) return { type: 'danger', label: '偏低' }
  if (value <= 6.1) return { type: 'success', label: '正常' }
  if (value <= 7.8) return { type: 'warning', label: '偏高' }
  return { type: 'danger', label: '过高' }
}

// 筛选处理
const handleFilter = () => resetPagination()
const toggleChartView = () => showChart.value = !showChart.value

// 新建/编辑/删除操作
const handleAdd = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

const handleEdit = (row: FingerBloodData) => {
  isEdit.value = true
  form.batch_id = row.batch_id
  nextTick(() => {
    Object.assign(form, row)
    dialogVisible.value = true
  })
}

const handleDelete = async (row: FingerBloodData) => {
  try {
    await ElMessageBox.confirm('确定要删除这条血糖数据吗？', '删除确认', { type: 'warning' })
    await dataStore.deleteFingerBloodData(row.finger_blood_file_id)
    ElMessage.success('删除成功')
    await dataStore.loadFingerBloodData(true) // 强制刷新
  } catch (error) {
    if (error !== 'cancel') ElMessage.error('删除失败')
  }
}

// 批量操作
const handleBatchAdd = () => {
  resetBatchForm()
  batchDialogVisible.value = true
}

const addDataItem = () => batchForm.dataList.push({ collection_time: '', blood_glucose_value: undefined })
const removeDataItem = (index: number) => batchForm.dataList.splice(index, 1)

const handleSelectionChange = (selection: FingerBloodData[]) => selectedRows.value = selection

const handleBatchDelete = async () => {
  if (selectedRows.value.length === 0) return ElMessage.warning('请先选择要删除的数据')

  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${selectedRows.value.length} 条数据吗？`, '批量删除确认', { type: 'warning' })
    const ids = selectedRows.value.map(row => row.finger_blood_file_id)
    await ApiService.batchDeleteFingerBloodData(ids)
    ElMessage.success('批量删除成功')
    selectedRows.value = []
    await dataStore.loadFingerBloodData(true)
  } catch (error) {
    if (error !== 'cancel') ElMessage.error('批量删除失败')
  }
}

// 表单提交
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        const payload = {
          batch_id: form.batch_id!,
          person_id: form.person_id!,
          collection_time: form.collection_time,
          blood_glucose_value: form.blood_glucose_value!
        }
        if (isEdit.value) {
          await dataStore.updateFingerBloodData(form.finger_blood_file_id, payload)
          ElMessage.success('更新成功')
        } else {
          await dataStore.addFingerBloodData(payload)
          ElMessage.success('录入成功')
        }
        dialogVisible.value = false
        resetForm() // [问题修复] 补回表单重置调用
      } catch (error) {
        ElMessage.error(isEdit.value ? '更新失败' : '录入失败')
      }
    }
  })
}

const handleBatchSubmit = async () => {
  if (!batchFormRef.value) return
  if (batchForm.dataList.length === 0) return ElMessage.warning('请至少添加一条数据')
  
  await batchFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        const promises = batchForm.dataList.map(item => dataStore.addFingerBloodData({
          batch_id: batchForm.batch_id!,
          person_id: batchForm.person_id!,
          collection_time: item.collection_time,
          blood_glucose_value: item.blood_glucose_value!
        }))
        await Promise.all(promises)
        ElMessage.success('批量录入成功')
        batchDialogVisible.value = false
        resetBatchForm() // [问题修复] 补回表单重置调用
      } catch (error) {
        ElMessage.error('批量录入失败')
      } finally {
        loading.value = false
      }
    }
  })
}

// 表单重置
const resetForm = () => {
  if (formRef.value) formRef.value.resetFields()
  Object.assign(form, { finger_blood_file_id: 0, batch_id: undefined, person_id: undefined, collection_time: '', blood_glucose_value: undefined })
}

const resetBatchForm = () => {
  if (batchFormRef.value) batchFormRef.value.resetFields()
  Object.assign(batchForm, { batch_id: undefined, person_id: undefined, dataList: [] })
}

// 导出数据
const handleExport = () => {
  exportLoading.value = true
  try {
    const groupedData = filteredData.value.reduce((acc, item) => {
      const personName = getPersonName(item.person_id) || `人员${item.person_id}`
      if (!acc[personName]) acc[personName] = []
      const dateTime = new Date(item.collection_time)
      acc[personName].push({
        '日期': `${dateTime.getFullYear()}.${dateTime.getMonth() + 1}.${dateTime.getDate()}`,
        '时间': `${String(dateTime.getHours()).padStart(2, '0')}:${String(dateTime.getMinutes()).padStart(2, '0')}`,
        '雅培': '',
        '指尖血': item.blood_glucose_value
      })
      return acc
    }, {} as Record<string, any[]>)

    Object.values(groupedData).forEach(data => 
      data.sort((a, b) => new Date(`${a['日期'].replace(/\./g, '-')} ${a['时间']}`).getTime() - new Date(`${b['日期'].replace(/\./g, '-')} ${b['时间']}`).getTime())
    )

    const sheets = Object.entries(groupedData).map(([personName, data]) => ({
      data: data,
      name: personName.replace(/[\\\/\[\]:*?"<>|]/g, '_')
    }))
    
    exportMultipleSheetsToExcel(sheets, '指尖血数据导出')
    ElMessage.success('导出成功')
  } catch (error) {
    ElMessage.error('导出失败')
  } finally {
    exportLoading.value = false
  }
}
</script>

<style scoped>
.sensor-detail-management {
  background-color: #f5f7fa;
  padding: 20px;
  min-height: 100vh;
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

.data-card {
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.unified-form-layout {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 20px;
  background-color: #fafafa;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
  padding: 20px 0;
}

.chart-card {
  margin-bottom: 20px;
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

.chart-container {
  height: 400px;
}

.chart {
  height: 100%;
  width: 100%;
}

.glucose-tag {
  margin-right: 8px;
}

.glucose-level {
  font-size: 12px;
  color: #909399;
}

.glucose-hint {
  margin-top: 4px;
  font-size: 12px;
  color: #909399;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
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
}

/* 批量录入样式 */
.data-section {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-header h4 {
  margin: 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
}

.empty-hint {
  text-align: center;
  padding: 40px 0;
  color: #909399;
}

.data-item {
  margin-bottom: 16px;
}

.data-card {
  border: 1px solid #e4e7ed;
}

.data-form {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 16px;
  align-items: end;
}

.data-actions {
  display: flex;
  gap: 8px;
  padding-top: 32px;
}

.form-tip {
  margin-top: 4px;
  font-size: 12px;
  color: #909399;
}

:deep(.data-form .el-form-item) {
  margin-bottom: 0;
}

/* 深度选择器样式 - 与传感器模块保持一致 */
:deep(.el-dialog) {
  border-radius: 8px;
}

:deep(.el-dialog__header) {
  padding: 20px 20px 10px;
  border-bottom: 1px solid #e4e7ed;
}

:deep(.el-dialog__body) {
  padding: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 600;
  color: #606266;
}

:deep(.el-input__wrapper) {
  border-radius: 6px;
}

:deep(.el-button) {
  border-radius: 6px;
}

:deep(.el-table) {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.el-table th) {
  background-color: #fafafa;
  color: #606266;
  font-weight: 600;
}

:deep(.el-table td) {
  border-bottom: 1px solid #f0f0f0;
}

:deep(.el-pagination) {
  justify-content: center;
}

:deep(.el-card) {
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

:deep(.el-card__header) {
  background-color: #fafafa;
  border-bottom: 1px solid #e4e7ed;
  padding: 16px 20px;
}
</style>

