<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h2>实验数据管理系统</h2>
        <div class="mode-switch">
          <el-button
            :type="isLoginMode ? 'primary' : 'default'"
            size="small"
            @click="switchToLogin"
          >
            登录
          </el-button>
          <el-button
            :type="!isLoginMode ? 'primary' : 'default'"
            size="small"
            @click="switchToRegister"
          >
            注册账号
          </el-button>
        </div>
      </div>
      
      <!-- 登录表单 -->
      <el-form
        v-if="isLoginMode"
        ref="loginFormRef"
        :model="loginForm"
        :rules="loginRules"
        class="login-form"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginForm.username"
            placeholder="请输入用户名"
            size="large"
            :prefix-icon="User"
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入密码"
            size="large"
            :prefix-icon="Lock"
            show-password
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            class="login-button"
            :loading="loading"
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form-item>
      </el-form>
      
      <!-- 注册表单 -->
      <el-form
        v-else
        ref="registerFormRef"
        :model="registerForm"
        :rules="registerRules"
        class="login-form"
        @submit.prevent="handleRegister"
      >
        <el-form-item prop="username">
          <el-input
            v-model="registerForm.username"
            placeholder="请输入用户名"
            size="large"
            :prefix-icon="User"
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="registerForm.password"
            type="password"
            placeholder="请输入密码"
            size="large"
            :prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <el-form-item prop="confirmPassword">
          <el-input
            v-model="registerForm.confirmPassword"
            type="password"
            placeholder="请确认密码"
            size="large"
            :prefix-icon="Lock"
            show-password
            @keyup.enter="handleRegister"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            class="login-button"
            :loading="loading"
            @click="handleRegister"
          >
            注册
          </el-button>
        </el-form-item>
      </el-form>
      
      <!-- <div class="login-tips">
        <p>默认账号：admin</p>
        <p>默认密码：admin123</p>
      </div> -->
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, type FormInstance } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { useAuthStore } from '../stores/auth'
import { userApi } from '@/services/api'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const loginFormRef = ref<FormInstance>()
const registerFormRef = ref<FormInstance>()
const loading = ref(false)
const isLoginMode = ref(true)

const loginForm = reactive({
  username: '',
  password: ''
})

const registerForm = reactive({
  username: '',
  password: '',
  confirmPassword: ''
})

const loginRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ]
}

const validateConfirmPassword = (rule: any, value: any, callback: any) => {
  if (value === '') {
    callback(new Error('请确认密码'))
  } else if (value !== registerForm.password) {
    callback(new Error('两次输入密码不一致'))
  } else {
    callback()
  }
}

const registerRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, message: '用户名长度不能少于3位', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const switchToLogin = () => {
  isLoginMode.value = true
  // 清空表单
  loginForm.username = ''
  loginForm.password = ''
}

const switchToRegister = () => {
  isLoginMode.value = false
  // 清空表单
  registerForm.username = ''
  registerForm.password = ''
  registerForm.confirmPassword = ''
}

const handleLogin = async () => {
  if (!loginFormRef.value) return
  
  await loginFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      
      try {
        const success = await authStore.login(loginForm.username, loginForm.password)
        
        if (success) {
          ElMessage.success('登录成功')
          
          // 检查是否有重定向参数
          const redirect = route.query.redirect as string
          if (redirect && redirect !== '/login') {
            router.push(redirect)
          } else {
            router.push('/dashboard')
          }
        } else {
          ElMessage.error('用户名或密码错误')
        }
      } catch (error) {
        console.error('登录错误:', error)
        ElMessage.error('登录失败，请稍后重试')
      } finally {
        loading.value = false
      }
    }
  })
}

const handleRegister = async () => {
  if (!registerFormRef.value) return
  
  await registerFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      
      try {
        const response = await userApi.register({
          username: registerForm.username,
          password: registerForm.password
        })
        
        if (response) {
          // 注册成功，自动登录
          const { access_token, user_info } = response
          
          // 保存token和用户信息
          localStorage.setItem('token', access_token)
          authStore.setUser(user_info)
          authStore.setToken(access_token)
          
          // 显示注册成功提示
          ElMessage({
            message: '注册成功！已自动为您登录',
            type: 'success',
            duration: 3000,
            showClose: true
          })
          
          // 延迟跳转，确保用户能看到提示信息
          setTimeout(() => {
            // 检查是否有重定向参数
            const redirect = route.query.redirect as string
            if (redirect && redirect !== '/login') {
              router.push(redirect)
            } else {
              router.push('/dashboard')
            }
          }, 1500)
        }
      } catch (error: any) {
        console.error('注册错误:', error)
        const errorMessage = error.response?.data?.detail || '注册失败，请稍后重试'
        ElMessage.error(errorMessage)
      } finally {
        loading.value = false
      }
    }
  })
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8fafc;
  padding: 20px;
  position: relative;
}

.login-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.05) 0%, rgba(147, 51, 234, 0.05) 100%);
  pointer-events: none;
}

.login-card {
  width: 100%;
  max-width: 420px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  border: 1px solid #e5e7eb;
  padding: 48px 40px;
  position: relative;
  z-index: 1;
}

.login-header {
  text-align: center;
  margin-bottom: 32px;
}

.login-header h2 {
  color: #1f2937;
  margin: 0 0 20px 0;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: -0.025em;
}

.login-header p {
  color: #6b7280;
  margin: 0;
  font-size: 14px;
}

.mode-switch {
  display: flex;
  gap: 4px;
  justify-content: center;
  margin-bottom: 12px;
  background: #f3f4f6;
  border-radius: 10px;
  padding: 4px;
}

.mode-switch .el-button {
  flex: 1;
  max-width: 90px;
  border: none;
  background: transparent;
  color: #6b7280;
  font-weight: 500;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.mode-switch .el-button.el-button--primary {
  background: white;
  color: #374151;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.login-form {
  margin-bottom: 24px;
}

.login-form .el-form-item {
  margin-bottom: 20px;
}

.login-form .el-input__wrapper {
  border-radius: 10px;
  border: 1.5px solid #e5e7eb;
  transition: all 0.2s ease;
  padding: 12px 16px;
}

.login-form .el-input__wrapper:hover {
  border-color: #d1d5db;
}

.login-form .el-input__wrapper.is-focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.login-button {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 600;
  border-radius: 10px;
  background: #374151;
  border-color: #374151;
  transition: all 0.2s ease;
}

.login-button:hover {
  background: #1f2937;
  border-color: #1f2937;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.login-button:active {
  transform: translateY(0);
}

.login-tips {
  text-align: center;
  padding: 20px;
  background: #f9fafb;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
}

.login-tips p {
  margin: 4px 0;
  color: #6b7280;
  font-size: 13px;
}
</style>