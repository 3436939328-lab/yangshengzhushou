import {
  QuickAction,
  SolarTermInfo,
  WeatherWellness,
  WellnessPlan
} from '../../model/WellnessModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { SectionTitle } from '../cards/CommonCards';
import { LocationCoordinate, searchLocations, requestWeatherAtLocation } from '../../services/WeatherService';

@Component
export struct HomeTab {
  @Prop weather: WeatherWellness;
  @Prop solarTerm: SolarTermInfo;
  @Prop plans: WellnessPlan[];
  @Prop quickActions: QuickAction[];
  @Prop suggestionSource: string;
  @Prop suggestionSummary: string;
  @Prop suggestionItems: string[];
  @Prop suggestionRetrievalStatus: string;
  @Prop suggestionLoading: boolean;
  @Prop suggestionError: string;
  @Prop weatherRefreshing: boolean;
  @Prop weatherRefreshStatus: string;
  onRefreshWeather?: () => void;
  onRefreshSuggestion?: () => void;
  onQuickAction?: (title: string) => void;
  onWeatherSelected?: (weather: WeatherWellness) => void;
  @State showLocationSearch: boolean = false;
  @State locationQuery: string = '';
  @State locationResults: LocationCoordinate[] = [];
  @State locationMessage: string = '';
  @State locationBusy: boolean = false;

  build() {
    Column({ space: 14 }) {
      this.WeatherCard()
      if (this.showLocationSearch) {
        this.LocationSearch()
      }
      this.TodaySuggestionCard()
      this.SolarTermCard()
      SectionTitle('大模型调理计划')
      this.ModelPlanList()
      SectionTitle('快捷入口')
      Grid() {
        ForEach(this.quickActions, (item: QuickAction) => {
          GridItem() {
            Column() {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(DEEP_TEXT)
              Text(item.description)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
                .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .height(92)
            .padding(14)
            .backgroundColor(CARD_BG)
            .borderRadius(CARD_RADIUS)
            .onClick(() => { if (this.onQuickAction) this.onQuickAction(item.title); })
          }
        }, (item: QuickAction) => item.title)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .height(194)
    }
    .margin({ top: 14 })
  }


  @Builder
  TodaySuggestionCard() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('今日建议')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(this.suggestionSourceText())
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.suggestionLoading ? '生成中' : '生成建议')
          .fontSize(12)
          .fontColor(BRAND_GREEN)
          .backgroundColor('#EEF7F1')
          .height(32)
          .enabled(!this.suggestionLoading)
          .onClick(() => {
            if (this.onRefreshSuggestion) {
              this.onRefreshSuggestion();
            }
          })
      }
      .width('100%')

