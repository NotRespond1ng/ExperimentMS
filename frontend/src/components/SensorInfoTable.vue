<template>
  <div class="sensors-cell">
    <div v-if="sensors && sensors.length > 0" class="sensors-group">
      <div class="sensors-header">
        <el-icon class="group-icon"><Monitor /></el-icon>
        <span class="sensor-count">{{ sensors.length }}个传感器</span>
      </div>
      <div class="sensors-table">
        <div class="sensors-table-header">
          <div class="sensor-col sensor-col-name">传感器</div>
          <div class="sensor-col sensor-col-field">佩戴位置</div>
          <div class="sensor-col sensor-col-field">用户名称</div>
          <div class="sensor-col sensor-col-field">敷贴器批号</div>
          <div class="sensor-col sensor-col-field">传感器批号</div>
          <div class="sensor-col sensor-col-field">传感器批次</div>
          <div class="sensor-col sensor-col-field">传感器号</div>
          <div class="sensor-col sensor-col-field">发射器号</div>
          <div class="sensor-col sensor-col-time">佩戴开始</div>
          <div class="sensor-col sensor-col-time">佩戴结束</div>
          <div class="sensor-col sensor-col-test-params">测试参数</div>
          <div class="sensor-col sensor-col-abnormal">异常情况</div>
          <div class="sensor-col sensor-col-analysis">原因分析</div>
        </div>
        <div 
          v-for="(sensor, index) in sensors" 
          :key="sensor.wear_record_id"
          class="sensors-table-row"
        >
          <div class="sensor-col sensor-col-name">
            <div class="sensor-item-compact">
              <div class="sensor-avatar">
                {{ getSensorDisplayName(sensor).charAt(0) || 'S' }}
              </div>
              <div class="sensor-info-compact">
                <div class="sensor-test">{{ getSensorDisplayName(sensor) }}</div>
                <div class="sensor-probe">{{ getSensorDisplaySubName(sensor) }}</div>
              </div>
            </div>
          </div>
          <div class="sensor-col sensor-col-field">
            <el-tag v-if="sensor.wear_position" type="primary" size="small">
              {{ sensor.wear_position }}
            </el-tag>
            <span v-else class="field-value">-</span>
          </div>
          <div class="sensor-col sensor-col-field">
            <span class="field-value user-name">{{ sensor.nickname || '-' }}</span>
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
          <div class="sensor-col sensor-col-time">
            <span class="field-value" :class="sensor.wear_end_time && sensor.wear_end_time.trim() !== '' ? 'wear-end-time' : 'time-not-ended'">
              {{ sensor.wear_end_time && sensor.wear_end_time.trim() !== '' ? formatSimpleDate(sensor.wear_end_time) : '进行中' }}
            </span>
          </div>
          <div class="sensor-col sensor-col-test-params">
            <div class="test-params-container">
              <div class="test-values">
                <div class="test-value-item">
                  <span class="test-label">0.00:</span>
                  <span class="test-value">{{ formatTestValue(sensor.sensor_detail?.value_0) }}</span>
                </div>
                <div class="test-value-item">
                  <span class="test-label">2.00:</span>
                  <span class="test-value">{{ formatTestValue(sensor.sensor_detail?.value_2) }}</span>
                </div>
                <div class="test-value-item">
                  <span class="test-label">5.00:</span>
                  <span class="test-value">{{ formatTestValue(sensor.sensor_detail?.value_5) }}</span>
                </div>
                <div class="test-value-item">
                  <span class="test-label">25.00:</span>
                  <span class="test-value">{{ formatTestValue(sensor.sensor_detail?.value_25) }}</span>
                </div>
              </div>
              <div class="sensitivity-params">
                <div class="sensitivity-item">
                  <span class="sensitivity-label">初始灵敏度:</span>
                  <span class="sensitivity-value">{{ formatSensitivity(sensor.sensor_detail?.sensitivity) }}</span>
                </div>
                <div class="r-value-item">
                  <span class="r-label">R值:</span>
                  <el-tag 
                    v-if="sensor.sensor_detail?.r_value" 
                    :type="getRValueType(sensor.sensor_detail.r_value)" 
                    size="small"
                  >
                    {{ formatRValue(sensor.sensor_detail.r_value) }}
                  </el-tag>
                  <span v-else class="r-value-empty">-</span>
                </div>
              </div>
            </div>
          </div>
          <div class="sensor-col sensor-col-abnormal">
            <span v-if="sensor.abnormal_situation" class="abnormal-tag">{{ sensor.abnormal_situation }}</span>
            <span v-else class="field-value">-</span>
          </div>
          <div class="sensor-col sensor-col-analysis">
            <span class="field-value reason-analysis" :title="sensor.cause_analysis">{{ sensor.cause_analysis || '-' }}</span>
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

