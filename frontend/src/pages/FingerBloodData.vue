<template>
  <div class="finger-blood-data">
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
    <el-card>
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
      >
        <el-table-column label="序号" width="80" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <!-- 隐藏原始finger_blood_file_id列，但保留数据用于后端传递 -->
        <!-- <el-table-column prop="finger_blood_file_id" label="数据ID" width="100" /> -->
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
        <el-table-column label="操作" width="180" fixed="right">
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
      width="500px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="120px"
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
                  :rules="dataRules.collection_time"
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
                  :rules="dataRules.blood_glucose_value"
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

import { getBatchNumber, getPersonName, formatDateTime } from '@/utils/formatters'
import { exportToExcel, exportMultipleSheetsToExcel } from '@/utils/excel'

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

// 根据指尖血数据中实际存在的批次进行筛选
const availableBatchesForFilter = computed(() => {
  const batchIds = [...new Set(dataStore.fingerBloodData.map(data => data.batch_id))]
  return dataStore.batches.filter(batch => batchIds.includes(batch.batch_id))
})

// 根据指尖血数据中实际存在的人员进行筛选
const availablePersonsForFilter = computed(() => {
  const personIds = [...new Set(dataStore.fingerBloodData.map(data => data.person_id))]
  return dataStore.persons.filter(person => personIds.includes(person.person_id))
})

// 根据选择的批次过滤人员
const filteredPersonsForFilter = computed(() => {
  if (!filterBatchId.value) {
    return availablePersonsForFilter.value
  }
  return availablePersonsForFilter.value.filter(person => person.batch_id === filterBatchId.value)
})

// 监听批次选择变化，清空人员过滤
watch(() => filterBatchId.value, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId) {
    filterPersonId.value = undefined
    resetPagination()
  }
})
const dateRange = ref<[string, string] | null>(null)
const dialogVisible = ref(false)
const batchDialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()
const batchFormRef = ref<FormInstance>()

// 分页相关
const { currentPage, pageSize, total, handleSizeChange, handleCurrentChange, resetPagination } = usePagination()
const pageSizes = [10, 20, 50, 100]

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

const rules = {
  batch_id: [
    { required: true, message: '请选择关联批次', trigger: 'change' }
  ],
  person_id: [
    { required: true, message: '请选择关联人员', trigger: 'change' }
  ],
  collection_time: [
    { required: true, message: '请选择采集时间', trigger: 'change' }
  ],
  blood_glucose_value: [
    { required: true, message: '请输入血糖值', trigger: 'blur' },
    { type: 'number', min: 0, max: 30, message: '血糖值应在0-30之间', trigger: 'blur' }
  ]
}

const batchRules = {
  batch_id: [
    { required: true, message: '请选择关联批次', trigger: 'change' }
  ],
  person_id: [
    { required: true, message: '请选择关联人员', trigger: 'change' }
  ]
}

const dataRules = {
  collection_time: [
    { required: true, message: '请选择采集时间', trigger: 'change' }
  ],
  blood_glucose_value: [
    { required: true, message: '请输入血糖值', trigger: 'blur' },
    { type: 'number', min: 0, max: 30, message: '血糖值应在0-30之间', trigger: 'blur' }
  ]
}

// 根据选择的批次过滤人员（表单）
const filteredPersonsForForm = computed(() => {
  if (!form.batch_id) {
    return []
  }
  return dataStore.persons.filter(person => person.batch_id === form.batch_id)
})

// 根据选择的批次过滤人员（批量录入表单）
const filteredPersonsForBatchForm = computed(() => {
  if (!batchForm.batch_id) {
    return []
  }
  return dataStore.persons.filter(person => person.batch_id === batchForm.batch_id)
})

// 监听批次选择变化，清空人员选择（表单）
watch(() => form.batch_id, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId) {
    form.person_id = undefined
  }
})