      if (this.suggestionError.length > 0) {
        Text(this.suggestionError)
          .fontSize(13)
          .fontColor(WARM_ACCENT)
          .lineHeight(20)
      } else if (this.suggestionLoading && this.suggestionSummary.length === 0) {
        Text('正在结合当前位置、天气和健康档案生成建议...')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
      } else if (this.suggestionSummary.length > 0) {
        Text(this.suggestionSummary)
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .lineHeight(22)
      } else {
        Text('点击生成建议，获取结合当前位置、天气和健康档案的今日养生建议。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
      }

      if (this.visibleSuggestionItems().length > 0) {
        Column({ space: 8 }) {
          ForEach(this.visibleSuggestionItems(), (item: string) => {
            Row() {
              Text('')
                .width(6)
                .height(6)
                .backgroundColor(BRAND_GREEN)
                .borderRadius(3)
                .margin({ top: 7, right: 8 })
              Text(item)
                .fontSize(13)
                .fontColor(DEEP_TEXT)
                .lineHeight(20)
                .layoutWeight(1)
            }
            .alignItems(VerticalAlign.Top)
            .width('100%')
          }, (item: string) => item)
        }
        .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }


  @Builder
  WeatherCard() {
    Column() {
      Row() {
        Column() {
          Text(`${this.weather.city} · ${this.weather.condition}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(DEEP_TEXT)
          Text(this.weather.temperature)
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .fontColor(BRAND_GREEN)
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(`${this.weather.sourceLabel} · 湿度 ${this.weather.humidity}`)
            .fontSize(13)
            .fontColor(this.weather.isFallback === true ? WARM_ACCENT : MUTED_TEXT)
          Button(this.weatherRefreshing ? '刷新中' : '刷新')
            .fontSize(12)
            .fontColor(BRAND_GREEN)
            .backgroundColor('#EEF7F1')
            .height(32)
            .margin({ top: 8 })
            .enabled(!this.weatherRefreshing)
            .onClick(() => {
              if (this.onRefreshWeather) {
                this.onRefreshWeather();
              }
            })
        }
        .alignItems(HorizontalAlign.End)
      }

      Text(`当前天气：${this.weather.condition} · 温度 ${this.weather.temperature} · 湿度 ${this.weather.humidity}`)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(22)
        .margin({ top: 14 })
      if (this.weatherRefreshStatus.length > 0) {
        Text(this.weatherRefreshStatus)
          .fontSize(12)
          .fontColor(this.weather.isFallback === true ? WARM_ACCENT : BRAND_GREEN)
          .lineHeight(18)
          .margin({ top: 8 })
      }
      if (this.weather.isFallback === true) {
        Text(this.weather.advice)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .lineHeight(18)
          .margin({ top: 8 })
      }
      if (this.weather.address && this.weather.address.length > 0) {
        Text(this.weather.address).fontSize(12).fontColor(MUTED_TEXT).margin({ top: 8 })
      }
      Button(this.showLocationSearch ? '收起位置选择' : '选择城市或地址')
        .fontSize(12).fontColor(BRAND_GREEN).backgroundColor(Color.Transparent)
        .onClick(() => { this.showLocationSearch = !this.showLocationSearch; })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }


  private suggestionSourceText(): string {
    if (this.suggestionSource.length === 0) {
      return '等待生成';
    }
    const status = this.suggestionRetrievalStatus.length > 0
      ? this.suggestionRetrievalStatus
      : 'RAG';
    return `${this.suggestionSource} · ${status}`;
  }

  private visibleSuggestionItems(): string[] {
    return this.suggestionItems;
  }


  @Builder
  SolarTermCard() {
    Column({ space: 10 }) {
      Row() {
        Text(this.solarTerm.name)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text(this.solarTerm.date)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .margin({ left: 8 })
      }
      .width('100%')

      Text(this.solarTerm.focus)
        .fontSize(15)
        .fontColor(BRAND_GREEN)

      Text(`适宜：${this.solarTerm.foods.join('、')}`)
        .fontSize(13)
        .fontColor(MUTED_TEXT)

      Text(this.solarTerm.routine)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(22)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#EEF7F1')
    .borderRadius(CARD_RADIUS)
  }


  @Builder
  ModelPlanList() {
    if (this.plans.length > 0) {
      Column({ space: 10 }) {
        ForEach(this.plans, (item: WellnessPlan) => {
          this.PlanRow(item)
        }, (item: WellnessPlan) => item.title)
      }
      .width('100%')
    } else {
      Column({ space: 8 }) {
        Text(this.planPlaceholderTitle())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.suggestionError.length > 0 ? WARM_ACCENT : DEEP_TEXT)
        Text(this.planPlaceholderDetail())
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
  }


  @Builder
  PlanRow(item: WellnessPlan) {
    Row() {
      Text(item.time)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(BRAND_GREEN)
        .width(58)
      Column() {
        Row() {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(DEEP_TEXT)
          Text(item.tag)
            .fontSize(11)
            .fontColor(WARM_ACCENT)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#FFF2E8')
            .borderRadius(10)
            .margin({ left: 8 })
        }
        Text(item.detail)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private planPlaceholderTitle(): string {
    if (this.suggestionError.length > 0) {
      return '大模型计划生成失败';
    }
    if (this.suggestionLoading) {
      return '正在生成调理计划';
    }
    return '等待生成调理计划';
  }

  private planPlaceholderDetail(): string {
    if (this.suggestionError.length > 0) {
      return this.suggestionError;
    }
    if (this.suggestionLoading) {
      return '正在根据当前位置、天气和健康档案生成饮食、运动、睡眠安排。';
    }
    return '点击“生成建议”后，这里会展示大模型返回的当日调理计划。';
  }

  @Builder
  LocationSearch() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        TextInput({ text: this.locationQuery, placeholder: '搜索全国城市、区县或地址' })
          .layoutWeight(1).onChange((value: string) => { this.locationQuery = value; })
        Button('搜索').enabled(!this.locationBusy).onClick(() => { this.searchLocation(); })
      }
      if (this.locationMessage.length > 0) {
        Text(this.locationMessage).fontSize(12).fontColor(MUTED_TEXT)
      }
      ForEach(this.locationResults, (place: LocationCoordinate) => {
        Button(place.address || place.city || '选择此位置')
          .width('100%').fontSize(13).fontColor(DEEP_TEXT).backgroundColor(CARD_BG)
          .enabled(!this.locationBusy).onClick(() => { this.selectLocation(place); })
      }, (place: LocationCoordinate) => `${place.latitude},${place.longitude}`)
    }.width('100%')
  }

  private async searchLocation(): Promise<void> {
    this.locationBusy = true;
    try {
      this.locationResults = await searchLocations(this.locationQuery);
      this.locationMessage = this.locationResults.length === 0 ? '未找到结果，请补充省市或详细地址' : '';
    } catch (error) {
      this.locationMessage = '地址搜索暂不可用，请检查网络或稍后重试';
    } finally { this.locationBusy = false; }
  }

  private async selectLocation(place: LocationCoordinate): Promise<void> {
    this.locationBusy = true;
    try {
      const weather = await requestWeatherAtLocation(place);
      if (this.onWeatherSelected) this.onWeatherSelected(weather);
      this.showLocationSearch = false;
    } catch (error) { this.locationMessage = '无法获取此位置的天气'; }
    finally { this.locationBusy = false; }
  }

}
