<template>
  <div class="dashboard">
    <div class="dashboard-header">
      <h1>系统概览</h1>
      <p>欢迎使用实验数据管理系统</p>
    </div>
    
    <!-- 统计卡片 -->
    <div class="stats-grid">
      <!-- 统计卡片骨架屏 -->
      <template v-if="statsLoading">
        <el-card v-for="i in 4" :key="i" class="stat-card">
          <el-skeleton animated>
            <template #template>
              <div class="stat-content">
                <el-skeleton-item variant="circle" style="width: 60px; height: 60px" />
                <div class="stat-info">
                  <el-skeleton-item variant="h1" style="width: 60px; margin-bottom: 8px" />
                  <el-skeleton-item variant="text" style="width: 80px" />
                </div>
              </div>
            </template>
          </el-skeleton>
        </el-card>
      </template>
      
      <!-- 实际统计卡片 -->
      <template v-else>
        <el-card class="stat-card batch-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="32"><Collection /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-number">{{ dashboardStats.batches_count }}</div>
              <div class="stat-label">实验批次</div>
            </div>
          </div>
        </el-card>
        
        <el-card class="stat-card person-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="32"><User /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-number">{{ dashboardStats.persons_count }}</div>
              <div class="stat-label">受试人员</div>
            </div>
          </div>
        </el-card>
        
        <el-card class="stat-card experiment-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="32"><DataAnalysis /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-number">{{ dashboardStats.experiments_count }}</div>
              <div class="stat-label">实验记录</div>
            </div>
          </div>
        </el-card>
        
        <el-card class="stat-card data-card">
          <div class="stat-content">
            <div class="stat-icon">
              <el-icon size="32"><TrendCharts /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-number">{{ dashboardStats.finger_blood_data_count }}</div>
              <div class="stat-label">血糖数据</div>
            </div>
          </div>
        </el-card>
      </template>
    </div>
    
    <!-- 快速操作 -->
    <div class="quick-actions">
      <el-card>
        <template #header>
          <div class="card-header">
            <span>快速操作</span>
          </div>
        </template>
        
        <div class="action-buttons">
          <el-button type="primary" @click="$router.push('/batches')">
            <el-icon><Plus /></el-icon>
            新建实验批次
          </el-button>
          
          <el-button type="success" @click="$router.push('/persons')">
            <el-icon><UserFilled /></el-icon>
            添加实验人员
          </el-button>
          
          <el-button type="warning" @click="$router.push('/experiments')">
            <el-icon><DocumentAdd /></el-icon>
            创建实验
          </el-button>
          
          <el-button type="info" @click="$router.push('/fingerBloodData')">
            <el-icon><DataLine /></el-icon>
            录入指尖血数据
          </el-button>
        </div>
      </el-card>
    </div>
    
    <!-- 最近活动 -->
    <div class="recent-activity">
      <el-card>
        <template #header>
          <div class="card-header">
            <span>最近活动</span>
            <el-icon v-if="activitiesLoading" class="is-loading"><Loading /></el-icon>
          </div>
        </template>
        
        <!-- 活动列表骨架屏 -->
        <template v-if="activitiesLoading">
          <el-skeleton animated>
            <template #template>
              <div v-for="i in 4" :key="i" class="activity-skeleton">
                <el-skeleton-item variant="circle" style="width: 12px; height: 12px" />
                <div class="activity-content">
                  <el-skeleton-item variant="text" style="width: 200px; margin-bottom: 4px" />
                  <el-skeleton-item variant="text" style="width: 120px" />
                </div>
              </div>
            </template>
          </el-skeleton>
        </template>
        
        <!-- 实际活动列表 -->
        <el-timeline v-else>
          <el-timeline-item
            v-for="activity in recentActivities"
            :key="activity.id"
            :timestamp="activity.time"
            :type="activity.type"
          >
            {{ activity.description }}
          </el-timeline-item>
        </el-timeline>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import {
  Collection,
  User,
  DataAnalysis,
  TrendCharts,
  Plus,
  UserFilled,
  DocumentAdd,
  DataLine,
  Loading
} from '@element-plus/icons-vue'
import { ApiService } from '../services/api'
import type { DashboardStats } from '../services/api'

