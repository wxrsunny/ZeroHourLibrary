import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { gameSession } from '../storage/GameSession';

export default class EntryAbility extends UIAbility {
  onCreate(): void { AppStorage.setOrCreate('libraryForeground', true); }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
    windowStage.getMainWindow().then((main: window.Window) => {
      main.setWindowSystemBarProperties({ statusBarColor: '#F6EEDC', statusBarContentColor: '#203E3B',
        navigationBarColor: '#F6EEDC', navigationBarContentColor: '#203E3B' });
    }).catch(() => { hilog.warn(0x0000, 'ZeroHourLibrary', 'System bar styling unavailable'); });
  }

  onForeground(): void { AppStorage.setOrCreate('libraryForeground', true); }

  onBackground(): void {
    AppStorage.setOrCreate('libraryForeground', false);
    if (gameSession.hasSave) {
      gameSession.save().then((result) => {
        if (!result.success) { gameSession.warning = result.message; hilog.error(0x0000, 'ZeroHourLibrary', 'Background save failed'); }
      });
    }
  }
}
