import { router } from '@kit.ArkUI';
import { CLUES } from '../data/StoryData';
import { ClueDefinition } from '../model/GameTypes';
import { gameSession } from '../storage/GameSession';

@Entry
@Component
struct Notebook {
  @State collected: string[] = [];
  aboutToAppear(): void { this.collected = gameSession.progress.clues.slice(); }

  build() {
    Column({ space: 0 }) {
      Row() {
        Button('‹ 返回探索').fontSize(13).fontColor('#736A58').backgroundColor(Color.Transparent).padding(0)
          .onClick(() => { router.back(); }).id('back-explore')
        Blank()
        Text(this.collected.length + ' / 5').fontSize(13).fontColor('#967447')
      }.width('100%').height(42)
      Text('线索手册').fontSize(30).fontWeight(FontWeight.Bold).fontColor('#203E3B').width('100%').margin({ top: 14 })
      Text('把散落的片段，拼成完整的往事。').fontSize(13).fontColor('#84775E').width('100%').margin({ top: 8, bottom: 22 })
      List({ space: 12 }) {
        ForEach(CLUES, (clue: ClueDefinition, index: number) => {
          ListItem() {
            Column({ space: 8 }) {
              Row() {
                Text('0' + (index + 1)).fontSize(12).fontColor('#A3875A')
                Blank()
                Text(clue.optional ? '往事' : '谜题').fontSize(10).fontColor('#8E7955')
              }.width('100%')
              Text(this.collected.includes(clue.id) ? clue.title : '尚未发现的线索').fontSize(18)
                .fontWeight(FontWeight.Medium).fontColor(this.collected.includes(clue.id) ? '#274E45' : '#AA9C81').width('100%')
              if (this.collected.includes(clue.id)) {
                Text(clue.description).fontSize(14).lineHeight(23).fontColor('#716550').width('100%')
                Text(clue.location).fontSize(11).fontColor('#A3875A').width('100%').margin({ top: 4 })
              } else { Text('继续探索，留意现在与过去的不同。').fontSize(12).fontColor('#A99A7C').width('100%'); }
            }.padding(18).width('100%').borderRadius(12).backgroundColor('#FCF6E9')
          }
        }, (clue: ClueDefinition) => clue.id)
      }.layoutWeight(1).width('100%').scrollBar(BarState.Auto)
    }.padding({ left: 22, right: 22, top: 8, bottom: 20 }).width('100%').height('100%').backgroundColor('#F1E8D3')
  }
}
