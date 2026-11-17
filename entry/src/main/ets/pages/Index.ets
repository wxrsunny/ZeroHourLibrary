import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { LibraryMap } from '../components/LibraryMap';
import { GameProgress, createProgress } from '../model/GameTypes';
import { gameSession } from '../storage/GameSession';

@Entry
@Component
struct Index {
  @State ready: boolean = false;
  @State hasSave: boolean = false;
  @State endingCount: number = 0;
  @State warning: string = '';
  private preview: GameProgress = createProgress();

  async aboutToAppear(): Promise<void> {
    await gameSession.initialize(getContext(this) as common.UIAbilityContext);
    this.hasSave = gameSession.hasSave;
    this.endingCount = gameSession.progress.unlockedEndings.length;
    this.warning = gameSession.warning;
    this.ready = true;
  }

  async newGame(): Promise<void> {
    gameSession.progress = createProgress(gameSession.progress.unlockedEndings);
    const saved = await gameSession.save();
    if (!saved.success) { this.warning = saved.message; }
    await router.pushUrl({ url: 'pages/Explore' });
  }

  start(): void {
    if (this.hasSave || this.warning !== '') {
      AlertDialog.show({ title: '重新翻开这个故事？', message: '当前探索进度会被覆盖，已解锁的结局会保留。',
        primaryButton: { value: '再想一想', action: () => {} },
        secondaryButton: { value: '开始新游戏', action: () => { this.newGame(); } } });
    } else { this.newGame(); }
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row() {
          Text('旧馆档案 / NO. 001').fontSize(11).fontColor('#786C55').letterSpacing(2)
          Blank()
          Text('23:59').fontSize(16).fontColor('#274E45').fontWeight(FontWeight.Medium)
        }.width('100%').margin({ bottom: 24 })
        Text('零点借阅室').fontSize(38).fontWeight(FontWeight.Bold).fontColor('#203E3B').width('100%')
        Text('THE LAST CHECKOUT').fontSize(11).fontColor('#967447').letterSpacing(4).width('100%').margin({ top: 8, bottom: 22 })
        Stack({ alignContent: Alignment.BottomStart }) {
          LibraryMap({ progress: this.preview })
          Text('一本旧书，一封未寄出的信。').fontSize(13).fontColor('#FFF2D5')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor('#E6203E3B').margin(12).borderRadius(6)
        }.width('100%').borderRadius(14).clip(true)
        Text('走进即将闭馆的图书馆。\n在现在与过去之间，找回一个迟到的约定。')
          .fontSize(15).fontColor('#736A58').lineHeight(25).width('100%').margin({ top: 20, bottom: 22 })
        if (this.hasSave) {
          Button('继续上次探索', { type: ButtonType.Normal }).width('100%').height(50).borderRadius(12)
            .backgroundColor('#274E45').fontColor('#FFF3D8').enabled(this.ready).id('continue-game')
            .onClick(() => { router.pushUrl({ url: gameSession.progress.ending === '' ? 'pages/Explore' : 'pages/Ending' }); })
        }
        Button(this.hasSave ? '重新开始' : '开始探索', { type: ButtonType.Normal })
          .width('100%').height(50).borderRadius(12).margin({ top: this.hasSave ? 10 : 0 })
          .backgroundColor(this.hasSave ? '#E8DDC7' : '#274E45').fontColor(this.hasSave ? '#274E45' : '#FFF3D8')
          .enabled(this.ready).id('new-game').onClick(() => { this.start(); })
        Row() {
          Button('玩法说明').fontSize(12).fontColor('#786C55').backgroundColor(Color.Transparent).padding(0)
            .onClick(() => {
              AlertDialog.show({ title: '探索指南', message: '按住方向键自由走动，书架和墙壁会阻挡你。\n\n靠近物件后点击「调查」；点击「回声」观察同一地点的过去。线索会自动记入手册。\n\n走到门口进入其他房间。关键操作后自动保存，下次可继续探索。', confirm: { value: '知道了', action: () => {} } });
            })
          Blank()
          Text('结局收藏 ' + this.endingCount + ' / 2').fontSize(12).fontColor('#786C55')
        }.width('100%').margin({ top: 12 })
        if (this.warning !== '') { Text(this.warning).fontSize(12).fontColor('#A44D38').width('100%').margin({ top: 8 }); }
      }.padding(24).width('100%').constraintSize({ maxWidth: 520 })
    }.width('100%').height('100%').backgroundColor('#F6EEDC').scrollBar(BarState.Off)
  }
}
