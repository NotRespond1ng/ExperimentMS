import { defineStore } from 'pinia'
import { ref } from 'vue'
import { ApiService } from '../services/api'
import type {
  Batch,
  Person,
  Experiment,
  CompetitorFile,
  FingerBloodData,
  Sensor,
  SensorDetail
} from '../services/api'

// 重新导出类型
export type {
  Batch,
  Person,
  Experiment,
  CompetitorFile,
  FingerBloodData,
  Sensor,
  SensorDetail
}

export const useDataStore = defineStore('data', () => {
  // 响应式数据
  const batches = ref<Batch[]>([])
  const persons = ref<Person[]>([])
  const experiments = ref<Experiment[]>([])
  const competitorFiles = ref<CompetitorFile[]>([])
  const fingerBloodData = ref<FingerBloodData[]>([])
  const sensors = ref<Sensor[]>([])
  const sensorDetails = ref<SensorDetail[]>([])
  
  // 加载状态
  const loading = ref(false)
  const error = ref<string | null>(null)
  
  // 数据缓存状态跟踪
  const dataLoaded = ref({
    batches: false,
    persons: false,
    experiments: false,
    competitorFiles: false,
    fingerBloodData: false,
    sensors: false,
    sensorDetails: false,
    initialized: false
  })
  
  // 最后加载时间戳，用于缓存过期检查
  const lastLoadTime = ref<Record<string, number>>({})
  
  // 缓存过期时间（5分钟）
  const CACHE_EXPIRE_TIME = 5 * 60 * 1000

  // 检查缓存是否过期
  const isCacheExpired = (dataType: string): boolean => {
    const lastLoad = lastLoadTime.value[dataType]
    if (!lastLoad) return true
    return Date.now() - lastLoad > CACHE_EXPIRE_TIME
  }
  
  // 单独加载各类数据的方法
  const loadBatches = async (force = false) => {
    if (!force && dataLoaded.value.batches && !isCacheExpired('batches')) {
      return batches.value
    }
    
    try {
      const data = await ApiService.getBatches()
      batches.value = data
      dataLoaded.value.batches = true
      lastLoadTime.value.batches = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load batches:', err)
      throw err
    }
  }
  
  const loadPersons = async (force = false) => {
    if (!force && dataLoaded.value.persons && !isCacheExpired('persons')) {
      return persons.value
    }
    
    try {
      const data = await ApiService.getPersons()
      persons.value = data
      dataLoaded.value.persons = true
      lastLoadTime.value.persons = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load persons:', err)
      throw err
    }
  }
  
  const loadExperiments = async (force = false) => {
    if (!force && dataLoaded.value.experiments && !isCacheExpired('experiments')) {
      return experiments.value
    }
    
    try {
      const data = await ApiService.getExperiments()
      experiments.value = data
      dataLoaded.value.experiments = true
      lastLoadTime.value.experiments = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load experiments:', err)
      throw err
    }
  }
  
  const loadCompetitorFiles = async (force = false) => {
    if (!force && dataLoaded.value.competitorFiles && !isCacheExpired('competitorFiles')) {
      return competitorFiles.value
    }
    
    try {
      const data = await ApiService.getCompetitorFiles()
      competitorFiles.value = data
      dataLoaded.value.competitorFiles = true
      lastLoadTime.value.competitorFiles = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load competitor files:', err)
      throw err
    }
  }
  
  const loadFingerBloodData = async (force = false) => {
    if (!force && dataLoaded.value.fingerBloodData && !isCacheExpired('fingerBloodData')) {
      return fingerBloodData.value
    }
    
    try {
      const data = await ApiService.getFingerBloodData()
      fingerBloodData.value = data
      dataLoaded.value.fingerBloodData = true
      lastLoadTime.value.fingerBloodData = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load finger blood data:', err)
      throw err
    }
  }
  
  const loadSensors = async (force = false) => {
    if (!force && dataLoaded.value.sensors && !isCacheExpired('sensors')) {
      return sensors.value
    }
    
    try {
      const data = await ApiService.getSensors()
      sensors.value = data
      dataLoaded.value.sensors = true
      lastLoadTime.value.sensors = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load sensors:', err)
      throw err
    }
  }

  const loadSensorDetails = async (force = false) => {
    if (!force && dataLoaded.value.sensorDetails && !isCacheExpired('sensorDetails')) {
      return sensorDetails.value
    }
    
    try {
      const data = await ApiService.getSensorDetails()
      sensorDetails.value = data
      dataLoaded.value.sensorDetails = true
      lastLoadTime.value.sensorDetails = Date.now()
      return data
    } catch (err) {
      console.error('Failed to load sensor details:', err)
      throw err
    }
  }
  
  // 优化后的初始化数据方法
  const initializeData = async (force = false) => {
    // 如果已经初始化且未过期，直接返回
    if (!force && dataLoaded.value.initialized && !isCacheExpired('initialized')) {
      return
    }
    
    try {
      loading.value = true
      error.value = null
      
      // 只加载核心数据，其他数据按需加载
      await Promise.all([
        loadBatches(force),
        loadPersons(force)
      ])
      
      dataLoaded.value.initialized = true
      lastLoadTime.value.initialized = Date.now()
    } catch (err) {
      error.value = err instanceof Error ? err.message : '加载数据失败'
      console.error('Failed to initialize data:', err)
    } finally {
      loading.value = false
    }
  }
  
  // 按需加载所有数据
  const loadAllData = async (force = false) => {
    try {
      loading.value = true
      error.value = null
      
      await Promise.all([
        loadBatches(force),
        loadPersons(force),
        loadExperiments(force),
        loadCompetitorFiles(force),
        loadFingerBloodData(force),
        loadSensors(force)
      ])
    } catch (err) {
      error.value = err instanceof Error ? err.message : '加载数据失败'
      console.error('Failed to load all data:', err)
    } finally {
      loading.value = false
    }
  }

  // 批次管理
  const addBatch = async (batch: Omit<Batch, 'batch_id'>) => {
    try {
      const newBatch = await ApiService.createBatch(batch)
      batches.value.push(newBatch)
      return newBatch
    } catch (err: any) {
      // 提取后端返回的具体错误信息
      const errorMessage = err?.response?.data?.detail || err?.message || '创建批次失败'
      error.value = errorMessage
      throw new Error(errorMessage)
    }
  }

  const updateBatch = async (id: number, batch: Partial<Batch>) => {
    try {
      const updatedBatch = await ApiService.updateBatch(id, batch)
      const index = batches.value.findIndex(b => b.batch_id === id)
      if (index !== -1) {
        batches.value[index] = updatedBatch
      }
      return updatedBatch
    } catch (err: any) {
      // 提取后端返回的具体错误信息
      const errorMessage = err?.response?.data?.detail || err?.message || '更新批次失败'
      error.value = errorMessage
      throw new Error(errorMessage)
    }
  }

  const deleteBatch = async (id: number) => {
    try {
      await ApiService.deleteBatch(id)
      const index = batches.value.findIndex(b => b.batch_id === id)
      if (index !== -1) {
        batches.value.splice(index, 1)
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : '删除批次失败'
      throw err
    }
  }

  // 人员管理
  const addPerson = async (person: Omit<Person, 'person_id'>) => {
    try {
      const newPerson = await ApiService.createPerson(person)
      persons.value.push(newPerson)
      
      // 添加人员后，重新加载批次数据以更新 person_count
      batches.value = await ApiService.getBatches()
      
      return newPerson
    } catch (err) {
      error.value = err instanceof Error ? err.message : '创建人员失败'
      throw err
    }
  }

  const updatePerson = async (id: number, person: Partial<Person>) => {
    try {
      const updatedPerson = await ApiService.updatePerson(id, person)
      
      // 重新加载完整的人员数据以确保batch_number等关联字段正确显示
      const freshPersonsData = await ApiService.getPersons()
      persons.value = freshPersonsData
      
      // 更新缓存状态
      dataLoaded.value.persons = true
      lastLoadTime.value.persons = Date.now()
      
      return updatedPerson
    } catch (err) {
      error.value = err instanceof Error ? err.message : '更新人员失败'
      throw err
    }
  }

  const deletePerson = async (id: number) => {
    try {
      await ApiService.deletePerson(id)
      const index = persons.value.findIndex(p => p.person_id === id)
      if (index !== -1) {
        persons.value.splice(index, 1)
      }
      
      // 删除人员后，同样重新加载批次数据
      batches.value = await ApiService.getBatches()
      
    } catch (err: any) {
      // 保留原始错误信息，让前端组件处理详细的错误显示
      error.value = err?.response?.data?.detail || err?.message || '删除人员失败'
      throw err
    }
  }

  // 实验管理
  const addExperiment = async (experiment: Omit<Experiment, 'experiment_id'>) => {
    try {
      const newExperiment = await ApiService.createExperiment(experiment)
      experiments.value.push(newExperiment)
      return newExperiment
    } catch (err) {
      error.value = err instanceof Error ? err.message : '创建实验失败'
      throw err
    }
  }

  const updateExperiment = async (id: number, experiment: Partial<Experiment>) => {
    try {
      const updatedExperiment = await ApiService.updateExperiment(id, experiment)
      const index = experiments.value.findIndex(e => e.experiment_id === id)
      if (index !== -1) {
        experiments.value[index] = updatedExperiment
      }
      return updatedExperiment
    } catch (err) {
      error.value = err instanceof Error ? err.message : '更新实验失败'
      throw err
    }
  }

  const deleteExperiment = async (id: number) => {
    try {
      await ApiService.deleteExperiment(id)
      const index = experiments.value.findIndex(e => e.experiment_id === id)
      if (index !== -1) {
        experiments.value.splice(index, 1)
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : '删除实验失败'
      throw err
    }
  }

  // 竞品文件管理
  const addCompetitorFile = async (formData: FormData) => {
    try {
      const newFile = await ApiService.uploadCompetitorFile(formData)
      competitorFiles.value.push(newFile)
      return newFile
    } catch (err) {
      error.value = err instanceof Error ? err.message : '上传竞品文件失败'
      throw err
    }
  }

  const deleteCompetitorFile = async (id: number) => {
    try {
      await ApiService.deleteCompetitorFile(id)
      const index = competitorFiles.value.findIndex(f => f.competitor_file_id === id)
      if (index !== -1) {
        competitorFiles.value.splice(index, 1)
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : '删除竞品文件失败'
      throw err
    }
  }

  // 指尖血数据管理
  const addFingerBloodData = async (data: Omit<FingerBloodData, 'finger_blood_file_id'>) => {
    try {
      const newData = await ApiService.createFingerBloodData(data)
      fingerBloodData.value.push(newData)
      return newData
    } catch (err) {
      error.value = err instanceof Error ? err.message : '创建指尖血数据失败'
      throw err
    }
  }

  const updateFingerBloodData = async (id: number, data: Partial<FingerBloodData>) => {
    try {
      const updatedData = await ApiService.updateFingerBloodData(id, data)
      const index = fingerBloodData.value.findIndex(d => d.finger_blood_file_id === id)
      if (index !== -1) {
        fingerBloodData.value[index] = updatedData
      }
      return updatedData
    } catch (err) {
      error.value = err instanceof Error ? err.message : '更新指尖血数据失败'
      throw err
    }
  }

  const deleteFingerBloodData = async (id: number) => {
    try {
      await ApiService.deleteFingerBloodData(id)
      const index = fingerBloodData.value.findIndex(d => d.finger_blood_file_id === id)
      if (index !== -1) {
        fingerBloodData.value.splice(index, 1)
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : '删除指尖血数据失败'
      throw err
    }
  }

  // 传感器管理
  const addSensor = async (sensor: Omit<Sensor, 'sensor_id'>) => {
    try {
      const newSensor = await ApiService.createSensor(sensor)
      sensors.value.push(newSensor)
      return newSensor
    } catch (err) {
      error.value = err instanceof Error ? err.message : '创建传感器失败'
      throw err
    }
  }

  const updateSensor = async (sensorId: number, updates: Partial<Sensor>) => {
    try {
      const updatedSensor = await ApiService.updateSensor(sensorId, updates)
      const index = sensors.value.findIndex(s => s.sensor_id === sensorId)
      if (index !== -1) {
        sensors.value[index] = updatedSensor
      }
      return updatedSensor
    } catch (err) {
      error.value = err instanceof Error ? err.message : '更新传感器失败'
      throw err
    }
  }

  const deleteSensor = async (sensorId: number) => {
    try {
      await ApiService.deleteSensor(sensorId)
      const index = sensors.value.findIndex(s => s.sensor_id === sensorId)
      if (index !== -1) {
        sensors.value.splice(index, 1)
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : '删除传感器失败'
      throw err
    }
  }

  // 清除特定数据类型的缓存
  const clearCache = (dataType: string) => {
    if (dataType === 'persons') {
      dataLoaded.value.persons = false
      delete lastLoadTime.value.persons
    } else if (dataType === 'batches') {
      dataLoaded.value.batches = false
      delete lastLoadTime.value.batches
    } else if (dataType === 'experiments') {
      dataLoaded.value.experiments = false
      delete lastLoadTime.value.experiments
    } else if (dataType === 'competitorFiles') {
      dataLoaded.value.competitorFiles = false
      delete lastLoadTime.value.competitorFiles
    } else if (dataType === 'fingerBloodData') {
      dataLoaded.value.fingerBloodData = false
      delete lastLoadTime.value.fingerBloodData
    } else if (dataType === 'sensors') {
      dataLoaded.value.sensors = false
      delete lastLoadTime.value.sensors
    } else if (dataType === 'sensorDetails') {
      dataLoaded.value.sensorDetails = false
      delete lastLoadTime.value.sensorDetails
    } else if (dataType === 'all') {
      // 清除所有缓存
      dataLoaded.value = {
        batches: false,
        persons: false,
        experiments: false,
        competitorFiles: false,
        fingerBloodData: false,
        sensors: false,
        sensorDetails: false,
        initialized: false
      }
      lastLoadTime.value = {}
    }
  }

  return {
    // 数据
    batches,
    persons,
    experiments,
    competitorFiles,
    fingerBloodData,
    sensors,
    sensorDetails,
    // 状态
    loading,
    error,
    dataLoaded,
    // 缓存管理
    clearCache,
    // 初始化和数据加载
    initializeData,
    loadAllData,
    loadBatches,
    loadPersons,
    loadExperiments,
    loadCompetitorFiles,
    loadFingerBloodData,
    loadSensors,
    loadSensorDetails,
    // 批次管理
    addBatch,
    updateBatch,
    deleteBatch,
    // 人员管理
    addPerson,
    updatePerson,
    deletePerson,
    // 实验管理
    addExperiment,
    updateExperiment,
    deleteExperiment,
    // 竞品文件管理
    addCompetitorFile,
    deleteCompetitorFile,
    // 指尖血数据管理
    addFingerBloodData,
    updateFingerBloodData,
    deleteFingerBloodData,
    // 传感器管理
    addSensor,
    updateSensor,
    deleteSensor
  }
})