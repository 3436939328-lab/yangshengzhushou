import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ChatMessage } from '../model/WellnessModels';
import { getAssistantMessages } from './WellnessContentService';

const CHAT_HISTORY_KEY: string = 'assistant_chat_history';
const MAX_CHAT_HISTORY_COUNT: number = 30;

export interface PendingChatRequest { id: string; question: string; }

export interface ChatHistoryStorageAdapter {
  read(key: string): Promise<string>;
  write(key: string, value: string): Promise<void>;
  remove(key: string): Promise<void>;
}

export class MemoryChatHistoryStorageAdapter implements ChatHistoryStorageAdapter {
  private values: Map<string, string> = new Map<string, string>();

  async read(key: string): Promise<string> {
    return this.values.get(key) || '';
  }

  async write(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }

  async remove(key: string): Promise<void> {
    this.values.delete(key);
  }
}

export class PreferencesChatHistoryStorageAdapter implements ChatHistoryStorageAdapter {
  private context: common.UIAbilityContext;
  private storeName: string;

  constructor(context: common.UIAbilityContext, storeName: string = 'wellness_chat_history') {
    this.context = context;
    this.storeName = storeName;
  }

  async read(key: string): Promise<string> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      const value = store.getSync(key, '');
      return typeof value === 'string' ? value : '';
    } catch (error) {
      throw new Error('对话记录读取失败，请检查设备存储');
    }
  }

  async write(key: string, value: string): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      store.putSync(key, value);
      await store.flush();
    } catch (error) {
      throw new Error('对话记录保存失败，请检查设备存储');
    }
  }

  async remove(key: string): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      store.deleteSync(key);
      await store.flush();
    } catch (error) {
      throw new Error('对话记录更新失败，请检查设备存储');
    }
  }
}

export function trimChatHistory(messages: ChatMessage[]): ChatMessage[] {
  if (messages.length <= MAX_CHAT_HISTORY_COUNT) {
    return messages;
  }
  return messages.slice(messages.length - MAX_CHAT_HISTORY_COUNT);
}

export function serializeChatHistory(messages: ChatMessage[]): string {
  return JSON.stringify(trimChatHistory(messages));
}

export function deserializeChatHistory(value: string): ChatMessage[] {
  try {
    const parsed = JSON.parse(value) as ChatMessage[];
    if (Array.isArray(parsed) && parsed.length > 0) {
      const messages = parsed.filter((item: ChatMessage) => item.content !== '你好，我会把你的问题、当前位置天气和健康档案发送给后端大模型生成建议。');
      return trimChatHistory(messages.map((item: ChatMessage, index: number) => {
        item.id = item.id || `saved-${index}`;
        return item;
      }));
    }
  } catch (error) {
    return getAssistantMessages();
  }
  return getAssistantMessages();
}

export class ChatHistoryRepository {
  private storage: ChatHistoryStorageAdapter;

  constructor(storage: ChatHistoryStorageAdapter) {
    this.storage = storage;
  }

  async loadPending(): Promise<PendingChatRequest | null> {
    const value = await this.storage.read('pending_chat');
    if (value.length === 0) return null;
    const pending = JSON.parse(value) as PendingChatRequest;
    if (!pending || typeof pending.id !== 'string' || pending.id.length === 0 || typeof pending.question !== 'string') {
      throw new Error('待确认问答记录无法读取');
    }
    return pending;
  }

  async savePending(value: PendingChatRequest): Promise<void> {
    await this.storage.write('pending_chat', JSON.stringify(value));
  }

  async clearPending(): Promise<void> { await this.storage.remove('pending_chat'); }

  async loadMessages(): Promise<ChatMessage[]> {
    const stored = await this.storage.read(CHAT_HISTORY_KEY);
    if (stored.length === 0) {
      return getAssistantMessages();
    }
    return deserializeChatHistory(stored);
  }

  async saveMessages(messages: ChatMessage[]): Promise<ChatMessage[]> {
    const nextMessages = trimChatHistory(messages);
    await this.storage.write(CHAT_HISTORY_KEY, serializeChatHistory(nextMessages));
    return nextMessages;
  }

  async clearMessages(): Promise<ChatMessage[]> {
    await this.storage.remove(CHAT_HISTORY_KEY);
    return getAssistantMessages();
  }
}

export function buildScopedChatHistoryStoreName(scope: string): string {
  const trimmedScope = scope.trim();
  if (trimmedScope.length === 0) {
    return 'wellness_chat_history';
  }
  return `wellness_chat_history_${trimmedScope}`;
}

export function createPreferencesChatHistoryRepository(
  context: common.UIAbilityContext,
  profileScope: string = ''
): ChatHistoryRepository {
  return new ChatHistoryRepository(new PreferencesChatHistoryStorageAdapter(context, buildScopedChatHistoryStoreName(profileScope)));
}
