<template>
  <div class="batch-management">
    <div class="page-header">
      <h2>批次管理</h2>
      <p>管理实验批次信息</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchText"
          placeholder="搜索实验批次号"
          style="width: 300px"
          clearable
          @input="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
      </div>
      
      <div class="toolbar-right">
        <el-button 
          :disabled="!authStore.hasModulePermission('batch_management', 'read')"
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('batch_management', 'write')"
          type="primary" 
          @click="handleAdd"
        >
          <el-icon><Plus /></el-icon>
          新建批次
        </el-button>
      </div>
    </div>
    
    <!-- 数据表格 -->
    <el-card>
      <el-table
        :data="paginatedBatches"
        stripe
        style="width: 100%"
        v-loading="loading"
      >
        <el-table-column prop="batch_id" label="批次ID" width="100" />
        <el-table-column prop="batch_number" label="实验批次号" min-width="150">
          <template #default="{ row }">
            <el-tag type="primary" size="small">
              {{ row.batch_number }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="start_time" label="开始时间" min-width="180" />
        <el-table-column prop="end_time" label="结束时间" min-width="180">
          <template #default="{ row }">
            {{ row.end_time || getBatchStatus(row).label }}
          </template>
        </el-table-column>
        <el-table-column prop="person_count" label="人数" width="80" align="center">
          <template #default="{ row }">
            <el-tag type="info" size="small">
              {{ row.person_count || 0 }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" min-width="100">
          <template #default="{ row }">
            <el-tag :type="getBatchStatus(row).type">
              {{ getBatchStatus(row).label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button
              :disabled="!authStore.hasModulePermission('batch_management', 'write')"
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('batch_management', 'delete')"
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
      :title="isEdit ? '编辑批次' : '新建批次'"
      width="680px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="实验批次号" prop="batch_number">
          <el-input
            v-model="form.batch_number"
            placeholder="请输入实验批次号"
          />
        </el-form-item>
        
        <el-form-item label="开始时间" prop="start_time">
          <el-date-picker
            v-model="form.start_time"
            type="datetime"
            placeholder="选择开始时间"
            style="width: 100%"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        
        <el-form-item label="结束时间" prop="end_time">
          <el-date-picker
            v-model="form.end_time"
            type="datetime"
            placeholder="选择结束时间（可选）"
            style="width: 100%"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
            clearable
          />
        </el-form-item>
        
        <!-- 人员信息录入区域（仅新建时显示） -->
        <div v-if="!isEdit" class="person-section">
          <div class="section-header">
            <h4>同时添加人员（可选）</h4>
            <el-button type="primary" size="small" @click="addPerson">
              <el-icon><Plus /></el-icon>
              添加人员
            </el-button>
          </div>
          
          <div v-if="form.persons.length === 0" class="empty-hint">
            <p>可选择在创建批次时同时添加人员信息，也可以稍后在人员管理中添加</p>
          </div>
          
          <!-- START: MODIFIED SECTION -->
          <div v-for="(person, index) in form.persons" :key="index" class="person-item">
            <el-card shadow="never" class="person-card">
              <div class="person-form">
                <div class="person-inline-row">
                  <!-- 姓名 -->
                  <el-form-item
                    :prop="'persons.' + index + '.person_name'"
                    :rules="personRules.person_name"
                    label="姓名"
                    class="inline-form-item"
                  >
                    <el-input
                      v-model="person.person_name"
                      placeholder="请输入姓名"
                      clearable
                    />
                  </el-form-item>

                  <!-- 性别 -->
                  <el-form-item label="性别" class="inline-form-item">
                    <el-select
                      v-model="person.gender"
                      placeholder="请选择"
                      clearable
                      style="width: 100%"
                    >
                      <el-option label="男" value="Male" />
                      <el-option label="女" value="Female" />
                      <el-option label="其他" value="Other" />
                    </el-select>
                  </el-form-item>

                  <!-- 年龄 -->
                  <el-form-item label="年龄" class="inline-form-item">
                    <el-input
                      v-model.number="person.age"
                      type="number"
                      placeholder="请输入年龄"
                      :min="1"
                      :max="120"
                      clearable
                    />
                  </el-form-item>
                  
                  <!-- 删除按钮 -->
                  <el-button type="danger" plain size="small" @click="removePerson(index)">
                    删除
                  </el-button>
                </div>
              </div>
            </el-card>
          </div>
          <!-- END: MODIFIED SECTION -->
        </div>
      </el-form>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted, watch } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance } from 'element-plus'
import { Search, Plus, Download, Delete } from '@element-plus/icons-vue'
import { usePagination } from '../composables/usePagination'
import { exportToExcel } from '../utils/excel'
import { useDataStore, type Batch } from '../stores/data'
import { ApiService } from '../services/api'
import { useAuthStore } from '../stores/auth'

const dataStore = useDataStore()
const authStore = useAuthStore()

// 页面可见性监听
const handleVisibilityChange = async () => {
  if (!document.hidden) {
    // 页面变为可见时刷新数据
    try {
      loading.value = true
      await dataStore.loadBatches(true)
    } catch (error) {
      console.error('Failed to refresh data:', error)
    } finally {
      loading.value = false
    }
  }
}

// 组件挂载时检查数据是否已加载
onMounted(async () => {
  try {
    loading.value = true
    // 使用缓存机制加载批次数据
    await dataStore.loadBatches()
    
    // 添加页面可见性监听
    document.addEventListener('visibilitychange', handleVisibilityChange)
  } catch (error) {
    console.error('Failed to load batches:', error)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
})

// 组件卸载时移除监听器
onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const loading = ref(false)
const searchText = ref('')
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()

const form = reactive({
  batch_id: 0,
  batch_number: '',
  start_time: '',
  end_time: '',
  // 人员信息
  persons: [] as Array<{
    person_name: string
    gender?: 'Male' | 'Female' | 'Other'
    age?: number
  }>
})

const rules = {
  batch_number: [
    { required: true, message: '请输入实验批次号', trigger: 'blur' },
    { min: 3, max: 50, message: '实验批次号长度在 3 到 50 个字符', trigger: 'blur' }
  ],
  start_time: [
    { required: true, message: '请选择开始时间', trigger: 'change' }
  ]
}

// 人员表单验证规则
const personRules = {
  person_name: [
    { required: true, message: '请输入姓名', trigger: 'blur' },
    { min: 2, max: 20, message: '姓名长度在 2 到 20 个字符', trigger: 'blur' }
  ]
}

// 性别映射
const genderMap = {
  Male: '男',
  Female: '女',
  Other: '其他'
}

// 获取批次状态
const getBatchStatus = (batch: Batch) => {
  const now = new Date().getTime()
  const startTime = new Date(batch.start_time).getTime()
  const endTime = batch.end_time ? new Date(batch.end_time).getTime() : null
  
  if (now < startTime) {
    return { type: 'warning', label: '未开始' }
  } else if (endTime && now > endTime) {
    return { type: 'info', label: '已结束' }
  } else {
    return { type: 'success', label: '进行中' }
  }
}

// 过滤后的批次列表
const filteredBatches = computed(() => {
  let result = dataStore.batches
  
  if (searchText.value) {
    result = result.filter(batch => 
      batch.batch_number.toLowerCase().includes(searchText.value.toLowerCase())
    )
  }
  
  // 按批次ID倒序排列，最新创建的在前面
  return result.sort((a, b) => b.batch_id - a.batch_id)
})

// 分页逻辑
const {
  currentPage,
  pageSize,
  pageSizes,
  total,
  handleSizeChange,
  handleCurrentChange,
  resetPagination
} = usePagination()

// 分页数据计算
const paginatedBatches = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredBatches.value.slice(start, end)
})

// 监听过滤结果变化，更新总数
watch(filteredBatches, (newVal) => {
  total.value = newVal.length
}, { immediate: true })

// 搜索处理
const handleSearch = () => {
  resetPagination()
}

// 导出数据
const handleExport = () => {
  try {
    const exportData = filteredBatches.value.map(batch => ({
      '批次ID': batch.batch_id,
      '实验批次号': batch.batch_number,
      '开始时间': batch.start_time,
      '结束时间': batch.end_time || '进行中',
      '状态': getBatchStatus(batch).label
    }))
    
    const success = exportToExcel(exportData, '批次数据导出', '批次数据')
    if (success) {
      ElMessage.success('导出成功')
    } else {
      ElMessage.error('导出失败')
    }
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 新建批次
const handleAdd = () => {
  isEdit.value = false
  dialogVisible.value = true
  resetForm()
}

// 添加人员
const addPerson = () => {
  form.persons.push({
    person_name: '',
    gender: undefined,
    age: undefined
  })
}

// 删除人员
const removePerson = (index: number) => {
  form.persons.splice(index, 1)
}

// 编辑批次
const handleEdit = (row: Batch) => {
  isEdit.value = true
  dialogVisible.value = true
  Object.assign(form, row)
}

// 删除批次
const handleDelete = async (row: Batch) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除批次 "${row.batch_number}" 吗？`,
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await dataStore.deleteBatch(row.batch_id)
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
          await dataStore.updateBatch(form.batch_id, {
            batch_number: form.batch_number,
            start_time: form.start_time,
            end_time: form.end_time || undefined
          })
          ElMessage.success('更新成功')
        } else {
          const newBatch = await dataStore.addBatch({
            batch_number: form.batch_number,
            start_time: form.start_time,
            end_time: form.end_time || undefined,
            person_count: 0
          })
          
          if (form.persons.length > 0) {
            const validPersons = form.persons.filter(p => p.person_name.trim())
            for (const person of validPersons) {
              await dataStore.addPerson({
                person_name: person.person_name,
                gender: person.gender || undefined,
                age: person.age || undefined,
                batch_id: newBatch.batch_id
              })
            }
            
            // 重新获取批次数据以更新person_count
            const batchesData = await ApiService.getBatches()
            dataStore.batches = batchesData
            
            // 清除人员缓存，确保人员管理页面能够获取最新数据
            dataStore.clearCache('persons')
            
            if (validPersons.length > 0) {
              ElMessage.success(`批次创建成功，已添加 ${validPersons.length} 位人员`)
            } else {
              ElMessage.success('批次创建成功')
            }
          } else {
            ElMessage.success('批次创建成功')
          }
        }
        
        dialogVisible.value = false
        resetForm()
      } catch (error: any) {
        console.error('Submit failed:', error)
        let errorMessage = isEdit.value ? '更新失败' : '创建失败'
        
        if (error?.response?.data?.detail) {
          errorMessage = error.response.data.detail
        } else if (error?.message && !error.message.includes('Request failed')) {
          errorMessage = error.message
        }
        
        ElMessage.error(errorMessage)
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
    batch_id: 0,
    batch_number: '',
    start_time: '',
    end_time: '',
    persons: []
  })
}
</script>

<style scoped>
.batch-management {
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
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
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

/* 人员信息录入区域样式 */
.person-section {
  margin-top: 24px;
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
  padding: 20px;
  color: #909399;
  font-size: 14px;
}

.empty-hint p {
  margin: 0;
}

.person-item {
  margin-bottom: 16px;
}

.person-card {
  border: 1px solid #e4e7ed;
}

.person-form {
  width: 100%;
}

/* START: NEW/MODIFIED STYLES FOR INLINE FORM */
.person-inline-row {
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
}

.inline-form-item {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1; 
  margin-bottom: 0;
}

:deep(.inline-form-item .el-form-item__label) {
  padding: 0;
  line-height: normal;
  width: auto !important;
  color: #606266;
  font-weight: normal;
  white-space: nowrap;
}

:deep(.inline-form-item .el-form-item__content) {
  margin-left: 0 !important;
  flex: 1;
}

:deep(.inline-form-item.is-required .el-form-item__label::before) {
    content: '*';
    color: var(--el-color-danger);
    margin-right: 4px;
}
/* END: NEW/MODIFIED STYLES */

@media (max-width: 768px) {
  .person-inline-row {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
  }
}
</style>
