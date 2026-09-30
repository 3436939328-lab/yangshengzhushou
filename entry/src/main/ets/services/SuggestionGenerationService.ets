import { DailyWellnessPlan, WellnessSuggestion } from '../model/WellnessModels';

/**
 * 建议生成任务状态
 */
export enum SuggestionTaskStatus {
  PENDING = 'PENDING',           // 待生成
  GENERATING = 'GENERATING',     // 生成中
  SUCCESS = 'SUCCESS',           // 生成成功
  FAILED = 'FAILED',             // 生成失败
  CANCELLED = 'CANCELLED'        // 已取消
}

/**
 * 建议生成任务
 */
export interface SuggestionGenerationTask {
  id: string;
  userId: string;
  date: string;                  // 建议日期 YYYY-MM-DD
  triggerType: 'SCHEDULED' | 'MANUAL' | 'DATA_CHANGE' | 'WEATHER_CHANGE';
  status: SuggestionTaskStatus;
  progress: number;              // 0-100
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  planVersion?: string;          // 生成的建议版本号
  errorMessage?: string;
  retryCount: number;
  maxRetries: number;
}

/**
 * 任务完成状态
 */
export interface TaskCompletionState {
  morningDone: boolean;
  afternoonDone: boolean;
  eveningDone: boolean;
  customDone: Record<string, boolean>;
}

/**
 * 每日建议记录
 */
export interface DailySuggestionRecord {
  date: string;                  // YYYY-MM-DD
  plan: DailyWellnessPlan;
  version: string;               // 版本号，如 v20250929.1
  generatedAt: string;
  generationType: 'SCHEDULED' | 'MANUAL' | 'DATA_CHANGE' | 'WEATHER_CHANGE';
  taskId: string;
  isRead: boolean;
  taskCompletion: TaskCompletionState;
}

/**
 * 今日完成进度
 */
export interface TodayProgress {
  done: number;
  total: number;
  percentage: number;
}

/**
 * 建议生成队列
 */
export class SuggestionGenerationQueue {
  private tasks: SuggestionGenerationTask[] = [];
  private records: Map<string, DailySuggestionRecord> = new Map();
  private currentPlanVersion = 1;

