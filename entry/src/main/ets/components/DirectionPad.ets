import { Direction } from '../model/GameTypes';

@Component
export struct DirectionPad {
  @Prop disabled: boolean = false;
  onStart: (direction: Direction) => void = () => {};
  onStop: () => void = () => {};

  @Builder
  directionButton(label: string, direction: Direction) {
    Button(label, { type: ButtonType.Normal }).width(46).height(42).padding(0).borderRadius(12).fontSize(23)
      .backgroundColor('#E8DDC7').fontColor('#274E45').enabled(!this.disabled)
      .id('move-' + direction).accessibilityText('向' + label + '移动')
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) { this.onStart(direction); }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.onStop(); }
      })
  }

  build() {
    Column({ space: 4 }) {
      this.directionButton('↑', 'up')
      Row({ space: 4 }) {
        this.directionButton('←', 'left')
        Text('·').fontSize(28).fontColor('#A79576').width(46).height(42).textAlign(TextAlign.Center)
        this.directionButton('→', 'right')
      }
      this.directionButton('↓', 'down')
    }.width(146)
  }
}