<script setup lang="ts">
import { Monitor, Location } from '@element-plus/icons-vue'
import { watchEffect } from 'vue'

interface SensorDetail {
  sensor_detail_id: number
  test_number: string
  probe_number: string
  value_0?: number
  value_2?: number
  value_5?: number
  value_25?: number
  sensitivity?: number
  r_value?: number
}

interface WearRecord {
  wear_record_id: number
  wear_record_name?: string
  user_name?: string
  nickname?: string
  wear_position?: string
  test_number?: string
  probe_number?: string
  applicator_lot_no?: string
  sensor_lot_no?: string
  sensor_batch?: string
  sensor_number?: string
  transmitter_id?: string
  wear_time: string
  wear_end_time?: string
  abnormal_situation?: string
  cause_analysis?: string
  sensor_detail?: SensorDetail
}

interface Props {
  sensors: WearRecord[]
}

const props = defineProps<Props>()

// 获取传感器显示名称
const getSensorDisplayName = (sensor: WearRecord): string => {
  if (sensor.sensor_detail?.test_number) {
    return sensor.sensor_detail.test_number
  }
  if (sensor.sensor_batch) {
    return sensor.sensor_batch
  }
  if (sensor.sensor_number) {
    return sensor.sensor_number
  }
  return '未知传感器'
}

// 获取传感器显示副名称
const getSensorDisplaySubName = (sensor: WearRecord): string => {
  if (sensor.sensor_detail?.probe_number) {
    return sensor.sensor_detail.probe_number
  }
  if (sensor.sensor_detail?.test_number && sensor.sensor_batch) {
    return sensor.sensor_batch
  }
  if (sensor.sensor_number && sensor.sensor_batch !== sensor.sensor_number) {
    return sensor.sensor_number
  }
  return '-'
}

// 格式化简单日期
const formatSimpleDate = (date: string | Date | null | undefined): string => {
  if (!date) return '-'
  try {
    const dateObj = new Date(date)
    if (isNaN(dateObj.getTime())) return '-'
    return dateObj.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    })
  } catch {
    return '-'
  }
}

// 格式化测试值
const formatTestValue = (value: number | null | undefined): string => {
  if (value === null || value === undefined) return '-'
  return Number(value).toFixed(2)
}

// 格式化灵敏度
const formatSensitivity = (value: number | null | undefined): string => {
  if (value === null || value === undefined) return '-'
  return Number(value).toFixed(6)
}

// 格式化R值
const formatRValue = (value: number | null | undefined): string => {
  if (value === null || value === undefined) return '-'
  return Number(value).toFixed(4)
}

// 获取R值类型
const getRValueType = (rValue: number | null | undefined): string => {
  if (!rValue) return 'info'
  if (rValue >= 0.95) return 'success'
  if (rValue >= 0.90) return 'warning'
  return 'danger'
}
</script>

<style scoped lang="scss">
.sensors-cell {
  width: 100%;
}

.sensors-group {
  .sensors-header {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
    
    .group-icon {
      margin-right: 6px;
      color: #409eff;
    }
    
    .sensor-count {
      font-size: 14px;
      color: #606266;
      font-weight: 500;
    }
  }
}

