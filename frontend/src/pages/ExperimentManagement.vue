<template>
  <div class="experiment-management">
    <div class="page-header">
      <h2>实验管理</h2>
      <p>管理实验记录和关联信息</p>
    </div>
    
    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-select
          v-model="filterBatchId"
          placeholder="筛选实验批次"
          clearable
          style="width: 200px; margin-right: 12px"
          @change="handleFilter"
        >
          <!-- MODIFIED: 使用统一的、安全的计算属性 sortedAvailableBatches -->
          <el-option
            v-for="batch in sortedAvailableBatches"
            :key="batch.batch_id"
            :label="batch.batch_number"
            :value="batch.batch_id"
          />
        </el-select>
        
        <el-select
          v-model="filterPersonId"
          placeholder="筛选人员"
          clearable
          style="width: 200px"
          @change="handleFilter"
        >
          <el-option
            v-for="person in filteredPersonsForFilter"
            :key="person.person_id"
            :label="`${person.person_name} (ID: ${person.person_id})`"
            :value="person.person_id"
          />
        </el-select>
      </div>
      
      <div class="toolbar-right">

        <el-button 
          :disabled="!authStore.hasModulePermission('experiment_management', 'read')"
          @click="handleExport"
        >
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
        <el-button 
          :disabled="!authStore.hasModulePermission('experiment_management', 'write')"
          type="primary" 
          @click="handleAdd"
        >
          <el-icon><Plus /></el-icon>
          新建实验
        </el-button>
      </div>
    </div>
    
    <!-- 数据表格 -->
    <el-card>
      <el-table
        :data="paginatedExperiments"
        stripe
        style="width: 100%"
        v-loading="loading"
      >
        <el-table-column label="序号" width="80" align="center">
          <template #default="{ $index }">
            {{ (currentPage - 1) * pageSize + $index + 1 }}
          </template>
        </el-table-column>
        <el-table-column label="实验批次号" width="150">
          <template #default="{ row }">
            <el-tag type="primary">
              {{ getBatchNumber(row.batch_id) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="实验成员" min-width="300">
          <template #default="{ row }">
            <div class="members-cell">
              <div v-if="row.members && row.members.length > 0" class="members-group">
                <div class="members-header">
                  <el-icon class="group-icon"><User /></el-icon>
                  <span class="member-count">{{ row.members.length }}人小组</span>
                </div>
                <div class="members-list">
                  <div 
                    v-for="(member, index) in row.members.slice(0, 5)" 
                    :key="member.id"
                    class="member-item"
                  >
                    <div class="member-avatar">
                      {{ member.person_name.charAt(0) }}
                    </div>
                    <div class="member-info">
                      <span class="member-name">{{ member.person_name }}</span>
                      <span class="member-id">ID: {{ member.person_id }}</span>
                    </div>
                    <div class="member-actions">
                      <el-tag 
                        type="info" 
                        size="small"
                        class="member-role"
                      >
                        成员
                      </el-tag>
                      <el-button
                        v-if="authStore.hasModulePermission('experiment_management', 'write')"
                        type="danger"
                        size="small"
                        text
                        @click="handleRemoveMember(row.experiment_id, member.person_id, member.person_name)"
                        class="remove-member-btn"
                      >
                        移除
                      </el-button>
                    </div>
                  </div>
                  <!-- 显示剩余成员数量 -->
                  <div v-if="row.members.length > 5" class="more-members">
                    <el-icon class="more-icon"><MoreFilled /></el-icon>
                    <span class="more-text">...还有{{ row.members.length - 5 }}人</span>
                  </div>
                </div>
              </div>
              <div v-else class="no-members">
                <el-icon><UserFilled /></el-icon>
                <span>暂无成员</span>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="created_time" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.created_time) }}
          </template>
        </el-table-column>
        <el-table-column prop="experiment_content" label="实验内容" min-width="200">
          <template #default="{ row }">
            <div class="content-cell">
              {{ row.experiment_content || '暂无描述' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button
              :disabled="!authStore.hasModulePermission('experiment_management', 'write')"
              type="primary"
              size="small"
              @click="handleEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              :disabled="!authStore.hasModulePermission('experiment_management', 'delete')"
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
      :title="isEdit ? '编辑实验' : '新建实验'"
      width="600px"
      @close="resetForm"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="关联实验批次" prop="batch_id" label-width="120px">
          <el-select
            v-model="form.batch_id"
            placeholder="请选择实验批次"
            style="width: 100%"
          >
            <!-- MODIFIED: 使用统一的、安全的计算属性 sortedAvailableBatches -->
            <el-option
              v-for="batch in sortedAvailableBatches"
              :key="batch.batch_id"
              :label="`${batch.batch_number} (${batch.start_time})`"
              :value="batch.batch_id"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="实验成员" prop="member_ids" label-width="120px">
          <div v-if="!isEdit" class="auto-sync-members">
            <div v-if="!form.batch_id" class="no-batch-selected">
              <el-icon><UserFilled /></el-icon>
              <span>请先选择实验批次，将自动同步该批次下的所有人员</span>
            </div>
            <div v-else-if="filteredPersons.length === 0" class="no-members">
              <el-icon><UserFilled /></el-icon>
              <span>该批次下暂无人员</span>
            </div>
            <div v-else class="members-preview">
              <div class="members-header">
                <el-icon class="sync-icon"><User /></el-icon>
                <span class="sync-text">将自动添加以下 {{ filteredPersons.length }} 名成员：</span>
              </div>
              <div class="members-list">
                <el-tag
                  v-for="person in filteredPersons.slice(0, 10)"
                  :key="person.person_id"
                  type="info"
                  size="small"
                  class="member-tag"
                >
                  {{ person.person_name }} (ID: {{ person.person_id }})
                </el-tag>
                <el-tag v-if="filteredPersons.length > 10" type="info" size="small" class="more-tag">
                  ...还有{{ filteredPersons.length - 10 }}人
                </el-tag>
              </div>
            </div>
          </div>
          <el-select
            v-else
            v-model="form.member_ids"
            placeholder="请选择实验成员"
            multiple
            style="width: 100%"
            collapse-tags
            collapse-tags-tooltip
          >
            <el-option
              v-for="person in filteredPersons"
              :key="person.person_id"
              :label="`${person.person_name} (ID: ${person.person_id})`"
              :value="person.person_id"
            />
          </el-select>
          <div v-if="isEdit" class="form-tip">
            编辑模式：可手动调整实验成员
          </div>
        </el-form-item>
        
        <el-form-item label="实验内容" prop="experiment_content">
          <el-input
            v-model="form.experiment_content"
            type="textarea"
            :rows="4"
            placeholder="请输入实验内容描述"
          />
        </el-form-item>
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
// NEW: 引入 onActivated 生命周期钩子
import { ref, computed, reactive, onMounted, onUnmounted, watch, nextTick, onActivated } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance } from 'element-plus'
import { Plus, Download, User, UserFilled, MoreFilled } from '@element-plus/icons-vue'
import { useDataStore, type Experiment } from '../stores/data'
import { ApiService } from '../services/api'
import { useAuthStore } from '../stores/auth'
import { usePagination } from '@/composables/usePagination'

import { getBatchNumber, formatDateTime } from '@/utils/formatters'
import { exportToExcel } from '@/utils/excel'

const dataStore = useDataStore()
const authStore = useAuthStore()

const loading = ref(false)

// --- NEW: 统一的数据加载逻辑 ---
const loadPageData = async (force = false) => {
  try {
    loading.value = true
    // 并行加载所有需要的数据，force参数确保可以强制从服务器获取最新数据
    await Promise.all([
      dataStore.loadExperiments(force),
      dataStore.loadPersons(force),
      dataStore.loadBatches(force)
    ])
  } catch (error) {
    console.error('Failed to load page data:', error)
    ElMessage.error('加载数据失败')
  } finally {
    loading.value = false
  }
}

// 页面可见性变化处理函数，用于浏览器切页后的数据刷新
const handleVisibilityChange = () => {
  if (!document.hidden) {
    console.log('页面重新可见，强制刷新数据...');
    loadPageData(true)
  }
}

// --- MODIFIED: onMounted 现在只负责初始加载和事件监听 ---
onMounted(() => {
  loadPageData() // 首次进入页面时加载数据
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

// --- NEW: 添加 onActivated 钩子 ---
// 当组件在 <keep-alive> 中被激活时，此钩子会被调用
// 这解决了切换路由回来后数据不刷新的问题
onActivated(() => {
  console.log('组件被激活，强制刷新数据...');
  loadPageData(true) // 每次进入该模块都强制刷新数据
})

// 组件卸载时清理监听器
onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()

// 分页相关
const { currentPage, pageSize, pageSizes, handleSizeChange, handleCurrentChange, resetPagination } = usePagination()

// 筛选相关
const filterBatchId = ref<number | undefined>()
const filterPersonId = ref<number | undefined>()

// --- REMOVED: 移除重复且不安全的 availableBatchesForFilter ---

// 显示人员表中的所有人员
const availablePersonsForFilter = computed(() => {
  return dataStore.persons
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

const form = reactive({
  experiment_id: 0,
  batch_id: undefined as number | undefined,
  member_ids: [] as number[],
  experiment_content: ''
})

const rules = {
  batch_id: [
    { required: true, message: '请选择关联实验批次', trigger: 'change' }
  ],
  member_ids: [
    { 
      validator: (rule: any, value: any, callback: any) => {
        if (isEdit.value) {
          if (!value || value.length === 0) {
            callback(new Error('请至少选择一个实验成员'))
          } else {
            callback()
          }
        } else {
          if (form.batch_id) {
            const batchPersons = dataStore.persons.filter(person => person.batch_id === form.batch_id)
            if (batchPersons.length === 0) {
              callback(new Error('该批次下暂无人员，无法创建实验'))
            } else {
              callback()
            }
          } else {
            callback(new Error('请先选择实验批次'))
          }
        }
      },
      trigger: 'change'
    }
  ],
  experiment_content: [
    { max: 500, message: '实验内容长度不能超过 500 个字符', trigger: 'blur' }
  ]
}

// 过滤后的实验列表
const filteredExperiments = computed(() => {
  let result = dataStore.experiments
  
  if (filterBatchId.value) {
    result = result.filter(exp => exp.batch_id === filterBatchId.value)
  }
  
  if (filterPersonId.value) {
    result = result.filter(exp => 
      exp.members && exp.members.some(member => member.person_id === filterPersonId.value)
    )
  }
  
  return result.sort((a, b) => b.experiment_id - a.experiment_id)
})

// 当前页数据
const paginatedExperiments = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredExperiments.value.slice(start, end)
})

// 总数据量
const total = computed(() => filteredExperiments.value.length)

// 根据选择的批次过滤人员，用于表单弹窗
const filteredPersons = computed(() => {
  if (!form.batch_id) {
    return []
  }
  const batchPersons = dataStore.persons.filter(person => person.batch_id === form.batch_id)
  return batchPersons.sort((a, b) => a.person_id - b.person_id)
})

// --- 重命名 sortedBatches 并作为唯一的批次排序来源 ---
const sortedAvailableBatches = computed(() => {
  // 获取所有已存在实验记录的batch_id列表
  const existingBatchIds = new Set(dataStore.experiments.map(exp => exp.batch_id))
  
  // 过滤掉已有实验记录的批次，只显示未添加实验记录的批次
  const availableBatches = dataStore.batches.filter(batch => !existingBatchIds.has(batch.batch_id))
  
  // 使用[...]创建新数组进行排序，避免直接修改store状态
  return [...availableBatches].sort((a, b) => 
    new Date(b.start_time).getTime() - new Date(a.start_time).getTime()
  )
})

// 监听批次选择变化，新建时自动同步人员
watch(() => form.batch_id, (newBatchId, oldBatchId) => {
  if (newBatchId !== oldBatchId) {
    if (isEdit.value) {
      form.member_ids = []
    } else {
      nextTick(() => {
        if (newBatchId) {
          const batchPersons = dataStore.persons.filter(person => person.batch_id === newBatchId)
          form.member_ids = batchPersons.map(person => person.person_id)
        } else {
          form.member_ids = []
        }
      })
    }
  }
})

// 筛选处理
const handleFilter = () => {
  resetPagination()
}

// 导出数据
const handleExport = () => {
  try {
    const exportData = filteredExperiments.value.map(experiment => ({
      '实验ID': experiment.experiment_id,
      '实验批次号': getBatchNumber(experiment.batch_id),
      '实验成员': experiment.members?.map(m => m.person_name).join(', ') || '暂无成员',
      '成员数量': experiment.members?.length || 0,
      '实验内容': experiment.experiment_content || '暂无描述',
      '创建时间': formatDateTime(experiment.created_time)
    }))
    
    exportToExcel(exportData, '实验数据')
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('Export failed:', error)
    ElMessage.error('导出失败，请重试')
  }
}

// 新建实验
const handleAdd = () => {
  isEdit.value = false
  dialogVisible.value = true
  resetForm()
}

// 编辑实验
const handleEdit = (row: Experiment) => {
  isEdit.value = true
  dialogVisible.value = true
  
  form.experiment_id = row.experiment_id
  form.batch_id = row.batch_id
  form.experiment_content = row.experiment_content || ''
  
  nextTick(() => {
    form.member_ids = row.members ? row.members.map(member => member.person_id) : (row.member_ids || [])
  })
}

// 删除实验
const handleDelete = async (row: Experiment) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除实验记录 "${row.experiment_id}" 吗？`, '删除确认',
      { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
    )
    
    await ApiService.deleteExperiment(row.experiment_id)
    ElMessage.success('删除成功')
    
    // 只刷新实验数据即可
    await dataStore.loadExperiments(true)
    
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
      const payload = {
        batch_id: form.batch_id!,
        member_ids: form.member_ids,
        experiment_content: form.experiment_content
      }
      
      try {
        if (isEdit.value) {
          await ApiService.updateExperiment(form.experiment_id, payload)
          ElMessage.success('更新成功')
        } else {
          await ApiService.createExperiment(payload)
          ElMessage.success('创建成功')
        }
        
        dialogVisible.value = false
        await dataStore.loadExperiments(true)
        
      } catch (error) {
        console.error('Submit failed:', error)
        ElMessage.error(isEdit.value ? '更新失败' : '创建失败')
      }
    }
  })
}

// 移除实验成员
const handleRemoveMember = async (experimentId: number, personId: number, personName: string) => {
  try {
    await ElMessageBox.confirm(
      `确定要从实验中移除成员 ${personName} 吗？`, '确认移除',
      { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
    )
    
    await dataStore.removeExperimentMember(experimentId, personId)
    ElMessage.success(`成功移除成员 ${personName}`)
    
  } catch (error) {
    if (error !== 'cancel') {
      console.error('移除成员失败:', error)
      const errorMessage = error instanceof Error ? error.message : '移除成员失败'
      ElMessage.error(`移除成员失败: ${errorMessage}`)
    }
  }
}

// 重置表单
const resetForm = () => {
  if (formRef.value) {
    formRef.value.resetFields()
  }
  Object.assign(form, {
    experiment_id: 0,
    batch_id: undefined,
    member_ids: [],
    experiment_content: ''
  })
}
</script>

<style scoped>
/* 样式部分未作修改，保持原样 */
.experiment-management {
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

.content-cell {
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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

:deep(.el-select) {
  width: 100%;
}

.members-cell {
  padding: 8px 0;
}

.members-group {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 12px;
  border: 1px solid #e4e7ed;
}

.members-header {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid #e4e7ed;
}

.group-icon {
  color: #409eff;
  margin-right: 6px;
  font-size: 16px;
}

.member-count {
  font-size: 12px;
  color: #606266;
  font-weight: 500;
}

.members-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.member-item {
  display: flex;
  align-items: center;
  padding: 6px 8px;
  background: white;
  border-radius: 6px;
  border: 1px solid #ebeef5;
  transition: all 0.2s ease;
}

.member-item:hover {
  border-color: #409eff;
  box-shadow: 0 2px 4px rgba(64, 158, 255, 0.1);
}

.member-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409eff, #67c23a);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  margin-right: 10px;
  flex-shrink: 0;
}

.member-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.member-name {
  font-size: 13px;
  font-weight: 500;
  color: #303133;
  line-height: 1.2;
}

.member-id {
  font-size: 11px;
  color: #909399;
  line-height: 1.2;
  margin-top: 2px;
}

.member-role {
  margin-left: 8px;
  flex-shrink: 0;
}

.no-members {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  color: #c0c4cc;
  font-size: 13px;
  background: #fafafa;
  border-radius: 6px;
  border: 1px dashed #e4e7ed;
}

.no-members .el-icon {
  margin-right: 6px;
  font-size: 16px;
}

.form-tip {
  margin-top: 4px;
  color: #909399;
  font-size: 12px;
  line-height: 1.4;
}

.more-members {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
  background: #f0f9ff;
  border-radius: 6px;
  border: 1px dashed #409eff;
  color: #409eff;
  font-size: 12px;
  margin-top: 4px;
}

.more-icon {
  margin-right: 4px;
  font-size: 14px;
}

.more-text {
  font-weight: 500;
}

.auto-sync-members {
  min-height: 60px;
}

.no-batch-selected,
.no-members {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: #f8f9fa;
  border: 1px dashed #e4e7ed;
  border-radius: 8px;
  color: #909399;
  font-size: 14px;
}

.no-batch-selected .el-icon,
.no-members .el-icon {
  margin-right: 8px;
  font-size: 18px;
}

.members-preview {
  background: #f0f9ff;
  border: 1px solid #b3d8ff;
  border-radius: 8px;
  padding: 16px;
}

.members-preview .members-header { 
  display: flex;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #d1ecf1;
}

.sync-icon {
  color: #409eff;
  margin-right: 8px;
  font-size: 16px;
}

.sync-text {
  color: #409eff;
  font-weight: 500;
  font-size: 14px;
}

.members-preview .members-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  flex-direction: row;
}

.member-tag {
  margin: 0;
  font-size: 12px;
  border-radius: 4px;
}

.more-tag {
  background-color: #e1f5fe;
  border-color: #81d4fa;
  color: #0277bd;
}

</style>
