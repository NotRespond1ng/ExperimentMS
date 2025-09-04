<template>
  <div class="person-management">
    <div class="page-header">
      <h2>人员管理</h2>
      <p>管理受试人员信息</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-input
          v-model="searchText"
          placeholder="搜索人员姓名"
          clearable
          style="width: 300px"
          @keyup.enter="handleSearch"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
        
        <el-select
          v-model="batchFilter"
          placeholder="筛选批次"
          clearable
          style="width: 200px"
        >
          <el-option label="全部批次" value="" />
          <el-option
            v-for="batch in sortedBatches"
            :key="batch.batch_id"
            :label="batch.batch_number"
            :value="batch.batch_id"
          />
        </el-select>
      </div>
      
      <div class="toolbar-right">
        <el-button 
          :disabled="!authStore.hasModulePermission('person_management', 'read')"
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('person_management', 'write')"
          type="primary" 
          @click="handleAdd"
        >
          <el-icon><Plus /></el-icon>
          新建人员
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('person_management', 'write')"
          type="success" 
          @click="handleBatchAdd"
        >
          <el-icon><Plus /></el-icon>
          批量添加
        </el-button>
      </div>
    </div>
    
    <!-- 数据表格 -->
    <el-card>
      <el-table
        :data="paginatedPersons"
        stripe
        style="width: 100%"
        v-loading="loading"
      >
        <el-table-column label="序号" width="120" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <!-- 隐藏原始person_id列，但保留数据用于后端传递 -->
        <!-- <el-table-column prop="person_id" label="人员ID" width="100" /> -->
        <el-table-column prop="person_name" label="姓名" width="180">
          <template #default="{ row }">
            <el-tag type="success" size="small">
              {{ row.person_name }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="gender" label="性别" width="120">
          <template #default="{ row }">
            <el-tag
              :type="row.gender === 'Male' ? 'primary' : row.gender === 'Female' ? 'danger' : 'info'"
              size="small"
            >
              {{ genderMap[row.gender] || '未知' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="age" label="年龄" width="120">
          <template #default="{ row }">
            {{ row.age || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="batch_number" label="所属实验批次" min-width="200">
          <template #default="{ row }">
            <el-tag v-if="row.batch_number" type="info" size="small">
              {{ row.batch_number }}
            </el-tag>
            <span v-else class="text-gray-400">未分配</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button
              :disabled="!authStore.hasModulePermission('person_management', 'write')"
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('person_management', 'delete')"
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
      :title="isEdit ? '编辑人员' : '新建人员'"
      width="500px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="姓名" prop="person_name">
          <el-input
            v-model="form.person_name"
            placeholder="请输入姓名"
          />
        </el-form-item>
        
        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="form.gender">
            <el-radio value="Male">男</el-radio>
            <el-radio value="Female">女</el-radio>
            <el-radio value="Other">其他</el-radio>
          </el-radio-group>
        </el-form-item>
        
        <el-form-item label="年龄" prop="age">
          <el-input-number
            v-model="form.age"
            :min="1"
            :max="120"
            placeholder="请输入年龄"
            style="width: 100%"
          />
        </el-form-item>
        
        <el-form-item label="所属实验批次" prop="batch_id">
          <el-select
            v-model="form.batch_id"
            placeholder="请选择实验批次"
            style="width: 100%"
            clearable
          >
            <el-option
              v-for="batch in sortedBatches"
              :key="batch.batch_id"
              :label="batch.batch_number"
              :value="batch.batch_id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 批量添加人员对话框 -->
    <el-dialog
      v-model="batchDialogVisible"
      title="批量添加人员"
      width="800px"
      :close-on-click-modal="false"
    >
      <el-form
        :model="batchForm"
        :rules="batchRules"
        label-width="100px"
        label-position="left"
      >
        <el-form-item label="选择实验批次" prop="batch_id">
          <el-select
            v-model="batchForm.batch_id"
            placeholder="请选择实验批次"
            style="width: 100%"
            clearable
          >
            <el-option
              v-for="batch in sortedBatches"
              :key="batch.batch_id"
              :label="batch.batch_number"
              :value="batch.batch_id"
            />
          </el-select>
        </el-form-item>

        <div class="person-section">
          <div class="section-header">
            <h4>人员信息</h4>
            <el-button type="primary" size="small" @click="addPersonToBatch">
              <el-icon><Plus /></el-icon>
              添加人员
            </el-button>
          </div>

          <div v-if="batchForm.persons.length === 0" class="empty-hint">
            <p>暂无人员，请点击"添加人员"按钮添加</p>
          </div>

          <div v-for="(person, index) in batchForm.persons" :key="index" class="person-item">
            <el-card shadow="never" class="person-card">
              <div class="person-form">
                <div class="person-inline-row">
                  <!-- 姓名 -->
                  <el-form-item
                    :prop="`persons.${index}.name`"
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
                  <el-button type="danger" plain size="small" @click="removePersonFromBatch(index)">
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
import { ref, computed, reactive, onMounted, onUnmounted, watch } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance } from 'element-plus'
import { Search, Plus, Download, Delete } from '@element-plus/icons-vue'
import { useDataStore, type Person } from '../stores/data'
import { ApiService } from '../services/api'
import { useAuthStore } from '../stores/auth'
import { usePagination } from '@/composables/usePagination'
import { getBatchNumber, formatDateTime } from '@/utils/formatters'
import { exportToExcel } from '@/utils/excel'

const dataStore = useDataStore()
const authStore = useAuthStore()

// 组件挂载时获取最新数据
onMounted(async () => {
  try {
    loading.value = true
    
    // 使用缓存机制加载数据
    await Promise.all([
      dataStore.loadPersons(),
      dataStore.loadBatches()
    ])
    
    // 获取批次数据用于表单选择
    batches.value = await ApiService.getBatchesForPerson()
  } catch (error) {
    console.error('Failed to load data:', error)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
})

// 页面可见性监听，当页面重新获得焦点时刷新数据
const handleVisibilityChange = async () => {
  if (!document.hidden) {
    // 页面重新获得焦点时，强制刷新人员数据
    try {
      await dataStore.loadPersons(true) // force = true
      batches.value = await ApiService.getBatchesForPerson()
    } catch (error) {
      console.error('Failed to refresh data:', error)
    }
  }
}

// 添加页面可见性监听器
onMounted(() => {
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

// 移除监听器
onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const loading = ref(false)
const dialogVisible = ref(false)
const batchDialogVisible = ref(false)
const isEdit = ref(false)
const currentPersonId = ref<number | null>(null)
const formRef = ref<FormInstance>()
const batches = ref<any[]>([])
const batchForm = ref({
  batch_id: null,
  persons: []
})

// 分页相关
const {
  currentPage,
  pageSize,
  pageSizes,
  total,
  handleSizeChange,
  handleCurrentChange,
  resetPagination
} = usePagination()

// 搜索相关
const searchText = ref('')
const batchFilter = ref('')
const handleSearch = () => {
  resetPagination()
}

const form = reactive({
  person_id: 0,
  person_name: '',
  gender: 'Male' as 'Male' | 'Female' | 'Other',
  age: undefined as number | undefined,
  batch_id: undefined as number | undefined
})

const genderMap = {
  Male: '男',
  Female: '女',
  Other: '其他'
}

const rules = {
  person_name: [
    { required: true, message: '请输入姓名', trigger: 'blur' },
    { min: 2, max: 20, message: '姓名长度在 2 到 20 个字符', trigger: 'blur' }
  ],
  gender: [
    { required: true, message: '请选择性别', trigger: 'change' }
  ]
}

const batchRules = {
  batch_id: [
    { required: true, message: '请选择实验批次', trigger: 'change' }
  ]
}

const personRules = {
  person_name: [
    { required: true, message: '请输入姓名', trigger: 'blur' }
  ],
  gender: [
    { required: true, message: '请选择性别', trigger: 'change' }
  ]
}

// 过滤后的人员列表
const filteredPersons = computed(() => {
  let result = dataStore.persons
  
  // 按姓名搜索过滤
  if (searchText.value) {
    result = result.filter(person => 
      person.person_name.toLowerCase().includes(searchText.value.toLowerCase())
    )
  }
  
  // 按批次过滤
  if (batchFilter.value) {
    result = result.filter(person => person.batch_id === Number(batchFilter.value))
  }
  
  // 按人员ID倒序排列，最新创建的在前面
  return result.sort((a, b) => b.person_id - a.person_id)
})

// 排序后的批次列表（新建的在前面）
const sortedBatches = computed(() => {
  return [...batches.value].sort((a, b) => b.batch_id - a.batch_id)
})

// 当前页数据
const paginatedPersons = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredPersons.value.slice(start, end)
})

// 监听过滤结果变化，更新总数
watch(filteredPersons, (newVal) => {
  total.value = newVal.length
}, { immediate: true })





// 导出数据
const handleExport = () => {
  try {
    // 准备导出数据
    const exportData = filteredPersons.value.map(person => ({
      '人员ID': person.person_id,
      '姓名': person.person_name,
      '性别': genderMap[person.gender] || '未知',
      '年龄': person.age || '-',
      '所属实验批次': person.batch_number || '未分配'
    }))
    
    exportToExcel(exportData, '人员数据')
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('Export failed:', error)
    ElMessage.error('导出失败，请重试')
  }
}

// 新建人员
const handleAdd = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

const handleBatchAdd = () => {
  resetBatchForm()
  batchDialogVisible.value = true
}

const addPersonToBatch = () => {
  batchForm.value.persons.push({
    person_name: '',
    gender: 'Male',
    age: undefined
  })
}

const removePersonFromBatch = (index: number) => {
  batchForm.value.persons.splice(index, 1)
}

const resetBatchForm = () => {
  batchForm.value = {
    batch_id: null,
    persons: []
  }
}

const handleBatchSubmit = async () => {
  if (batchForm.value.persons.length === 0) {
    ElMessage.warning('请至少添加一位人员')
    return
  }
  
  try {
    loading.value = true
    
    // 批量添加人员
    for (const person of batchForm.value.persons) {
      const personData = {
        ...person,
        batch_id: batchForm.value.batch_id
      }
      await dataStore.addPerson(personData)
    }
    
    ElMessage.success('批量添加人员成功')
    batchDialogVisible.value = false
    resetBatchForm()
    // 重新加载人员数据
    const personsData = await ApiService.getPersons()
    dataStore.persons = personsData
  } catch (error) {
    console.error('批量添加人员失败:', error)
    ElMessage.error('批量添加人员失败')
  } finally {
    loading.value = false
  }
}

// 编辑人员
const handleEdit = (row: Person) => {
  isEdit.value = true
  dialogVisible.value = true
  Object.assign(form, row)
}

// 删除人员
const handleDelete = async (row: Person) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除人员 "${row.person_name}" 吗？`,
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await dataStore.deletePerson(row.person_id)
    ElMessage.success('删除成功')
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('Delete failed:', error)
      // 从错误响应中提取详细错误信息
      const errorMessage = error?.response?.data?.detail || error?.message || '删除失败'
      ElMessage.error(errorMessage)
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
          // 编辑
          await dataStore.updatePerson(form.person_id, {
            person_name: form.person_name,
            gender: form.gender,
            age: form.age,
            batch_id: form.batch_id
          })
          ElMessage.success('更新成功')
          // updatePerson方法内部已经重新加载了完整的人员数据，无需额外刷新
        } else {
          // 新建
          await dataStore.addPerson({
            person_name: form.person_name,
            gender: form.gender,
            age: form.age,
            batch_id: form.batch_id
          })
          ElMessage.success('创建成功')
          
          // 重新加载人员数据，与批量录入逻辑保持一致
          const personsData = await ApiService.getPersons()
          dataStore.persons = personsData
        }
        
        // 更新批次数据（仅在新建时需要，编辑时dataStore.updatePerson已处理）
        if (!isEdit.value) {
          batches.value = await ApiService.getBatchesForPerson()
        }
        
        dialogVisible.value = false
        resetForm()
      } catch (error) {
        console.error('Submit failed:', error)
        ElMessage.error(isEdit.value ? '更新失败' : '创建失败')
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
    person_id: 0,
    person_name: '',
    gender: 'Male' as 'Male' | 'Female' | 'Other',
    age: undefined,
    batch_id: undefined
  })
}
</script>

<style scoped>
.person-management {
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

:deep(.el-radio-group) {
  display: flex;
  gap: 16px;
}

.person-section {
  margin-top: 20px;
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

.person-item {
  margin-bottom: 16px;
}

.person-card {
  border: 1px solid #e4e7ed;
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