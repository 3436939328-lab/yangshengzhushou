import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

/**
 * 医生信息（增强版）
 */
export interface DoctorCardInfo {
  id: string;
  userId: string;
  name: string;
  title: string;           // 职称
  specialty: string;       // 擅长方向
  introduction?: string;   // 个人简介
  department?: string;     // 科室
  hospital?: string;       // 医院
  avatarUrl?: string;      // 头像
  rating?: number;         // 评分
  consultationCount?: number; // 问诊次数
  price?: number;          // 问诊价格
  priceUnit?: string;      // 价格单位
  isOnline?: boolean;      // 是否在线
  responseTime?: string;   // 平均响应时间
  tags?: string[];         // 标签
}

/**
 * 医生列表卡片组件
 */
@Component
export struct DoctorCard {
  @Prop doctor: DoctorCardInfo;
  @Prop isSelected: boolean = false;

  onSelect?: (doctor: DoctorCardInfo) => void;
  onViewProfile?: (doctor: DoctorCardInfo) => void;

  build() {
    Column({ space: 12 }) {
      // 医生基本信息
      Row({ space: 12 }) {
        // 头像
        Stack() {
          if (this.doctor.avatarUrl) {
            Image(this.doctor.avatarUrl)
              .width(56)
              .height(56)
              .borderRadius(28)
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              Text(this.doctor.name.charAt(0))
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor(BRAND_GREEN)
            .justifyContent(FlexAlign.Center)
          }

          // 在线状态
          if (this.doctor.isOnline) {
            Column()
              .width(12)
              .height(12)
              .borderRadius(6)
              .backgroundColor('#4CAF50')
              .border({ width: 2, color: Color.White })
              .position({ right: 0, bottom: 0 })
          }
        }
        .width(56)
        .height(56)

        // 姓名职称
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.doctor.name)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
            if (this.doctor.title) {
              Text(this.doctor.title)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#F0F0F0')
                .borderRadius(4)
            }
          }

          if (this.doctor.department || this.doctor.hospital) {
            Text(`${this.doctor.hospital || ''} ${this.doctor.department || ''}`.trim())
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          // 评分和问诊次数
          if (this.doctor.rating !== undefined || this.doctor.consultationCount !== undefined) {
            Row({ space: 10 }) {
              if (this.doctor.rating !== undefined) {
                Row({ space: 2 }) {
                  Text('⭐')
                    .fontSize(12)
                  Text(this.doctor.rating.toFixed(1))
                    .fontSize(12)
                    .fontColor(WARM_ACCENT)
                    .fontWeight(FontWeight.Medium)
                }
              }
              if (this.doctor.consultationCount !== undefined) {
                Text(`${this.doctor.consultationCount} 次问诊`)
                  .fontSize(12)
                  .fontColor(MUTED_TEXT)
              }
              if (this.doctor.responseTime) {
                Text(`平均${this.doctor.responseTime}回复`)
                  .fontSize(12)
                  .fontColor(MUTED_TEXT)
              }
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 价格
        if (this.doctor.price !== undefined) {
          Column({ space: 2 }) {
            Text(`¥${this.doctor.price}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(WARM_ACCENT)
            Text(this.doctor.priceUnit || '/次')
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
          .alignItems(HorizontalAlign.End)
        }
      }
      .width('100%')

      // 擅长方向
      if (this.doctor.specialty) {
        Column({ space: 6 }) {
          Text('擅长')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text(this.doctor.specialty)
            .fontSize(13)
            .fontColor(DEEP_TEXT)
            .lineHeight(20)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 标签
      if (this.doctor.tags && this.doctor.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.doctor.tags.slice(0, 3), (tag: string) => {
            Text(tag)
              .fontSize(11)
              .fontColor(BRAND_GREEN)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .margin({ right: 6, bottom: 6 })
              .backgroundColor('rgba(76, 175, 80, 0.1)')
              .borderRadius(10)
          }, (tag: string) => tag)
        }
        .width('100%')
      }

      // 操作按钮
      Row({ space: 10 }) {
        Button() {
          Text('查看详情')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
        }
        .height(34)
        .backgroundColor('rgba(76, 175, 80, 0.1)')
        .borderRadius(17)
        .layoutWeight(1)
        .onClick(() => {
          if (this.onViewProfile) {
            this.onViewProfile(this.doctor);
          }
        })

        Button() {
          Text(this.isSelected ? '已选择' : '选择医生')
            .fontSize(13)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .height(34)
        .backgroundColor(this.isSelected ? '#81C784' : BRAND_GREEN)
        .borderRadius(17)
        .layoutWeight(1)
        .onClick(() => {
          if (this.onSelect) {
            this.onSelect(this.doctor);
          }
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isSelected ? 'rgba(76, 175, 80, 0.05)' : CARD_BG)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? BRAND_GREEN : '#EEEEEE'
    })
    .borderRadius(CARD_RADIUS)
  }
}

/**
 * 医生列表视图
 */
@Component
export struct DoctorListSection {
  @Prop doctors: DoctorCardInfo[];
  @Prop selectedDoctorId: string = '';
  @Prop isLoading: boolean = false;

  onSelectDoctor?: (doctor: DoctorCardInfo) => void;
  onViewDoctorProfile?: (doctor: DoctorCardInfo) => void;

  build() {
    Column({ space: 10 }) {
      if (this.isLoading) {
        Text('加载医生列表中...')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else if (this.doctors.length === 0) {
        Column({ space: 8 }) {
          Text('👨‍⚕️')
            .fontSize(40)
          Text('暂无可选医生')
            .fontSize(14)
            .fontColor(DEEP_TEXT)
          Text('请稍后再试或联系管理员')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .alignItems(HorizontalAlign.Center)
      } else {
        ForEach(this.doctors, (doctor: DoctorCardInfo) => {
          DoctorCard({
            doctor: doctor,
            isSelected: this.selectedDoctorId === doctor.userId,
            onSelect: (d: DoctorCardInfo) => {
              if (this.onSelectDoctor) this.onSelectDoctor(d);
            },
            onViewProfile: (d: DoctorCardInfo) => {
              if (this.onViewDoctorProfile) this.onViewDoctorProfile(d);
            }
          })
        }, (doctor: DoctorCardInfo) => doctor.id)
      }
    }
    .width('100%')
  }
}
