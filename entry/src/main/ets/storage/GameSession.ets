import { common } from '@kit.AbilityKit';
import { GameProgress, SaveResult, LoadResult, createProgress } from '../model/GameTypes';
import { SaveRepository } from './SaveRepository';
import { PreferenceStorage } from './PreferenceStorage';

class GameSession {
  progress: GameProgress = createProgress();
  hasSave: boolean = false;
  warning: string = '';
  private repository: SaveRepository | null = null;
  private initialized: boolean = false;

  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) { return; }
    this.repository = new SaveRepository(new PreferenceStorage(context));
    const loaded: LoadResult = await this.repository.load();
    this.warning = loaded.warning;
    this.hasSave = loaded.progress !== null;
    if (loaded.progress !== null) { this.progress = loaded.progress; }
    this.initialized = true;
  }

  async save(): Promise<SaveResult> {
    if (this.repository === null) { return { success: false, message: '存储尚未就绪，请稍后重试。' }; }
    const result: SaveResult = await this.repository.save(this.progress);
    if (result.success) { this.hasSave = true; }
    this.warning = result.success ? '' : result.message;
    return result;
  }
}

export const gameSession: GameSession = new GameSession();