  /**
   * 创建生成任务
   */
  createTask(
    userId: string,
    date: string,
    triggerType: SuggestionGenerationTask['triggerType']
  ): SuggestionGenerationTask {
    const task: SuggestionGenerationTask = {
      id: `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      userId,
      date,
      triggerType,
      status: SuggestionTaskStatus.PENDING,
      progress: 0,
      createdAt: new Date().toISOString(),
      retryCount: 0,
      maxRetries: 3
    };
    this.tasks.unshift(task);
    return task;
  }

  /**
   * 获取指定日期的最新任务
   */
  getLatestTask(userId: string, date: string): SuggestionGenerationTask | null {
    const userTasks = this.tasks.filter(t => t.userId === userId && t.date === date);
    return userTasks.length > 0 ? userTasks[0] : null;
  }

  /**
   * 获取任务列表
   */
  getTaskList(userId: string, limit: number = 10): SuggestionGenerationTask[] {
    return this.tasks
      .filter(t => t.userId === userId)
      .slice(0, limit);
  }

  /**
   * 获取今日建议记录
   */
  getTodayRecord(userId: string): DailySuggestionRecord | null {
    const today = this.getTodayDate();
    const key = `${userId}_${today}`;
    return this.records.get(key) || null;
  }

  /**
   * 获取指定日期的建议记录
   */
  getRecord(userId: string, date: string): DailySuggestionRecord | null {
    const key = `${userId}_${date}`;
    return this.records.get(key) || null;
  }

  /**
   * 保存建议记录
   */
  saveRecord(record: DailySuggestionRecord): void {
    const key = `${record.plan.userId || 'unknown'}_${record.date}`;
    this.records.set(key, record);
  }

  /**
   * 生成版本号
   */
  generateVersion(date: string): string {
    const dateStr = date.replace(/-/g, '');
    const version = `v${dateStr}.${this.currentPlanVersion}`;
    this.currentPlanVersion++;
    return version;
  }

  /**
   * 检查今日是否已生成建议
   */
  hasTodaySuggestion(userId: string): boolean {
    const today = this.getTodayDate();
    const key = `${userId}_${today}`;
    const record = this.records.get(key);
    return !!record;
  }

  /**
   * 检查是否需要重新生成（数据变动后）
   */
  needsRegeneration(userId: string): boolean {
    const today = this.getTodayDate();
    const key = `${userId}_${today}`;
    const record = this.records.get(key);
    // 如果没有记录或数据有重大变化，需要重新生成
    return !record;
  }

  /**
   * 更新任务进度
   */
  updateTaskProgress(taskId: string, progress: number, status?: SuggestionTaskStatus): void {
    const task = this.tasks.find(t => t.id === taskId);
    if (task) {
      task.progress = progress;
      if (status) {
        task.status = status;
        if (status === SuggestionTaskStatus.SUCCESS || status === SuggestionTaskStatus.FAILED) {
          task.completedAt = new Date().toISOString();
        }
      }
    }
  }

  /**
   * 标记任务为成功
   */
  markTaskSuccess(taskId: string, planVersion: string): void {
    const task = this.tasks.find(t => t.id === taskId);
    if (task) {
      task.status = SuggestionTaskStatus.SUCCESS;
      task.progress = 100;
      task.planVersion = planVersion;
      task.completedAt = new Date().toISOString();
    }
  }

  /**
   * 标记任务为失败
   */
  markTaskFailed(taskId: string, errorMessage: string): void {
    const task = this.tasks.find(t => t.id === taskId);
    if (task) {
      task.status = SuggestionTaskStatus.FAILED;
      task.errorMessage = errorMessage;
      task.completedAt = new Date().toISOString();
    }
  }

  /**
   * 重试任务
   */
  retryTask(taskId: string): boolean {
    const task = this.tasks.find(t => t.id === taskId);
    if (!task) return false;
    if (task.retryCount >= task.maxRetries) return false;

    task.retryCount++;
    task.status = SuggestionTaskStatus.PENDING;
    task.progress = 0;
    task.errorMessage = undefined;
    task.startedAt = undefined;
    task.completedAt = undefined;
    return true;
  }

  /**
   * 标记建议为已读
   */
  markAsRead(userId: string, date: string): void {
    const key = `${userId}_${date}`;
    const record = this.records.get(key);
    if (record) {
      record.isRead = true;
    }
  }

  /**
   * 切换任务完成状态
   */
  toggleTaskDone(
    userId: string,
    date: string,
    period: 'morning' | 'afternoon' | 'evening' | string,
    isCustom: boolean = false
  ): boolean {
    const key = `${userId}_${date}`;
    const record = this.records.get(key);
    if (!record) return false;

    if (isCustom) {
      record.taskCompletion.customDone[period] = !record.taskCompletion.customDone[period];
    } else {
      if (period === 'morning') {
        record.taskCompletion.morningDone = !record.taskCompletion.morningDone;
      } else if (period === 'afternoon') {
        record.taskCompletion.afternoonDone = !record.taskCompletion.afternoonDone;
      } else if (period === 'evening') {
        record.taskCompletion.eveningDone = !record.taskCompletion.eveningDone;
      }
    }
    return true;
  }

  /**
   * 获取今日完成进度
   */
  getTodayProgress(userId: string): TodayProgress {
    const today = this.getTodayDate();
    const key = `${userId}_${today}`;
    const record = this.records.get(key);

    if (!record) {
      return { done: 0, total: 0, percentage: 0 } as TodayProgress;
    }

    let done = 0;
    let total = 0;

    if (record.plan.morningRoutine && record.plan.morningRoutine.length > 0) {
      total++;
      if (record.taskCompletion.morningDone) done++;
    }
    if (record.plan.afternoonRoutine && record.plan.afternoonRoutine.length > 0) {
      total++;
      if (record.taskCompletion.afternoonDone) done++;
    }
    if (record.plan.eveningRoutine && record.plan.eveningRoutine.length > 0) {
      total++;
      if (record.taskCompletion.eveningDone) done++;
    }

    const customCount = Object.keys(record.taskCompletion.customDone).length;
    total += customCount;
    done += Object.values(record.taskCompletion.customDone).filter(Boolean).length;

    return {
      done,
      total,
      percentage: total > 0 ? Math.round((done / total) * 100) : 0
    } as TodayProgress;
  }

  private getTodayDate(): string {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
}

// 单例
const suggestionQueue = new SuggestionGenerationQueue();
export function getSuggestionGenerationQueue(): SuggestionGenerationQueue {
  return suggestionQueue;
}

/**
 * 建议触发条件检查服务
 */
export class SuggestionTriggerService {
  private queue: SuggestionGenerationQueue;

  constructor() {
    this.queue = getSuggestionGenerationQueue();
  }

  /**
   * 检查是否应该自动生成今日建议
   * 触发条件：
   * 1. 每日定时（早上6点后）
   * 2. 健康数据有重大变化
   * 3. 天气有明显变化
   */
  shouldGenerateTodaySuggestion(
    userId: string,
    lastDataChangeAt?: string,
    lastWeatherChangeAt?: string
  ): boolean {
    const now = new Date();
    const hour = now.getHours();

    // 早上6点后，如果今日还没有建议，则生成
    if (hour >= 6 && !this.queue.hasTodaySuggestion(userId)) {
      return true;
    }

    // 健康数据有重大变化（2小时内有新数据）
    if (lastDataChangeAt) {
      const changeTime = new Date(lastDataChangeAt).getTime();
      const twoHoursAgo = now.getTime() - 2 * 60 * 60 * 1000;
      if (changeTime > twoHoursAgo && this.queue.needsRegeneration(userId)) {
        return true;
      }
    }

    return false;
  }

  /**
   * 触发定时生成
   */
  triggerScheduledGeneration(userId: string): SuggestionGenerationTask {
    const date = this.getTodayDate();
    return this.queue.createTask(userId, date, 'SCHEDULED');
  }

  /**
   * 触发生成（数据变动）
   */
  triggerDataChangeGeneration(userId: string): SuggestionGenerationTask {
    const date = this.getTodayDate();
    return this.queue.createTask(userId, date, 'DATA_CHANGE');
  }

  /**
   * 触发生成（天气变动）
   */
  triggerWeatherChangeGeneration(userId: string): SuggestionGenerationTask {
    const date = this.getTodayDate();
    return this.queue.createTask(userId, date, 'WEATHER_CHANGE');
  }

  /**
   * 手动触发生成
   */
  triggerManualGeneration(userId: string): SuggestionGenerationTask {
    const date = this.getTodayDate();
    return this.queue.createTask(userId, date, 'MANUAL');
  }

  private getTodayDate(): string {
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
}

// 单例
const suggestionTriggerService = new SuggestionTriggerService();
export function getSuggestionTriggerService(): SuggestionTriggerService {
  return suggestionTriggerService;
}
