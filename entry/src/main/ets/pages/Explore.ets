import { router } from '@kit.ArkUI';
import { LibraryMap } from '../components/LibraryMap';
import { DirectionPad } from '../components/DirectionPad';
import { GameProgress, Direction, EndingId, InteractionResult, createProgress, cloneProgress } from '../model/GameTypes';
import { getScene } from '../data/StoryData';
import { movePlayer, nearbyObject } from '../logic/WorldController';
import { investigate, submitPuzzle, chooseEnding, canFulfilPromise, objective } from '../logic/GameEngine';
import { gameSession } from '../storage/GameSession';

@Entry
@Component
struct Explore {
  @State progress: GameProgress = createProgress();
  @State message: string = '走近物件，看看它留下了什么。';
  @State saveLabel: string = '进度已保存';
  @State dialogVisible: boolean = false;
  @State interaction: InteractionResult = { title: '', text: '', kind: 'text', collected: false };
  @State password: string = '';
  @State puzzleError: string = '';
  @StorageLink('libraryForeground') @Watch('foregroundChanged') foreground: boolean = true;
  private moveTimer: number = -1;
  private moveDirection: Direction = 'up';
  private moving: boolean = false;
  private saveRevision: number = 0;

  aboutToAppear(): void {
    this.progress = cloneProgress(gameSession.progress);
    this.message = objective(this.progress);
    this.saveLabel = gameSession.warning !== '' ? gameSession.warning : '进度已保存';
  }

  aboutToDisappear(): void { this.stopMovement(); }

  foregroundChanged(): void {
    if (!this.foreground) { this.stopMovement(); }
  }

  onBackPress(): boolean { this.goHome(); return true; }

  private commit(): void { gameSession.progress = cloneProgress(this.progress); }

  private async persist(): Promise<void> {
    this.commit();
    const revision: number = ++this.saveRevision;
    this.saveLabel = '正在保存…';
    const result = await gameSession.save();
    if (revision === this.saveRevision) { this.saveLabel = result.message; }
  }

  private startMovement(direction: Direction): void {
    if (this.dialogVisible || !this.foreground) { return; }
    this.stopMovement(false);
    this.moveDirection = direction;
    this.moving = true;
    this.step();
    if (this.moving) { this.moveTimer = setInterval(() => { this.step(); }, 65); }
  }

  private step(): void {
    if (!this.moving || this.dialogVisible || !this.foreground) { this.stopMovement(); return; }
    const moved = movePlayer(this.progress, this.moveDirection);
    this.progress = moved.progress;
    this.commit();
    if (moved.blockedDoor) { this.message = '门还锁着。走近密码锁，点击「调查」。'; }
    if (moved.changedRoom) {
      this.message = getScene(this.progress.room).subtitle;
      this.stopMovement();
    }
  }

  private stopMovement(save: boolean = true): void {
    const wasMoving: boolean = this.moving;
    this.moving = false;
    if (this.moveTimer !== -1) { clearInterval(this.moveTimer); this.moveTimer = -1; }
    if (save && wasMoving) { this.persist(); }
  }

  private switchEra(): void {
    this.stopMovement(false);
    const next = cloneProgress(this.progress);
    next.era = next.era === 'now' ? 'past' : 'now';
    this.progress = next;
    this.message = next.era === 'past' ? '回声浮现。同一间房，可能藏着不同的信息。' : '回到现在，过去的线索已经记在手册里。';
    this.persist();
  }

  private inspect(): void {
    this.stopMovement(false);
    const object = nearbyObject(this.progress);
    if (!object) { this.message = '靠近书桌、书架或公告栏，再试着调查。'; return; }
    const next = cloneProgress(this.progress);
    this.interaction = investigate(next, object.id);
    this.progress = next;
    this.password = '';
    this.puzzleError = '';
    this.dialogVisible = true;
    this.persist();
  }

  private openNotebook(): void {
    this.stopMovement();
    this.commit();
    router.pushUrl({ url: 'pages/Notebook' });
  }

  private async goHome(): Promise<void> {
    this.stopMovement(false);
    await this.persist();
    router.back();
  }

  private solve(): void {
    const next = cloneProgress(this.progress);
    const error: string = submitPuzzle(next, this.password);
    if (error !== '') { this.puzzleError = error; return; }
    this.progress = next;
    this.dialogVisible = false;
    this.message = '咔哒。资料室的门打开了，向上走进入门口。';
    this.persist();
  }

  private async finish(ending: EndingId): Promise<void> {
    const next = cloneProgress(this.progress);
    const error: string = chooseEnding(next, ending);
    if (error !== '') { this.puzzleError = error; return; }
    this.progress = next;
    this.dialogVisible = false;
    await this.persist();
    await router.replaceUrl({ url: 'pages/Ending' });
  }