.sensors-table {
  border: 1px solid #ebeef5;
  border-radius: 4px;
  overflow-x: auto;
  overflow-y: hidden;
  min-width: 100%;
  
  .sensors-table-header {
    display: flex;
    background-color: #f5f7fa;
    border-bottom: 1px solid #ebeef5;
    
    .sensor-col {
      padding: 8px 6px;
      font-size: 14px;
      font-weight: 600;
      color: #303133;
      border-right: 1px solid #ebeef5;
      text-align: center;
      white-space: nowrap;
      
      &:last-child {
        border-right: none;
      }
      
      &.sensor-col-name {
        width: 140px;
        min-width: 140px;
      }
      
      &.sensor-col-field {
        width: 120px;
        min-width: 120px;
      }
      
      &.sensor-col-abnormal {
        width: 170px;
        min-width: 170px;
      }
      
      &.sensor-col-analysis {
        width: 200px;
        min-width: 200px;
      }
      
      &.sensor-col-time {
        width: 150px;
        min-width: 150px;
      }
      
      &.sensor-col-test-params {
        width: 220px;
        min-width: 220px;
      }
    }
  }
  
  .sensors-table-row {
    display: flex;
    border-bottom: 1px solid #ebeef5;
    
    &:last-child {
      border-bottom: none;
    }
    
    &:hover {
      background-color: #f5f7fa;
    }
    
    .sensor-col {
      padding: 8px 6px;
      font-size: 13px;
      border-right: 1px solid #ebeef5;
      display: flex;
      align-items: center;
      justify-content: center;
      white-space: nowrap;
      
      &:last-child {
        border-right: none;
      }
      
      &.sensor-col-name {
        width: 140px;
        min-width: 140px;
        justify-content: flex-start;
      }
      
      &.sensor-col-field {
        width: 120px;
        min-width: 120px;
      }
      
      &.sensor-col-abnormal {
        width: 170px;
        min-width: 170px;
        white-space: normal;
        align-items: center;
        padding: 8px 6px;
      }
      
      &.sensor-col-analysis {
        width: 200px;
        min-width: 200px;
        white-space: normal;
        align-items: center;
        padding: 8px 6px;
      }
      
      &.sensor-col-time {
        width: 150px;
        min-width: 150px;
      }
      
      &.sensor-col-test-params {
        width: 220px;
        min-width: 220px;
        padding: 6px 4px;
      }
    }
  }
}

.sensor-item-compact {
  display: flex;
  align-items: center;
  
  .sensor-avatar {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 10px;
    font-weight: bold;
    margin-right: 6px;
    flex-shrink: 0;
  }
  
  .sensor-info-compact {
    flex: 1;
    min-width: 0;
    
    .sensor-test {
      font-size: 13px;
      font-weight: 600;
      color: #303133;
      line-height: 1.2;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    
    .sensor-probe {
      font-size: 12px;
      color: #909399;
      line-height: 1.2;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  }
}

.field-value {
  color: #606266;
  font-size: 13px;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  
  &.wear-record-name {
    font-weight: 500;
    color: #303133;
  }
  
  &.user-name {
    color: #409eff;
    font-weight: 500;
  }
  
  &.wear-end-time {
    color: #67c23a;
  }
  
  &.time-not-ended {
    color: #e6a23c;
    font-style: italic;
  }
  
  &.reason-analysis {
    white-space: normal;
    word-wrap: break-word;
    word-break: break-all;
    text-overflow: unset;
    overflow: visible;
    line-height: 1.4;
    text-align: left;
  }
}



.test-params-container {
  width: 100%;
  
  .test-values {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2px;
    margin-bottom: 4px;
    
    .test-value-item {
      display: flex;
      align-items: center;
      font-size: 12px;
      
      .test-label {
        color: #909399;
        margin-right: 2px;
        font-weight: 500;
      }
      
      .test-value {
        color: #303133;
        font-weight: 600;
      }
    }
  }
  
  .sensitivity-params {
    display: flex;
    flex-direction: column;
    gap: 2px;
    
    .sensitivity-item,
    .r-value-item {
      display: flex;
      align-items: center;
      font-size: 12px;
      
      .sensitivity-label,
      .r-label {
        color: #909399;
        margin-right: 2px;
        font-weight: 500;
      }
      
      .sensitivity-value {
        color: #303133;
        font-weight: 600;
      }
      
      .r-value-empty {
        color: #c0c4cc;
      }
    }
  }
}

.abnormal-tag {
  background-color: #fef0f0;
  color: #f56c6c;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 12px;
  font-weight: 500;
  border: 1px solid #fbc4c4;
  white-space: normal;
  word-wrap: break-word;
  word-break: break-all;
  line-height: 1.4;
  display: inline-block;
  max-width: 100%;
}

.no-sensors {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  color: #909399;
  font-size: 14px;
  
  .el-icon {
    margin-right: 6px;
  }
}
</style>