// 监听批量录入表单中批次选择变化，清空人员选择
watch(() => batchForm.batch_id, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId) {
    batchForm.person_id = undefined
  }
})



// 过滤后的数据列表 - 显示全部数据，只在有筛选条件时才过滤
const filteredData = computed(() => {
  let result = dataStore.fingerBloodData
  
  // 只有在明确设置了筛选条件时才进行过滤
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
  
  // 按指尖血数据ID倒序排列，最新创建的在前面
  return result.sort((a, b) => b.finger_blood_file_id - a.finger_blood_file_id)
})

// 当前页数据
const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// 更新总数据量
watch(() => filteredData.value.length, (newTotal) => {
  total.value = newTotal
}, { immediate: true })

// 图表数据 - 默认展示最新批次下的多个人员数据，时间跨度15天
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

// 图表配置
const chartOption = computed(() => {
  const data = chartData.value
  
  if (data.length === 0) {
    return {
      title: {
        text: '暂无数据',
        left: 'center',
        top: 'center',
        textStyle: {
          color: '#999',
          fontSize: 16
        }
      }
    }
  }
  
  // 按人员分组数据
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
    smooth: true,
    symbol: 'circle',
    symbolSize: 6,
    lineStyle: {
      width: 2
    }
  }))
  
  // 计算时间范围 - 确保显示完整的15天跨度
  let minTime, maxTime
  if (data.length > 0) {
    const times = data.map(item => new Date(item.collection_time).getTime())
    const dataMinTime = Math.min(...times)
    const dataMaxTime = Math.max(...times)
    
    // 如果没有筛选条件，强制显示15天跨度
    if (!filterBatchId.value && !filterPersonId.value && (!dateRange.value || (!dateRange.value[0] && !dateRange.value[1]))) {
      maxTime = dataMaxTime
      minTime = dataMaxTime - (15 * 24 * 60 * 60 * 1000) // 15天前
    } else {
      minTime = dataMinTime
      maxTime = dataMaxTime
    }
  }
  
  return {
    title: {
      text: '血糖值变化趋势（15天跨度）',
      left: 'center',
      textStyle: {
        fontSize: 16,
        fontWeight: 'bold'
      }
    },
    tooltip: {
      trigger: 'axis',
      formatter: (params: any) => {
        let result = `<div style="font-weight: bold;">${params[0].axisValue}</div>`
        params.forEach((param: any) => {
          const level = getGlucoseLevel(param.value[1])
          result += `<div style="margin-top: 4px;">
            <span style="display: inline-block; width: 10px; height: 10px; border-radius: 50%; background-color: ${param.color}; margin-right: 8px;"></span>
            ${param.seriesName}: <strong>${param.value[1]} mmol/L</strong>
            <span style="color: ${level.type === 'success' ? '#67C23A' : level.type === 'warning' ? '#E6A23C' : '#F56C6C'}; margin-left: 8px;">(${level.label})</span>
          </div>`
        })
        return result
      }
    },
    legend: {
      top: 30,
      data: Object.keys(groupedData)
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '15%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'time',
      boundaryGap: false,
      min: minTime,
      max: maxTime,
      axisLabel: {
        formatter: '{MM}-{dd} {HH}:{mm}'
      }
    },
    yAxis: {
      type: 'value',
      name: '血糖值 (mmol/L)',
      min: 0,
      max: 15,
      axisLabel: {
        formatter: '{value}'
      },
      splitLine: {
        lineStyle: {
          type: 'dashed'
        }
      }
    },
    dataZoom: [
      {
        type: 'slider',
        show: true,
        xAxisIndex: [0],
        start: 0,
        end: 100
      }
    ],
    series,
    // 添加正常范围标识线
    markLine: {
      data: [
        {
          yAxis: 3.9,
          lineStyle: { color: '#67C23A', type: 'dashed' },
          label: { formatter: '正常下限 3.9' }
        },
        {
          yAxis: 6.1,
          lineStyle: { color: '#67C23A', type: 'dashed' },
          label: { formatter: '正常上限 6.1' }
        }
      ]
    }
  }
})