const recentActivities = ref([])
const activitiesLoading = ref(false)
const statsLoading = ref(false)
const dashboardStats = ref<DashboardStats>({
  batches_count: 0,
  persons_count: 0,
  experiments_count: 0,
  finger_blood_data_count: 0
})

// 获取统计数据
const fetchDashboardStats = async () => {
  try {
    statsLoading.value = true
    const stats = await ApiService.getDashboardStats()
    dashboardStats.value = stats
  } catch (error) {
    console.error('获取统计数据失败:', error)
    // 保持默认值
  } finally {
    statsLoading.value = false
  }
}

// 获取最近活动数据
const fetchRecentActivities = async () => {
  try {
    activitiesLoading.value = true
    // 减少查询数量，提高性能
    const activities = await ApiService.getActivities(5)
    recentActivities.value = activities.map(activity => {
      const username = activity.username || '系统'
      return {
        id: activity.activity_id,
        description: `${username} ${activity.description}`,
        time: new Date(activity.createTime).toLocaleString('zh-CN'),
        type: getActivityType(activity.activity_type)
      }
    })
  } catch (error) {
    console.error('获取活动数据失败:', error)
    // 使用模拟数据作为后备
    recentActivities.value = [
      {
        id: 1,
        description: 'admin 创建了新批次 BATCH002',
        time: '2024-01-02 09:00:00',
        type: 'primary'
      },
      {
        id: 2,
        description: 'admin 添加了受试人员 李四',
        time: '2024-01-01 16:30:00',
        type: 'success'
      },
      {
        id: 3,
        description: 'user1 录入了血糖数据',
        time: '2024-01-01 14:00:00',
        type: 'warning'
      }
    ]
  } finally {
    activitiesLoading.value = false
  }
}

// 根据活动类型返回对应的时间线类型
const getActivityType = (activityType: string) => {
  switch (activityType) {
    case 'experiment_create':
    case 'experiment_update':
      return 'primary'
    case 'batch_create':
    case 'person_create':
      return 'success'
    case 'data_export':
      return 'warning'
    case 'experiment_delete':
      return 'danger'
    default:
      return 'info'
  }
}

// 定时刷新活动数据
let refreshInterval: number | null = null

onMounted(async () => {
  // 分步加载：先加载统计数据，再加载活动数据
  // 这样用户可以更快看到主要内容
  await fetchDashboardStats()
  
  // 延迟加载活动数据，避免阻塞主要内容
  setTimeout(async () => {
    await fetchRecentActivities()
    // 每60秒刷新一次活动数据（降低频率）
    refreshInterval = setInterval(fetchRecentActivities, 60000)
  }, 100)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
.dashboard {
  max-width: 1200px;
  margin: 0 auto;
}

.dashboard-header {
  margin-bottom: 24px;
}

.dashboard-header h1 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 28px;
  font-weight: 600;
}

.dashboard-header p {
  margin: 0;
  color: #909399;
  font-size: 16px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}

.stat-card {
  cursor: pointer;
  transition: all 0.3s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.batch-card .stat-icon {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.person-card .stat-icon {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.experiment-card .stat-icon {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.data-card .stat-icon {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.stat-info {
  flex: 1;
}

.stat-number {
  font-size: 32px;
  font-weight: 600;
  color: #303133;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.quick-actions {
  margin-bottom: 24px;
}

.card-header {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.action-buttons {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.action-buttons .el-button {
  flex: 1;
  min-width: 120px;
}

.recent-activity {
  margin-bottom: 24px;
}

:deep(.el-timeline-item__timestamp) {
  color: #909399;
  font-size: 12px;
}

/* 骨架屏样式 */
.activity-skeleton {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.activity-content {
  flex: 1;
}

.is-loading {
  animation: rotating 2s linear infinite;
}

@keyframes rotating {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

/* 统计卡片骨架屏优化 */
.stat-card .el-skeleton {
  padding: 0;
}

.stat-card .stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}
</style>