<template>
  <div class="sensor-detail-management">
    <div class="page-header">
      <h2>传感器详细信息管理</h2>
      <p>管理传感器的详细测试数据和属性信息</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索测试编号或探针编号"
          style="width: 250px; margin-right: 12px"
          clearable
          @input="handleSearch"
          size="large"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
      </div>
      
      <div class="toolbar-right">
        <el-button @click="handleExport" size="large">
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('sensor_details', 'write')"
          type="warning" 
          @click="handleImportExcel"
          size="large"
        >
          <el-icon><Upload /></el-icon>
          导入Excel
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('sensor_details', 'write')"
          type="success" 
          @click="handleBatchAdd"
          size="large"
        >
          <el-icon><Plus /></el-icon>
          批量添加
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('sensor_details', 'write')"
          type="primary" 
          @click="handleAdd"
          size="large"
        >
          <el-icon><Plus /></el-icon>
          添加传感器
        </el-button>
      </div>
    </div>
    
    <!-- 传感器详细信息列表 -->
    <el-card class="data-card">
      <template #header>
        <div class="card-header">
          <span>传感器详细信息列表</span>
          <span class="data-count">共 {{ filteredSensorDetails.length }} 条记录</span>
        </div>
      </template>
      
      <el-table
        :data="paginatedSensorDetails"
        stripe
        style="width: 100%"
        v-loading="loading"
        :row-style="{ height: '55px' }"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column label="序号" width="80" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <!-- 隐藏原始sensor_detail_id列，但保留数据用于后端传递 -->
        <!-- <el-table-column prop="sensor_detail_id" label="ID" width="80" /> -->
        <el-table-column prop="sterilization_date" label="灭菌日期" width="120">
          <template #default="{ row }">
            {{ row.sterilization_date ? formatDateToDots(row.sterilization_date) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="test_number" label="传感器测试编号" width="160" />
        <el-table-column prop="probe_number" label="探针编号" width="140" />
        <el-table-column prop="value_0" label="0.00" width="100">
          <template #default="{ row }">
            {{ (row.value_0 !== null && row.value_0 !== undefined) ? Number(row.value_0).toFixed(2) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="value_2" label="2.00" width="100">
          <template #default="{ row }">
            {{ (row.value_2 !== null && row.value_2 !== undefined) ? Number(row.value_2).toFixed(2) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="value_5" label="5.00" width="100">
          <template #default="{ row }">
            {{ (row.value_5 !== null && row.value_5 !== undefined) ? Number(row.value_5).toFixed(2) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="value_25" label="25.00" width="100">
          <template #default="{ row }">
            {{ (row.value_25 !== null && row.value_25 !== undefined) ? Number(row.value_25).toFixed(2) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="sensitivity" label="初始灵敏度" width="120">
          <template #default="{ row }">
            {{ row.sensitivity ? row.sensitivity.toFixed(6) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="r_value" label="R" width="120">
          <template #default="{ row }">
            <el-tag :type="getRValueType(row.r_value)" v-if="row.r_value">
              {{ row.r_value.toFixed(4) }}
            </el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="destination" label="去向" width="120">
          <template #default="{ row }">
            <span v-if="row.destination" class="destination-text">{{ row.destination }}</span>
            <span v-else class="no-data">-</span>
          </template>
        </el-table-column>
        <el-table-column prop="remarks" label="备注" width="120" show-overflow-tooltip>
          <template #default="{ row }">
            <span v-if="row.remarks" class="remarks-text">{{ row.remarks }}</span>
            <span v-else class="no-data">-</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #header>
            <div style="display: flex; align-items: center; gap: 8px;">
              <span>操作</span>
              <el-button
                v-if="selectedRows.length > 0"
                type="danger"
                size="small"
                @click="handleBatchDelete"
                :disabled="!authStore.hasModulePermission('sensor_details', 'delete')"
              >
                批量删除({{ selectedRows.length }})
              </el-button>
            </div>
          </template>
          <template #default="{ row }">
            <el-button
              :disabled="!authStore.hasModulePermission('sensor_details', 'write')"
              type="primary"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('sensor_details', 'delete')"
              type="danger"
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
      :title="isEdit ? '编辑传感器详细信息' : '添加传感器详细信息'"
      width="1000px"
      @close="resetForm"
      top="5vh"
    >
      <div class="unified-form-layout">
        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
        >
          <el-row :gutter="24">
            <el-col :span="8">
              <el-form-item label="传感器测试编号" prop="test_number">
                <el-input
                  v-model="form.test_number"
                  placeholder="请输入测试编号"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="探针编号" prop="probe_number">
                <el-input
                  v-model="form.probe_number"
                  placeholder="请输入探针编号"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="灭菌日期">
                <el-date-picker
                  v-model="form.sterilization_date"
                  type="date"
                  placeholder="选择日期"
                  style="width: 100%"
                  format="YYYY-MM-DD"
                  value-format="YYYY-MM-DD"
                  :locale="zhCn"
                />
              </el-form-item>
            </el-col>
          </el-row>
          
          <el-row :gutter="24">
            <el-col :span="6">
              <el-form-item label="测试值 (0.00)">
                <el-input-number
                  v-model="form.value_0"
                  :precision="4"
                  :step="0.01"
                  style="width: 100%"
                  placeholder="0.00"
                />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="测试值 (2.00)">
                <el-input-number
                  v-model="form.value_2"
                  :precision="4"
                  :step="0.01"
                  style="width: 100%"
                  placeholder="2.00"
                />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="测试值 (5.00)">
                <el-input-number
                  v-model="form.value_5"
                  :precision="4"
                  :step="0.01"
                  style="width: 100%"
                  placeholder="5.00"
                />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="测试值 (25.00)">
                <el-input-number
                  v-model="form.value_25"
                  :precision="4"
                  :step="0.01"
                  style="width: 100%"
                  placeholder="25.00"
                />
              </el-form-item>
            </el-col>
          </el-row>
          
          <el-row :gutter="24">
            <el-col :span="8">
              <el-form-item label="初始灵敏度">
                <el-input-number
                  v-model="form.sensitivity"
                  :precision="6"
                  :step="0.01"
                  style="width: 100%"
                  placeholder="灵敏度"
                />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="相关系数 R">
                <el-input-number
                  v-model="form.r_value"
                  :precision="10"
                  :step="0.0001"
                  :min="0"
                  :max="1"
                  style="width: 100%"
                  placeholder="相关系数"
                />
              </el-form-item>
            </el-col>
             <el-col :span="8">
              <el-form-item label="去向">
                <el-input
                  v-model="form.destination"
                  placeholder="请输入去向"
                />
              </el-form-item>
            </el-col>
          </el-row>
           <el-row>
            <el-col :span="24">
              <el-form-item label="备注">
                <el-input
                  v-model="form.remarks"
                  type="textarea"
                  :rows="3"
                  placeholder="请输入备注信息"
                  maxlength="200"
                  show-word-limit
                />
              </el-form-item>
            </el-col>
          </el-row>
        </el-form>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false" size="large">取消</el-button>
          <el-button type="primary" @click="handleSubmit" size="large">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 批量添加对话框 -->
    <el-dialog
      v-model="batchDialogVisible"
      title="批量添加传感器详细信息"
      width="1200px"
      @close="resetBatchForm"
      top="5vh"
    >
      <div class="batch-form-header">
        <el-button type="primary" @click="addBatchItem">
          <el-icon><Plus /></el-icon>
          添加一行
        </el-button>
        <span class="batch-tip">提示：测试编号和探针编号为必填项，其他为选填。</span>
      </div>
      
      <div class="batch-form-container">
        <div class="unified-form-layout batch-item" v-for="(item, index) in batchForm.items" :key="index">
          <div class="batch-item-header">
            <span class="item-number">第 {{ index + 1 }} 条记录</span>
            <el-button 
              type="danger" 
              plain
              @click="removeBatchItem(index)"
              :disabled="batchForm.items.length <= 1"
            >
              <el-icon><Delete /></el-icon>
              删除此条
            </el-button>
          </div>
          
          <el-form :model="item" label-position="top">
            <el-row :gutter="20">
              <el-col :span="8">
                <el-form-item label="传感器测试编号" required>
                  <el-input
                    v-model="item.test_number"
                    placeholder="请输入测试编号"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="探针编号" required>
                  <el-input
                    v-model="item.probe_number"
                    placeholder="请输入探针编号"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="灭菌日期">
                  <el-date-picker
                    v-model="item.sterilization_date"
                    type="date"
                    placeholder="选择日期"
                    style="width: 100%"
                    format="YYYY-MM-DD"
                    value-format="YYYY-MM-DD"
                    :locale="zhCn"
                  />
                </el-form-item>
              </el-col>
            </el-row>
            
            <el-row :gutter="20">
              <el-col :span="6">
                <el-form-item label="测试值 (0.00)">
                  <el-input-number
                    v-model="item.value_0"
                    :precision="4"
                    :step="0.01"
                    style="width: 100%"
                    placeholder="0.00"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="测试值 (2.00)">
                  <el-input-number
                    v-model="item.value_2"
                    :precision="4"
                    :step="0.01"
                    style="width: 100%"
                    placeholder="2.00"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="测试值 (5.00)">
                  <el-input-number
                    v-model="item.value_5"
                    :precision="4"
                    :step="0.01"
                    style="width: 100%"
                    placeholder="5.00"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="6">
                <el-form-item label="测试值 (25.00)">
                  <el-input-number
                    v-model="item.value_25"
                    :precision="4"
                    :step="0.01"
                    style="width: 100%"
                    placeholder="25.00"
                  />
                </el-form-item>
              </el-col>
            </el-row>
            
            <el-row :gutter="20">
              <el-col :span="8">
                <el-form-item label="初始灵敏度">
                  <el-input-number
                    v-model="item.sensitivity"
                    :precision="6"
                    :step="0.01"
                    style="width: 100%"
                    placeholder="灵敏度"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="相关系数R">
                  <el-input-number
                    v-model="item.r_value"
                    :precision="10"
                    :step="0.0001"
                    :min="0"
                    :max="1"
                    style="width: 100%"
                    placeholder="相关系数"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="8">
                <el-form-item label="去向">
                  <el-input
                    v-model="item.destination"
                    placeholder="请输入去向"
                  />
                </el-form-item>
              </el-col>
            </el-row>
             <el-row>
                <el-col :span="24">
                  <el-form-item label="备注">
                    <el-input
                      v-model="item.remarks"
                      placeholder="请输入备注"
                      maxlength="100"
                    />
                  </el-form-item>
                </el-col>
            </el-row>
          </el-form>
        </div>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="batchDialogVisible = false" size="large">取消</el-button>
          <el-button type="primary" @click="handleBatchSubmit" :loading="loading" size="large">
            提交添加
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Download, Plus, Upload, Delete } from '@element-plus/icons-vue'
import { ApiService, type SensorDetail } from '../services/api'
import { useAuthStore } from '../stores/auth'
import { usePagination } from '../composables/usePagination'
import { formatDate } from '../utils/formatters'
import { exportToExcel, importFromExcel, validateSensorDetailDataByPosition } from '../utils/excel'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

// 自定义日期格式化函数，将日期格式化为 YYYY.MM.DD 格式
const formatDateToDots = (date: string | Date): string => {
  if (!date) return ''
  const dateObj = new Date(date)
  
  const year = dateObj.getFullYear()
  const month = String(dateObj.getMonth() + 1).padStart(2, '0')
  const day = String(dateObj.getDate()).padStart(2, '0')
  
  return `${year}.${month}.${day}`
}

const authStore = useAuthStore()

// 数据状态
const loading = ref(false)
const sensorDetails = ref<SensorDetail[]>([])
const searchKeyword = ref('')
const selectedRows = ref<SensorDetail[]>([])

// 筛选后的数据
const filteredSensorDetails = computed(() => {
  let result = sensorDetails.value
  
  if (searchKeyword.value && searchKeyword.value.trim() !== '') {
    const keyword = searchKeyword.value.trim().toLowerCase()
    result = result.filter(item => 
      item.test_number.toLowerCase().includes(keyword) ||
      item.probe_number.toLowerCase().includes(keyword)
    )
  }
  
  return result.sort((a, b) => b.sensor_detail_id - a.sensor_detail_id);
})

// 对话框状态
const dialogVisible = ref(false)
const batchDialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref()

// 表单数据
const getInitialFormState = (): Partial<SensorDetail> => ({
  test_number: '',
  probe_number: '',
  sterilization_date: '',
  value_0: undefined,
  value_2: undefined,
  value_5: undefined,
  value_25: undefined,
  sensitivity: undefined,
  r_value: undefined,
  destination: '',
  remarks: ''
})

const form = ref<Partial<SensorDetail>>(getInitialFormState())

// 批量添加表单数据
const batchForm = ref<{ items: Array<Partial<SensorDetail>> }>({
  items: []
})

// 表单验证规则
const rules = {
  test_number: [
    { required: true, message: '请输入测试编号', trigger: 'blur' },
    { max: 100, message: '测试编号长度不能超过100个字符', trigger: 'blur' }
  ],
  probe_number: [
    { required: true, message: '请输入探针编号', trigger: 'blur' },
    { max: 100, message: '探针编号长度不能超过100个字符', trigger: 'blur' }
  ]
}

// 分页
const {
  currentPage,
  pageSize,
  pageSizes,
  total,
  paginatedData: paginatedSensorDetails,
  handleSizeChange,
  handleCurrentChange
} = usePagination(filteredSensorDetails)

// 方法
const loadSensorDetails = async () => {
  try {
    loading.value = true
    sensorDetails.value = await ApiService.getSensorDetails()
  } catch (error) {
    console.error('加载传感器详细信息失败:', error)
    ElMessage.error('加载传感器详细信息失败')
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  currentPage.value = 1
}

const handleAdd = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

const handleBatchAdd = () => {
  resetBatchForm()
  batchDialogVisible.value = true
}

const addBatchItem = () => {
  batchForm.value.items.push(getInitialFormState())
}

const removeBatchItem = (index: number) => {
  if (batchForm.value.items.length > 1) {
    batchForm.value.items.splice(index, 1)
  } else {
    ElMessage.warning('至少需要保留一条记录')
  }
}

const resetBatchForm = () => {
  batchForm.value.items = [getInitialFormState()]
}

const handleBatchSubmit = async () => {
  try {
    const validItems = batchForm.value.items.filter(item => 
      item.test_number && item.probe_number
    )
    
    if (validItems.length === 0) {
      ElMessage.warning('请至少填写一条有效的传感器信息 (测试编号和探针编号为必填项)')
      return
    }
    
    loading.value = true
    
    // 使用 Promise.all 并行处理请求以提高效率
    await Promise.all(validItems.map(item => 
        ApiService.createSensorDetail(item as Omit<SensorDetail, 'sensor_detail_id' | 'created_time'>)
    ));
    
    ElMessage.success(`成功添加 ${validItems.length} 条传感器详细信息`)
    batchDialogVisible.value = false
    await loadSensorDetails()
  } catch (error) {
    console.error('批量添加传感器详细信息失败:', error)
    ElMessage.error('批量添加失败，请检查数据或联系管理员')
  } finally {
    loading.value = false
  }
}

const handleEdit = (row: SensorDetail) => {
  isEdit.value = true
  form.value = { ...row }
  dialogVisible.value = true
}

const handleDelete = async (row: SensorDetail) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除传感器 <strong>${row.test_number} / ${row.probe_number}</strong> 吗？此操作不可撤销。`,
      '确认删除',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning',
        dangerouslyUseHTMLString: true,
      }
    )
    
    await ApiService.deleteSensorDetail(row.sensor_detail_id)
    ElMessage.success('删除成功')
    await loadSensorDetails()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除传感器详细信息失败:', error)
      
      let errorMessage = '删除失败'
      
      // 检查是否是HTTP错误响应
      if (error && typeof error === 'object') {
        // 优先从response.data中获取错误信息
        if (error.response?.data?.detail) {
          errorMessage = error.response.data.detail
        } else if (error.response?.data?.message) {
          errorMessage = error.response.data.message
        } else if (error.message) {
          // 如果没有详细错误信息，显示HTTP状态码和错误类型
          const status = error.status || error.response?.status
          if (status) {
            errorMessage = `删除失败 (HTTP ${status}): ${error.message}`
          } else {
            errorMessage = `删除失败: ${error.message}`
          }
        } else if (error.status || error.response?.status) {
          // 只有状态码的情况
          const status = error.status || error.response?.status
          errorMessage = `删除失败 (HTTP ${status})`
        }
      }
      
      ElMessage.error(errorMessage)
    }
  }
}

const handleSelectionChange = (selection: SensorDetail[]) => {
  selectedRows.value = selection
}

const handleBatchDelete = async () => {
  if (selectedRows.value.length === 0) {
    ElMessage.warning('请先选择要删除的传感器记录')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 <strong>${selectedRows.value.length}</strong> 条传感器记录吗？此操作不可撤销。`,
      '确认批量删除',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning',
        dangerouslyUseHTMLString: true,
      }
    )

    const ids = selectedRows.value.map(row => row.sensor_detail_id)
    const result = await ApiService.batchDeleteSensorDetails(ids)
    
    ElMessage.success(`批量删除成功：删除了 ${result.deleted_count} 条记录`)
    selectedRows.value = []
    await loadSensorDetails()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('批量删除传感器详细信息失败:', error)
      
      let errorMessage = '批量删除失败'
      
      // 检查是否是HTTP错误响应
      if (error && typeof error === 'object') {
        // 优先从response.data中获取错误信息
        if (error.response?.data?.detail) {
          errorMessage = error.response.data.detail
        } else if (error.response?.data?.message) {
          errorMessage = error.response.data.message
        } else if (error.message) {
          // 如果没有详细错误信息，显示HTTP状态码和错误类型
          const status = error.status || error.response?.status
          if (status) {
            errorMessage = `批量删除失败 (HTTP ${status}): ${error.message}`
          } else {
            errorMessage = `批量删除失败: ${error.message}`
          }
        } else if (error.status || error.response?.status) {
          // 只有状态码的情况
          const status = error.status || error.response?.status
          errorMessage = `批量删除失败 (HTTP ${status})`
        }
      }
      
      ElMessage.error(errorMessage)
    }
  }
}

const handleSubmit = async () => {
  try {
    const isValid = await formRef.value?.validate()
    if (!isValid) return
    
    if (isEdit.value) {
      await ApiService.updateSensorDetail(form.value.sensor_detail_id!, form.value)
      ElMessage.success('更新成功')
    } else {
      await ApiService.createSensorDetail(form.value as Omit<SensorDetail, 'sensor_detail_id' | 'created_time'>)
      ElMessage.success('添加成功')
    }
    
    dialogVisible.value = false
    await loadSensorDetails()
  } catch (error: any) {
    console.error('保存传感器详细信息失败:', error)
    
    let errorMessage = '保存失败'
    
    // 检查是否是HTTP错误响应
    if (error && typeof error === 'object') {
      // 优先从response.data中获取错误信息
      if (error.response?.data?.detail) {
        errorMessage = error.response.data.detail
      } else if (error.response?.data?.message) {
        errorMessage = error.response.data.message
      } else if (error.message) {
        // 如果没有详细错误信息，显示HTTP状态码和错误类型
        const status = error.status || error.response?.status
        if (status) {
          errorMessage = `保存失败 (HTTP ${status}): ${error.message}`
        } else {
          errorMessage = `保存失败: ${error.message}`
        }
      } else if (error.status || error.response?.status) {
        // 只有状态码的情况
        const status = error.status || error.response?.status
        errorMessage = `保存失败 (HTTP ${status})`
      }
    }
    
    ElMessage.error(errorMessage)
  }
}

const resetForm = () => {
  form.value = getInitialFormState()
  formRef.value?.clearValidate()
}

const handleExport = () => {
  const exportData = sensorDetails.value.map(item => ({
    '灭菌日期': item.sterilization_date ? formatDateToDots(item.sterilization_date) : '',
    '传感器测试编号': item.test_number,
    '探针编号': item.probe_number,
    '0.00': (item.value_0 !== null && item.value_0 !== undefined) ? Number(item.value_0) : '',
    '2.00': (item.value_2 !== null && item.value_2 !== undefined) ? Number(item.value_2) : '',
    '5.00': (item.value_5 !== null && item.value_5 !== undefined) ? Number(item.value_5) : '',
    '25.00': (item.value_25 !== null && item.value_25 !== undefined) ? Number(item.value_25) : '',
    '初始灵敏度': (item.sensitivity !== null && item.sensitivity !== undefined) ? Number(item.sensitivity) : '',
    'R': (item.r_value !== null && item.r_value !== undefined) ? Number(item.r_value) : '',
    '去向': item.destination || '',
    '备注': item.remarks || ''
  }))
  
  const success = exportToExcel(exportData, '传感器详细信息', '传感器详细信息')
  if (success) {
    ElMessage.success('导出成功')
  } else {
    ElMessage.error('导出失败')
  }
}

// Excel导入相关方法
const handleImportExcel = () => {
  // 创建文件输入元素
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = '.xlsx,.xls'
  input.style.display = 'none'
  
  input.onchange = async (event) => {
    const file = (event.target as HTMLInputElement).files?.[0]
    if (!file) return
    
    try {
      loading.value = true
      ElMessage.info('正在解析Excel文件...')
      
      // 解析Excel文件（使用列位置模式）
      const rawData = await importFromExcel(file, undefined, true)
      
      if (rawData.length === 0) {
        ElMessage.warning('Excel文件中没有有效数据')
        return
      }
      
      // 验证数据（使用列位置验证）
      const { valid, invalid } = validateSensorDetailDataByPosition(rawData)
      
      if (invalid.length > 0) {
        // 显示验证错误
        const errorMessages = invalid.map(item => 
          `第${item._rowIndex}行: ${item._errors.join(', ')}`
        ).slice(0, 5) // 只显示前5个错误
        
        const moreErrors = invalid.length > 5 ? `\n...还有${invalid.length - 5}个错误` : ''
        
        ElMessageBox.alert(
          `发现${invalid.length}条无效数据:\n${errorMessages.join('\n')}${moreErrors}`,
          '数据验证失败',
          {
            confirmButtonText: '确定',
            type: 'warning'
          }
        )
        return
      }
      
      if (valid.length === 0) {
        ElMessage.warning('没有找到有效的数据记录')
        return
      }
      
      // 确认导入
      await ElMessageBox.confirm(
        `即将导入${valid.length}条传感器详细信息记录，是否继续？`,
        '确认导入',
        {
          confirmButtonText: '确定导入',
          cancelButtonText: '取消',
          type: 'info'
        }
      )
      
      // 批量创建数据
      ElMessage.info('正在导入数据，请稍候...')
      
      let successCount = 0
      let failCount = 0
      
      // 使用Promise.all并行处理，但限制并发数量
      const batchSize = 10
      for (let i = 0; i < valid.length; i += batchSize) {
        const batch = valid.slice(i, i + batchSize)
        const promises = batch.map(async (item) => {
          try {
            // 移除辅助字段
            const { _rowIndex, ...cleanItem } = item
            await ApiService.createSensorDetail(cleanItem as Omit<SensorDetail, 'sensor_detail_id' | 'created_time'>)
            successCount++
          } catch (error) {
            console.error(`导入第${item._rowIndex}行数据失败:`, error)
            failCount++
          }
        })
        
        await Promise.all(promises)
      }
      
      // 刷新数据
      await loadSensorDetails()
      
      // 显示结果
      if (failCount === 0) {
        ElMessage.success(`成功导入${successCount}条传感器详细信息`)
      } else {
        ElMessage.warning(`导入完成：成功${successCount}条，失败${failCount}条`)
      }
      
    } catch (error) {
      console.error('Excel导入失败:', error)
      ElMessage.error(`导入失败: ${error}`)
    } finally {
      loading.value = false
      // 清理文件输入
      document.body.removeChild(input)
    }
  }
  
  // 添加到DOM并触发点击
  document.body.appendChild(input)
  input.click()
}

const getRValueType = (rValue?: number) => {
  if (rValue === null || typeof rValue === 'undefined') return 'info'
  if (rValue >= 0.999) return 'success'
  if (rValue >= 0.99) return 'warning'
  return 'danger'
}

// 生命周期
onMounted(() => {
  loadSensorDetails()
})
</script>

<style scoped>
.sensor-detail-management {
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
}

.toolbar-left {
  display: flex;
  align-items: center;
}

.toolbar-right {
  display: flex;
  gap: 12px;
}

.data-card {
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: 500;
}

.data-count {
  color: #86909c;
  font-size: 14px;
}

.destination-text,
.remarks-text {
  color: #4e5969;
}

.no-data {
  color: #c9cdd4;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 24px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

/* 统一表单布局样式 */
.unified-form-layout {
  padding: 20px;
  border: 1px solid #e5e6eb;
  border-radius: 8px;
  background-color: #fafafa;
}

.unified-form-layout.batch-item {
  position: relative;
  margin-bottom: 20px;
  padding-top: 50px; /* 为header留出空间 */
}

/* 批量添加对话框样式 */
.batch-form-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e6eb;
}

.batch-tip {
  color: #86909c;
  font-size: 14px;
}

.batch-form-container {
  max-height: 65vh;
  overflow-y: auto;
  padding: 4px;
  margin: -4px;
}

.batch-item-header {
    position: absolute;
    top: 15px;
    left: 20px;
    right: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
}

.item-number {
  font-weight: bold;
  color: #1677ff;
  font-size: 16px;
}

/* 深度选择器修改Element Plus组件内部样式 */
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
}

:deep(.el-form-item__label) {
  font-size: 14px !important;
  color: #4e5969 !important;
  margin-bottom: 8px !important;
  line-height: 1.5 !important;
}

:deep(.el-input__inner),
:deep(.el-input-number) {
  font-size: 14px;
  height: 40px;
}

:deep(.el-button) {
  font-size: 14px;
}

:deep(.el-table th) {
  background-color: #f2f3f5 !important;
  font-weight: 500;
  color: #4e5969;
}

:deep(.el-tag) {
  font-size: 13px;
  padding: 0 10px;
  height: 28px;
  line-height: 26px;
}
</style>
