import { GameProgress, LoadResult, SaveResult } from '../model/GameTypes';
import { encodeSave, decodeSave } from './SaveCodec';

// Platform-free interface: module tests can inject a deterministic storage stub.
export interface TextStorage {
  read(): Promise<string>;
  write(value: string): Promise<void>;
}

export class SaveRepository {
  private storage: TextStorage;
  private pending: Promise<void> = Promise.resolve();

  constructor(storage: TextStorage) { this.storage = storage; }

  async load(): Promise<LoadResult> {
    try { return decodeSave(await this.storage.read()); }
    catch { return { progress: null, warning: '本地存档暂时无法读取，请稍后重试。' }; }
  }

  async save(progress: GameProgress): Promise<SaveResult> {
    try {
      // Take the snapshot before awaiting. Queue writes to preserve user-operation order.
      const snapshot: string = encodeSave(progress);
      const task: Promise<void> = this.pending.then(() => this.storage.write(snapshot));
      this.pending = task.catch(() => {});
      await task;
      return { success: true, message: '进度已保存' };
    } catch {
      return { success: false, message: '保存失败，请保持应用打开并重试。' };
    }
  }
}
