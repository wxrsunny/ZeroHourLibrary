import { router } from '@kit.ArkUI';
import { LibraryMap } from '../components/LibraryMap';
import { GameProgress, createProgress, cloneProgress } from '../model/GameTypes';
import { endingTitle, endingText } from '../data/StoryData';
import { gameSession } from '../storage/GameSession';

@Entry
@Component
struct Ending {
  @State progress: GameProgress = createProgress();
  aboutToAppear(): void { this.progress = cloneProgress(gameSession.progress); }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('一段往事，已落下书签。').fontSize(12).letterSpacing(2).fontColor('#A28659').width('100%')
        Text(endingTitle(this.progress.ending)).fontSize(34).fontWeight(FontWeight.Bold).fontColor('#203E3B').width('100%')
        Text(this.progress.ending === 'promise' ? 'ENDING 02 / A PROMISE KEPT' : 'ENDING 01 / LETTER DELIVERED')
          .fontSize(10).letterSpacing(2).fontColor('#967447').width('100%')
        LibraryMap({ progress: this.progress }).borderRadius(14).clip(true)
        Text(endingText(this.progress.ending)).fontSize(16).lineHeight(28).fontColor('#73654F').width('100%')
        Text('线索 ' + this.progress.clues.length + '/5  ·  结局收藏 ' + this.progress.unlockedEndings.length + '/2')
          .fontSize(12).fontColor('#9A825B').width('100%')
        Button('返回首页', { type: ButtonType.Normal }).width('100%').height(48).borderRadius(12)
          .backgroundColor('#274E45').fontColor('#FFF2D5').onClick(() => { router.back(); }).id('ending-home')
      }.padding(24).width('100%').constraintSize({ maxWidth: 520 })
    }.height('100%').width('100%').backgroundColor('#F6EEDC').scrollBar(BarState.Off)
  }
}
