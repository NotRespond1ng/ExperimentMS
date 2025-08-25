<template>
  <div class="experiment-data-analysis">
    <div class="page-header">
      <h2>实验数据分析</h2>
      <p>管理实验数据的分析、查询和可视化展示</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-select
          v-model="selectedBatchId"
          placeholder="筛选实验批次"
          clearable
          style="width: 150px; margin-right: 12px"
          @change="onBatchChange"
        >
          <el-option
            v-for="batch in batches"
            :key="batch.batch_id"
            :label="batch.batch_number"
            :value="batch.batch_id"
          />
        </el-select>
        
        <el-select
          v-model="selectedPersonId"
          placeholder="筛选人员"
          clearable
          style="width: 150px; margin-right: 12px"
          :disabled="!selectedBatchId"
          @change="onPersonChange"
        >
          <el-option
            v-for="person in personsWithData"
            :key="person.person_id"
            :label="`${person.person_name} (ID: ${person.person_id})`"
            :value="person.person_id"
          />
        </el-select>
      </div>
      
      <div class="toolbar-right">
        <el-button 
          type="primary" 
          @click="showUploadDialog = true"
          v-if="authStore.hasModulePermission('experiment_data_analysis', 'write')"
        >
          <el-icon><Upload /></el-icon>
          导入数据
        </el-button>
      </div>
    </div>

    <!-- 总平均值显示 -->
    <el-card v-if="experimentData" class="summary-card">
      <template #header>
        <div class="card-header">
          <span>数据统计</span>
        </div>
      </template>
      <div class="summary-stats">
        <div class="stat-item">
          <span class="stat-label">总平均MARD：</span>
          <el-tag type="primary" size="large" class="stat-value">
            {{ experimentData.avg_mard.toFixed(2) }}%
          </el-tag>
        </div>
        <div class="stat-item">
          <span class="stat-label">总平均PARD：</span>
          <el-tag type="success" size="large" class="stat-value">
            {{ experimentData.avg_pard.toFixed(2) }}%
          </el-tag>
        </div>
      </div>
    </el-card>
    
    <!-- 图表展示 -->
    <el-card class="chart-card">
      <template #header>
        <div class="card-header">
          <span>MARD/PARD 数据趋势图</span>
        </div>
      </template>
      <div class="chart-container">
        <div v-if="!experimentData" class="empty-state">
          <el-empty description="请选择批次和人员以查看数据" />
        </div>
        <div v-else-if="experimentData && experimentData.daily_data.length === 0" class="empty-state">
          <el-empty>
            <template #description>
              <div class="no-data-message">
                <h3>暂无实验数据</h3>
                <p>当前选择的人员还没有实验数据记录</p>
                <p>您可以通过"导入数据"功能上传Excel文件来添加数据</p>
              </div>
            </template>
          </el-empty>
        </div>
        <div v-else ref="chartRef" class="chart"></div>
      </div>
    </el-card>

    <!-- 上传对话框 -->
    <el-dialog
      v-model="showUploadDialog"
      title="导入实验数据"
      width="500px"
      @close="closeUploadDialog"
    >
      <div class="upload-content">
        <el-upload
          ref="uploadRef"
          class="upload-demo"
          drag
          :auto-upload="false"
          :show-file-list="false"
          accept=".xlsx,.xls"
          :on-change="handleFileSelect"
        >
          <el-icon class="el-icon--upload"><upload-filled /></el-icon>
          <div class="el-upload__text">
            拖拽Excel文件到此处，或<em>点击选择文件</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              支持 .xlsx 和 .xls 格式文件
            </div>
          </template>
        </el-upload>
        
        <div v-if="selectedFile" class="selected-file">
          <el-tag type="info">
            <el-icon><Document /></el-icon>
            {{ selectedFile.name }}
          </el-tag>
        </div>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="closeUploadDialog">取消</el-button>
          <el-button 
            type="primary" 
            @click="uploadFile" 
            :disabled="!selectedFile" 
            :loading="uploading"
          >
            {{ uploading ? '上传中...' : '上传' }}
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload, UploadFilled, Document } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { ApiService } from '../services/api'
import { useAuthStore } from '../stores/auth'

