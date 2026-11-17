import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { TextStorage } from './SaveRepository';

export class PreferenceStorage implements TextStorage {
  private context: common.UIAbilityContext;
  constructor(context: common.UIAbilityContext) { this.context = context; }

  async read(): Promise<string> {
    const store: preferences.Preferences = await preferences.getPreferences(this.context, { name: 'zero_hour_library' });
    const value: preferences.ValueType = await store.get('game_save_v1', '');
    return typeof value === 'string' ? value : '{}';
  }

  async write(value: string): Promise<void> {
    const store: preferences.Preferences = await preferences.getPreferences(this.context, { name: 'zero_hour_library' });
    await store.put('game_save_v1', value);
    await store.flush();
  }
}