  @Builder
  dialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#A8142D2A')
      Column({ space: 14 }) {
        Text(this.interaction.collected ? '发现线索 / NEW CLUE' : (this.progress.era === 'past' ? '过去的回声 / ECHO' : '馆内记录 / ARCHIVE'))
          .fontSize(10).letterSpacing(2).fontColor('#98764A').width('100%')
        Text(this.interaction.title).fontSize(23).fontWeight(FontWeight.Bold).fontColor('#203E3B').width('100%')
        Scroll() {
          Text(this.interaction.text).fontSize(15).lineHeight(25).fontColor('#625A4A').width('100%')
        }.constraintSize({ maxHeight: 230 }).width('100%').scrollBar(BarState.Auto)
        if (this.interaction.kind === 'puzzle') {
          TextInput({ placeholder: '输入三位数字', text: this.password }).type(InputType.Number).maxLength(3)
            .height(48).fontSize(22).backgroundColor('#EBE1CC').fontColor('#274E45')
            .onChange((value: string) => { this.password = value; this.puzzleError = ''; }).id('password-input')
          Button('尝试开锁', { type: ButtonType.Normal }).width('100%').height(46).borderRadius(10)
            .backgroundColor('#274E45').fontColor('#FFF2D5').onClick(() => { this.solve(); }).id('submit-password')
        }
        if (this.interaction.kind === 'final') {
          Button('把信交给管理员', { type: ButtonType.Normal }).width('100%').height(46).borderRadius(10)
            .backgroundColor('#274E45').fontColor('#FFF2D5').onClick(() => { this.finish('delivered'); }).id('ending-delivered')
          Button('补全约定，留给后来者', { type: ButtonType.Normal }).width('100%').height(46).borderRadius(10)
            .backgroundColor('#DABB83').fontColor('#304B45').enabled(canFulfilPromise(this.progress))
            .onClick(() => { this.finish('promise'); }).id('ending-promise')
          if (!canFulfilPromise(this.progress)) {
            Text('这个选择还需要：赠书卡与后来者的留言。').fontSize(12).fontColor('#8B7352').width('100%')
          }
        }
        if (this.puzzleError !== '') { Text(this.puzzleError).fontSize(13).fontColor('#A44D38').width('100%'); }
        Button(this.interaction.kind === 'final' ? '先继续寻找' : '收起记录', { type: ButtonType.Normal })
          .width('100%').height(42).borderRadius(10).backgroundColor('#E8DDC7').fontColor('#274E45')
          .onClick(() => { this.dialogVisible = false; this.message = objective(this.progress); }).id('close-dialog')
      }.padding(24).width('88%').constraintSize({ maxWidth: 440 }).borderRadius(18).backgroundColor('#FBF3E2')
    }.width('100%').height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 0 }) {
        Row() {
          Button('‹ 首页').fontSize(13).fontColor('#736A58').backgroundColor(Color.Transparent).padding(0)
            .onClick(() => { this.goHome(); }).id('back-home')
          Blank()
          Button('线索 ' + this.progress.clues.length + '/5').fontSize(13).fontColor('#274E45').backgroundColor('#E8DDC7')
            .height(34).onClick(() => { this.openNotebook(); }).id('open-notebook')
        }.width('100%').height(40)
        Row() {
          Column({ space: 4 }) {
            Text('旧馆 / ROOM ' + getScene(this.progress.room).index).fontSize(10).letterSpacing(2).fontColor('#967447').width('100%')
            Text(getScene(this.progress.room).title).fontSize(26).fontWeight(FontWeight.Bold).fontColor('#203E3B').width('100%')
          }.layoutWeight(1)
          Text(this.progress.era === 'now' ? '● 现在' : '◌ 过去').fontSize(13)
            .fontColor(this.progress.era === 'now' ? '#446B53' : '#537987').padding(10)
            .backgroundColor(this.progress.era === 'now' ? '#E5E6CF' : '#DCE5DF').borderRadius(10)
        }.width('100%').margin({ top: 6, bottom: 16 })
        LibraryMap({ progress: this.progress, highlightId: nearbyObject(this.progress)?.id ?? '' })
          .borderRadius(12).clip(true)
        Row() {
          Text(nearbyObject(this.progress) ? '附近：' + nearbyObject(this.progress)!.name : '按住方向键走动 · 靠近物件调查')
            .fontSize(12).fontColor('#736A58').maxLines(1).layoutWeight(1)
        }.width('100%').height(33)
        Text(this.message).fontSize(13).fontColor('#6E6450').lineHeight(21).maxLines(3)
          .width('100%').height(64).padding(10).backgroundColor('#EDE4D0').borderRadius(10)
        Blank().constraintSize({ minHeight: 8, maxHeight: 30 })
        Row() {
          DirectionPad({ disabled: this.dialogVisible, onStart: (direction: Direction) => { this.startMovement(direction); }, onStop: () => { this.stopMovement(); } })
          Blank()
          Column({ space: 12 }) {
            Button(this.progress.era === 'now' ? '◌ 聆听回声' : '● 回到现在', { type: ButtonType.Normal })
              .width(142).height(45).borderRadius(12).fontSize(14).backgroundColor('#DDE4D9').fontColor('#345C55')
              .onClick(() => { this.switchEra(); }).id('switch-era')
            Button('调查', { type: ButtonType.Normal }).width(142).height(52).borderRadius(12).fontSize(17)
              .backgroundColor('#274E45').fontColor('#FFF2D5').enabled(nearbyObject(this.progress) !== undefined)
              .onClick(() => { this.inspect(); }).id('inspect-object')
          }
        }.width('100%').height(140)
        Row() {
          Text(this.saveLabel).fontSize(10).fontColor(this.saveLabel.includes('失败') ? '#A44D38' : '#9A8C70').layoutWeight(1)
          Button('保存').fontSize(11).fontColor('#786C55').backgroundColor(Color.Transparent).padding(0).height(26)
            .onClick(() => { this.persist(); }).id('save-progress')
        }.width('100%').height(28)
      }.padding({ left: 20, right: 20, top: 8, bottom: 8 }).width('100%').height('100%')
      if (this.dialogVisible) { this.dialog(); }
    }.width('100%').height('100%').backgroundColor('#F6EEDC')
  }
}