// 权限控制
const authStore = useAuthStore()

// 响应式数据
const batches = ref([])
const persons = ref([])
const selectedBatchId = ref<number | null>(null)
const selectedPersonId = ref<number | null>(null)
const experimentData = ref(null)
const chartRef = ref(null)
const chartInstance = ref(null)

// 上传相关
const showUploadDialog = ref(false)
const selectedFile = ref(null)
const uploading = ref(false)
const uploadRef = ref(null)

// 计算属性：只显示有数据的人员
const personsWithData = computed(() => {
  // 直接返回从API获取的有数据的人员列表
  return persons.value
})

// 获取批次列表（只获取有实验数据的批次）
const fetchBatches = async () => {
  try {
    batches.value = await ApiService.getExperimentDataBatchesWithData()
  } catch (error) {
    ElMessage.error('获取批次列表失败')
  }
}

// 获取人员列表（只获取有实验数据的人员）
const fetchPersons = async (batchId: number) => {
  try {
    persons.value = await ApiService.getExperimentDataPersonsWithData(batchId)
  } catch (error) {
    ElMessage.error('获取人员列表失败')
  }
}

// 获取实验数据
const fetchExperimentData = async (personId: number) => {
  try {
    experimentData.value = await ApiService.getExperimentData(undefined, personId)
    await nextTick()
    // 只有当有数据时才渲染图表
    if (experimentData.value && experimentData.value.daily_data.length > 0) {
      renderChart()
    }
  } catch (error) {
    ElMessage.error('获取实验数据失败')
    experimentData.value = null
  }
}

// 批次变化处理
const onBatchChange = () => {
  selectedPersonId.value = null
  persons.value = []
  experimentData.value = null
  if (selectedBatchId.value) {
    fetchPersons(selectedBatchId.value)
  }
}

// 人员变化处理
const onPersonChange = () => {
  if (selectedPersonId.value) {
    fetchExperimentData(selectedPersonId.value)
  } else {
    experimentData.value = null
  }
}

// 渲染图表
const renderChart = () => {
  if (!chartRef.value || !experimentData.value) return

  if (chartInstance.value) {
    chartInstance.value.dispose()
  }

  chartInstance.value = echarts.init(chartRef.value)

  // 确保x轴显示15天，即使某些天没有数据
  const allDays = Array.from({ length: 15 }, (_, i) => `第${i + 1}天`)
  
  // 创建一个映射，方便查找每天的数据
  const dataMap = new Map()
  experimentData.value.daily_data.forEach(item => {
    dataMap.set(item.experiment_day, item)
  })
  
  // 为15天生成完整的数据数组，没有数据的天数用null填充
  const mardData = allDays.map((_, index) => {
    const day = index + 1
    const dayData = dataMap.get(day)
    return dayData ? dayData.mard_value : null
  })
  
  const pardData = allDays.map((_, index) => {
    const day = index + 1
    const dayData = dataMap.get(day)
    return dayData ? dayData.pard_value : null
  })

  const option = {
    title: {
      text: 'MARD/PARD 数据趋势图',
      left: 'center'
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross'
      },
      formatter: function(params) {
        let result = params[0].name + '<br/>'
        params.forEach(param => {
          if (param.value !== null) {
            result += param.marker + param.seriesName + ': ' + param.value.toFixed(2) + '%<br/>'
          } else {
            result += param.marker + param.seriesName + ': 无数据<br/>'
          }
        })
        return result
      }
    },
    legend: {
      data: ['MARD', 'PARD'],
      top: 30
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: allDays,
      name: '实验天数',
      axisLabel: {
        interval: 0, // 显示所有标签
        rotate: 45   // 旋转45度避免重叠
      }
    },
    yAxis: {
      type: 'value',
      name: '数值(%)',
      axisLabel: {
        formatter: function(value) {
          return value.toFixed(2) + '%'
        }
      }
    },
    series: [
      {
        name: 'MARD',
        type: 'line',
        data: mardData,
        connectNulls: false, // 不连接空值点
        itemStyle: {
          color: '#5470c6'
        },
        lineStyle: {
          color: '#5470c6'
        },
        symbol: 'circle',
        symbolSize: 6
      },
      {
        name: 'PARD',
        type: 'line',
        data: pardData,
        connectNulls: false, // 不连接空值点
        itemStyle: {
          color: '#91cc75'
        },
        lineStyle: {
          color: '#91cc75'
        },
        symbol: 'circle',
        symbolSize: 6
      }
    ]
  }

  chartInstance.value.setOption(option)
}