// 获取血糖水平
const getGlucoseLevel = (value: number) => {
  if (value < 3.9) {
    return { type: 'danger', label: '偏低' }
  } else if (value <= 6.1) {
    return { type: 'success', label: '正常' }
  } else if (value <= 7.8) {
    return { type: 'warning', label: '偏高' }
  } else {
    return { type: 'danger', label: '过高' }
  }
}

// 获取人员性别显示
const getGenderDisplay = (gender: string) => {
  switch (gender) {
    case 'Male':
      return '男'
    case 'Female':
      return '女'
    default:
      return '其他'
  }
}





// 筛选处理
const handleFilter = () => {
  // 筛选逻辑已在computed中处理
  resetPagination()
}

// 切换图表显示
const toggleChartView = () => {
  showChart.value = !showChart.value
}

// 新建数据
const handleAdd = () => {
  isEdit.value = false
  dialogVisible.value = true
  resetForm()
}

// 批量录入数据
const handleBatchAdd = () => {
  resetBatchForm()
  batchDialogVisible.value = true
}

// 添加数据项到批量录入
const addDataItem = () => {
  batchForm.dataList.push({
    collection_time: '',
    blood_glucose_value: undefined
  })
}

// 删除数据项
const removeDataItem = (index: number) => {
  batchForm.dataList.splice(index, 1)
}

// 重置批量录入表单
const resetBatchForm = () => {
  Object.assign(batchForm, {
    batch_id: undefined,
    person_id: undefined,
    dataList: []
  })
  if (batchFormRef.value) {
    batchFormRef.value.resetFields()
  }
}

// 批量提交数据
const handleBatchSubmit = async () => {
  if (!batchFormRef.value) return
  
  if (batchForm.dataList.length === 0) {
    ElMessage.warning('请至少添加一条数据')
    return
  }
  
  await batchFormRef.value.validate(async (valid) => {
    if (valid) {
      try {
        loading.value = true
        
        // 批量添加数据
        for (const dataItem of batchForm.dataList) {
          if (dataItem.collection_time && dataItem.blood_glucose_value !== undefined) {
            await dataStore.addFingerBloodData({
              batch_id: batchForm.batch_id!,
              person_id: batchForm.person_id!,
              collection_time: dataItem.collection_time,
              blood_glucose_value: dataItem.blood_glucose_value
            })
          }
        }
        
        ElMessage.success('批量录入成功')
        batchDialogVisible.value = false
        resetBatchForm()
      } catch (error) {
        console.error('Batch submit failed:', error)
        ElMessage.error('批量录入失败')
      } finally {
        loading.value = false
      }
    }
  })
}

// 编辑数据
const handleEdit = (row: FingerBloodData) => {
  isEdit.value = true
  // 先设置batch_id，确保filteredPersonsForForm能正确计算
  form.batch_id = row.batch_id
  // 使用nextTick确保DOM更新后再设置其他字段
  nextTick(() => {
    Object.assign(form, row)
    dialogVisible.value = true
  })
}

