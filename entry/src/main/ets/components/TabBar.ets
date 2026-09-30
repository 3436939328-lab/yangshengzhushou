@Component
export struct WellnessTabBar {
  @Link currentTab: number;
  @Prop tabTitles: string[];

  build() {
    Row() {
      ForEach(this.tabTitles, (title: string, index: number) => {
        Column() {
          Text(title)
            .fontSize(13)
            .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(Color.White)
            .textShadow({ radius: 4, color: '#CC000000', offsetY: 1 })
          Column()
            .width(22)
            .height(3)
            .backgroundColor(this.currentTab === index ? Color.White : Color.Transparent)
            .borderRadius(2)
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .height(54)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentTab = index;
        })
      }, (title: string) => title)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 8, bottom: 10 })
    .backgroundColor(Color.Transparent)
  }
}