// 文件选择处理
const handleFileSelect = (file) => {
  selectedFile.value = file.raw
}

// 上传文件
const uploadFile = async () => {
  if (!selectedFile.value) return

  uploading.value = true

  try {
    const response = await ApiService.uploadExperimentData(selectedFile.value)
    ElMessage.success(`${response.message}，共处理${response.processed_rows}条数据`)
    closeUploadDialog()
    // 刷新数据
    if (selectedPersonId.value) {
      fetchExperimentData(selectedPersonId.value)
    }
  } catch (error) {
    ElMessage.error(error.response?.data?.detail || '上传失败')
  } finally {
    uploading.value = false
  }
}

// 关闭上传对话框
const closeUploadDialog = () => {
  showUploadDialog.value = false
  selectedFile.value = null
  uploading.value = false
  if (uploadRef.value) {
    uploadRef.value.clearFiles()
  }
}

// 组件挂载
onMounted(() => {
  fetchBatches()
})
</script>

<style scoped>
.experiment-data-analysis {
  padding: 20px;
}

.page-header {
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0 0 8px 0;
  font-size: 24px;
  font-weight: 600;
  color: #303133;
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
  background: #f8f9fa;
  border-radius: 8px;
}

.toolbar-left {
  display: flex;
  align-items: center;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.summary-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.summary-stats {
  display: flex;
  gap: 40px;
  padding: 16px 0;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 12px;
}

.stat-label {
  font-weight: 500;
  color: #606266;
  font-size: 14px;
}

.stat-value {
  font-size: 16px;
  font-weight: 600;
}

.chart-card {
  margin-bottom: 20px;
}

.chart-container {
  height: 500px;
  position: relative;
}

.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.no-data-message {
  text-align: center;
}

.no-data-message h3 {
  margin: 0 0 12px 0;
  color: #606266;
  font-size: 18px;
  font-weight: 500;
}

.no-data-message p {
  margin: 6px 0;
  color: #909399;
  font-size: 14px;
  line-height: 1.5;
}

.no-data-message p:last-child {
  margin-top: 16px;
  color: #409eff;
  font-weight: 500;
}

.chart {
  width: 100%;
  height: 100%;
}

.upload-content {
  padding: 20px 0;
}

.upload-demo {
  width: 100%;
}

.selected-file {
  margin-top: 16px;
  text-align: center;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

/* Element Plus 组件样式调整 */
:deep(.el-card__header) {
  padding: 16px 20px;
  border-bottom: 1px solid #ebeef5;
}

:deep(.el-card__body) {
  padding: 20px;
}

:deep(.el-empty__description) {
  margin-top: 16px;
}

:deep(.el-upload-dragger) {
  width: 100%;
  height: 180px;
}

:deep(.el-icon--upload) {
  font-size: 48px;
  color: #c0c4cc;
  margin-bottom: 16px;
}

:deep(.el-upload__text) {
  color: #606266;
  font-size: 14px;
}

:deep(.el-upload__text em) {
  color: #409eff;
  font-style: normal;
}

:deep(.el-upload__tip) {
  font-size: 12px;
  color: #909399;
  margin-top: 8px;
}
</style>