// 删除数据
const handleDelete = async (row: FingerBloodData) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除这条血糖数据吗？`,
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await dataStore.deleteFingerBloodData(row.finger_blood_file_id)
    ElMessage.success('删除成功')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Delete failed:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 导出数据
const handleExport = () => {
  try {
    exportLoading.value = true
    
    // 按人员分组数据
    const groupedData = filteredData.value.reduce((acc, item) => {
      // 获取纯姓名，不包含ID信息
      const person = dataStore.persons.find(p => p.person_id === item.person_id)
      const personName = person?.person_name || `人员${item.person_id}`
      
      if (!acc[personName]) {
        acc[personName] = []
      }
      
      // 解析时间并格式化
      const dateTime = new Date(item.collection_time)
      const year = dateTime.getFullYear()
      const month = dateTime.getMonth() + 1
      const day = dateTime.getDate()
      const hours = String(dateTime.getHours()).padStart(2, '0')
      const minutes = String(dateTime.getMinutes()).padStart(2, '0')
      
      // 格式化日期为 2025.8.8 格式
      const dateStr = `${year}.${month}.${day}`
      // 格式化时间为 15:46 格式
      const timeStr = `${hours}:${minutes}`
      
      acc[personName].push({
        '日期': dateStr,
        '时间': timeStr,
        '雅培': '', // 空列
        '指尖血': item.blood_glucose_value
      })
      return acc
    }, {} as Record<string, Array<{ '日期': string; '时间': string; '雅培': string; '指尖血': number }>>)

    // 对每个人员的数据按时间排序（最早的在前面）
    Object.keys(groupedData).forEach(personName => {
      groupedData[personName].sort((a, b) => {
        // 重新构建完整的时间字符串进行比较
        const dateTimeA = `${a['日期'].replace(/\./g, '-')} ${a['时间']}:00`
        const dateTimeB = `${b['日期'].replace(/\./g, '-')} ${b['时间']}:00`
        return new Date(dateTimeA).getTime() - new Date(dateTimeB).getTime()
      })
    })

    // 生成文件名
    const filters = []
    if (filterBatchId.value) {
      const batch = dataStore.batches.find(b => b.batch_id === filterBatchId.value)
      if (batch) filters.push(`批次${batch.batch_number}`)
    }
    if (filterPersonId.value) {
      const person = dataStore.persons.find(p => p.person_id === filterPersonId.value)
      if (person) filters.push(`人员${person.person_name}`)
    }
    if (dateRange.value && dateRange.value[0] && dateRange.value[1]) {
      filters.push(`${dateRange.value[0].slice(0, 10)}至${dateRange.value[1].slice(0, 10)}`)
    }
    
    const filename = filters.length > 0 
      ? `指尖血数据导出_${filters.join('_')}`
      : '指尖血数据导出'
    
    // 准备多个sheet的数据，确保sheet名称正确
    const sheets = Object.entries(groupedData).map(([personName, data]) => ({
      data: data,
      name: personName.replace(/[\\\/\[\]:*?"<>|]/g, '_') // 清理sheet名称中的非法字符
    }))
    
    // 使用多sheet导出函数
    exportMultipleSheetsToExcel(sheets, filename)
    
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('Export failed:', error)
    ElMessage.error('导出失败，请重试')
  } finally {
    exportLoading.value = false
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (isEdit.value) {
          // 编辑
          await dataStore.updateFingerBloodData(form.finger_blood_file_id, {
            batch_id: form.batch_id!,
            person_id: form.person_id!,
            collection_time: form.collection_time,
            blood_glucose_value: form.blood_glucose_value!
          })
          ElMessage.success('更新成功')
        } else {
          // 新建
          await dataStore.addFingerBloodData({
            batch_id: form.batch_id!,
            person_id: form.person_id!,
            collection_time: form.collection_time,
            blood_glucose_value: form.blood_glucose_value!
          })
          ElMessage.success('录入成功')
        }
        
        dialogVisible.value = false
        resetForm()
      } catch (error) {
        console.error('Submit failed:', error)
        ElMessage.error(isEdit.value ? '更新失败' : '录入失败')
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
    finger_blood_file_id: 0,
    batch_id: undefined,
    person_id: undefined,
    collection_time: '',
    blood_glucose_value: undefined
  })
}

// 监听筛选条件变化，更新图表
watch([filterBatchId, filterPersonId, dateRange], () => {
  chartLoading.value = true
  setTimeout(() => {
    chartLoading.value = false
  }, 500)
})
</script>

<style scoped>
.finger-blood-data {
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
</style>