@Entry
@Component
struct Index {
  build() {
    Column({ space: 18 }) {
      Text('零点借阅室').fontSize(36).fontWeight(FontWeight.Bold).fontColor('#203E3B')
      Text('一本旧书，一封未寄出的信。').fontSize(17).fontColor('#786B58')
      Text('原生工程已就绪').fontSize(13).fontColor('#786B58')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor('#F6EEDC')
  }
}
