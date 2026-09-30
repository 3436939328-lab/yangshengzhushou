import {
  MetricCode,
  BloodSugarType,
  BloodPressurePosition,
  BloodPressureArm,
  HeartRateContext,
  TemperatureSite,
  SleepType,
  SleepSubjectiveFeeling,
  DataSource,
  BloodPressureMeasurement,
  BloodSugarMeasurement,
  HeartRateMeasurement,
  BloodOxygenMeasurement,
  TemperatureMeasurement,
  BodyMeasurement,
  StepsMeasurement,
  ExerciseMeasurement,
  WaterMeasurement,
  SleepMeasurement,
  HealthMeasurement
} from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { buildSaveFailureText, buildSaveSuccessText } from '../../services/SaveFeedbackService';

interface SegmentOption<T> {
  value: T;
  label: string;
}

interface ValidationResult {
  valid: boolean;
  message?: string;
}

/**
 * 结构化健康指标录入表单
 * 支持血压、血糖、心率、血氧、体温、体格、步数、运动、饮水、睡眠 10 种类型
 */
@Component
export struct StructuredHealthForm {
  @Prop metricCode: MetricCode = MetricCode.BLOOD_PRESSURE;
  @Prop isVisible: boolean = false;

  @State isSaving: boolean = false;
  @State errorText: string = '';
  @State successText: string = '';

  // 血压字段
  @State bpSystolic: string = '';
  @State bpDiastolic: string = '';
  @State bpPulse: string = '';
  @State bpPosition: BloodPressurePosition = BloodPressurePosition.SITTING;
  @State bpArm: BloodPressureArm = BloodPressureArm.LEFT;

  // 血糖字段
  @State bsValue: string = '';
  @State bsType: BloodSugarType = BloodSugarType.FASTING;
  @State bsMeasureMethod: string = '';

  // 心率字段
  @State hrValue: string = '';
  @State hrContext: HeartRateContext = HeartRateContext.RESTING;

  // 血氧字段
  @State boValue: string = '';

  // 体温字段
  @State tempValue: string = '';
  @State tempSite: TemperatureSite = TemperatureSite.AXILLARY;

  // 体格字段
  @State bodyHeight: string = '';
  @State bodyWeight: string = '';
  @State bodyWaist: string = '';

  // 步数字段
  @State stepsValue: string = '';

  // 运动字段
  @State exerciseDuration: string = '';
  @State exerciseType: string = '';
  @State exerciseCalories: string = '';

  // 饮水字段
  @State waterAmount: string = '';

  // 睡眠字段
  @State sleepStartDate: string = '';
  @State sleepStartTime: string = '';
  @State sleepEndDate: string = '';
  @State sleepEndTime: string = '';
  @State sleepTotalMinutes: string = '';
  @State sleepLightMinutes: string = '';
  @State sleepDeepMinutes: string = '';
  @State sleepRemMinutes: string = '';
  @State sleepAwakeMinutes: string = '';
  @State sleepAwakenings: string = '';
  @State sleepType: SleepType = SleepType.MAIN;
  @State sleepFeeling: SleepSubjectiveFeeling = SleepSubjectiveFeeling.FAIR;
  @State sleepNote: string = '';

  // 通用字段
  @State measuredAtDate: string = '';
  @State measuredAtTime: string = '';
  @State recordNote: string = '';

  onClose?: () => void;
  onSave?: (measurement: HealthMeasurement) => Promise<boolean>;

  aboutToAppear() {
    // 初始化默认时间为当前时间
    const now = new Date();
    this.measuredAtDate = this.formatDate(now);
    this.measuredAtTime = this.formatTime(now);
    // 睡眠默认日期
    this.sleepStartDate = this.formatDate(now);
    this.sleepStartTime = '23:00';
    this.sleepEndDate = this.formatDate(now);
    this.sleepEndTime = '07:00';
  }

  build() {
    Column() {
      if (this.isVisible) {
      // 标题栏
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => {
            if (this.onClose) this.onClose();
          })

        Text(this.formTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .width('100%')

      Scroll() {
        Column({ space: 14 }) {
          // 测量时间
          this.MeasurementTimeSection()

          // 各类型专属字段
          if (this.metricCode === MetricCode.BLOOD_PRESSURE) {
            this.BloodPressureSection()
          } else if (this.metricCode === MetricCode.BLOOD_SUGAR) {
            this.BloodSugarSection()
          } else if (this.metricCode === MetricCode.HEART_RATE) {
            this.HeartRateSection()
          } else if (this.metricCode === MetricCode.BLOOD_OXYGEN) {
            this.BloodOxygenSection()
          } else if (this.metricCode === MetricCode.TEMPERATURE) {
            this.TemperatureSection()
          } else if (this.metricCode === MetricCode.BODY) {
            this.BodySection()
          } else if (this.metricCode === MetricCode.STEPS) {
            this.StepsSection()
          } else if (this.metricCode === MetricCode.EXERCISE) {
            this.ExerciseSection()
          } else if (this.metricCode === MetricCode.WATER) {
            this.WaterSection()
          } else if (this.metricCode === MetricCode.SLEEP) {
            this.SleepSection()
          }

          // 备注
          this.NoteSection()

          // 提示信息
          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor('#E53935')
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          if (this.successText.length > 0) {
            Text(this.successText)
              .fontSize(13)
              .fontColor(BRAND_GREEN)
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          // 保存按钮
          Button() {
            Text(this.isSaving ? '保存中...' : '保存记录')
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .height(48)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(24)
          .enabled(!this.isSaving)
          .margin({ top: 8, bottom: 20 })
          .onClick(() => {
            this.handleSave();
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18, top: 14 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 通用部分 ====================

  @Builder
  MeasurementTimeSection() {
    Column({ space: 10 }) {
      Text('测量时间')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(DEEP_TEXT)

      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('日期')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          TextInput({ text: this.measuredAtDate, placeholder: 'YYYY-MM-DD' })
            .height(40)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onChange((value: string) => {
              this.measuredAtDate = value;
            })
        }
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text('时间')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          TextInput({ text: this.measuredAtTime, placeholder: 'HH:MM' })
            .height(40)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onChange((value: string) => {
              this.measuredAtTime = value;
            })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
  }

  @Builder
  NoteSection() {
    Column({ space: 8 }) {
      Text('备注（可选）')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
      TextArea({ text: this.recordNote, placeholder: '添加备注...' })
        .height(72)
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onChange((value: string) => {
          this.recordNote = value;
        })
    }
    .width('100%')
  }

  // ==================== 血压 ====================

  @Builder
  BloodPressureSection() {
    Column({ space: 12 }) {
      Text('血压')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      // 高低压
      Row({ space: 10 }) {
        this.NumberInputField('收缩压（高压）', this.bpSystolic, 'mmHg', (val: string) => {
          this.bpSystolic = val;
        })
        this.NumberInputField('舒张压（低压）', this.bpDiastolic, 'mmHg', (val: string) => {
          this.bpDiastolic = val;
        })
      }

      // 脉搏（可选）
      this.NumberInputField('脉搏（可选）', this.bpPulse, '次/分', (val: string) => {
        this.bpPulse = val;
      })

      // 体位
      this.SegmentPicker<BloodPressurePosition>(
        '测量体位',
        [
          { value: BloodPressurePosition.SITTING, label: '坐位' } as SegmentOption<BloodPressurePosition>,
          { value: BloodPressurePosition.STANDING, label: '立位' } as SegmentOption<BloodPressurePosition>,
          { value: BloodPressurePosition.LYING, label: '卧位' } as SegmentOption<BloodPressurePosition>
        ],
        this.bpPosition,
        (val: BloodPressurePosition) => { this.bpPosition = val; }
      )

      // 手臂
      this.SegmentPicker<BloodPressureArm>(
        '测量手臂',
        [
          { value: BloodPressureArm.LEFT, label: '左臂' } as SegmentOption<BloodPressureArm>,
          { value: BloodPressureArm.RIGHT, label: '右臂' } as SegmentOption<BloodPressureArm>
        ],
        this.bpArm,
        (val: BloodPressureArm) => { this.bpArm = val; }
      )

      // 合理性提示
      if (this.bpSystolic.length > 0 && this.bpDiastolic.length > 0) {
        if (!isNaN(parseFloat(this.bpSystolic)) && !isNaN(parseFloat(this.bpDiastolic)) && parseFloat(this.bpDiastolic) >= parseFloat(this.bpSystolic)) {
          Text('⚠️ 低压不应高于高压，请确认数值')
            .fontSize(12)
            .fontColor(WARM_ACCENT)
            .width('100%')
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 血糖 ====================

  @Builder
  BloodSugarSection() {
    Column({ space: 12 }) {
      Text('血糖')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('血糖值', this.bsValue, 'mmol/L', (val: string) => {
        this.bsValue = val;
      })

      // 测量类型
      this.SegmentPicker<BloodSugarType>(
        '测量类型',
        [
          { value: BloodSugarType.FASTING, label: '空腹' } as SegmentOption<BloodSugarType>,
          { value: BloodSugarType.POST_MEAL_2H, label: '餐后2小时' } as SegmentOption<BloodSugarType>,
          { value: BloodSugarType.RANDOM, label: '随机' } as SegmentOption<BloodSugarType>
        ],
        this.bsType,
        (val: BloodSugarType) => { this.bsType = val; }
      )

      Text('⚠️ 请选择正确的测量类型，不同类型参考范围不同')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 心率 ====================

  @Builder
  HeartRateSection() {
    Column({ space: 12 }) {
      Text('心率')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('心率值', this.hrValue, '次/分', (val: string) => {
        this.hrValue = val;
      })

      this.SegmentPicker<HeartRateContext>(
        '测量情境',
        [
          { value: HeartRateContext.RESTING, label: '静息' } as SegmentOption<HeartRateContext>,
          { value: HeartRateContext.AFTER_EXERCISE, label: '运动后' } as SegmentOption<HeartRateContext>,
          { value: HeartRateContext.UNKNOWN, label: '未知' } as SegmentOption<HeartRateContext>
        ],
        this.hrContext,
        (val: HeartRateContext) => { this.hrContext = val; }
      )
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 血氧 ====================

  @Builder
  BloodOxygenSection() {
    Column({ space: 12 }) {
      Text('血氧饱和度')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('血氧值', this.boValue, '%', (val: string) => {
        this.boValue = val;
      })

      if (this.boValue.length > 0) {
        if (!isNaN(parseFloat(this.boValue)) && parseFloat(this.boValue) > 100) {
          Text('⚠️ 血氧饱和度不应超过100%')
            .fontSize(12)
            .fontColor(WARM_ACCENT)
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 体温 ====================

  @Builder
  TemperatureSection() {
    Column({ space: 12 }) {
      Text('体温')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('体温', this.tempValue, '℃', (val: string) => {
        this.tempValue = val;
      })

      this.SegmentPicker<TemperatureSite>(
        '测量部位',
        [
          { value: TemperatureSite.ORAL, label: '口腔' } as SegmentOption<TemperatureSite>,
          { value: TemperatureSite.AXILLARY, label: '腋下' } as SegmentOption<TemperatureSite>,
          { value: TemperatureSite.EAR, label: '耳温' } as SegmentOption<TemperatureSite>,
          { value: TemperatureSite.FOREHEAD, label: '额温' } as SegmentOption<TemperatureSite>
        ],
        this.tempSite,
        (val: TemperatureSite) => { this.tempSite = val; }
      )

      Text('💡 不同测量部位参考范围不同')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 体格 ====================

  @Builder
  BodySection() {
    Column({ space: 12 }) {
      Text('体格')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Row({ space: 10 }) {
        this.NumberInputField('身高', this.bodyHeight, 'cm', (val: string) => {
          this.bodyHeight = val;
        })
        this.NumberInputField('体重', this.bodyWeight, 'kg', (val: string) => {
          this.bodyWeight = val;
        })
      }

      this.NumberInputField('腰围（可选）', this.bodyWaist, 'cm', (val: string) => {
        this.bodyWaist = val;
      })

      // BMI 自动计算
      if (this.bodyHeight.length > 0 && this.bodyWeight.length > 0) {
        if (this.canCalculateBmi()) {
          Row({ space: 8 }) {
            Text('BMI：')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
            Text(this.calculateBmiText())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.bmiStatusColor(this.calculateBmiText()))
            Text(this.bmiStatusText(this.calculateBmiText()))
              .fontSize(13)
              .fontColor(this.bmiStatusColor(this.calculateBmiText()))
              .margin({ left: 8 })
          }
          .width('100%')
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 步数 ====================

  @Builder
  StepsSection() {
    Column({ space: 12 }) {
      Text('步数')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('今日步数', this.stepsValue, '步', (val: string) => {
        this.stepsValue = val;
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 运动 ====================

  @Builder
  ExerciseSection() {
    Column({ space: 12 }) {
      Text('运动')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('运动时长', this.exerciseDuration, '分钟', (val: string) => {
        this.exerciseDuration = val;
      })

      // 运动类型（文本输入，简化版）
      Column({ space: 6 }) {
        Text('运动类型（可选）')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        TextInput({ text: this.exerciseType, placeholder: '如：快走、跑步、瑜伽等' })
          .height(40)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.exerciseType = value;
          })
      }
      .width('100%')

      this.NumberInputField('消耗热量（可选）', this.exerciseCalories, 'kcal', (val: string) => {
        this.exerciseCalories = val;
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 饮水 ====================

  @Builder
  WaterSection() {
    Column({ space: 12 }) {
      Text('饮水')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.NumberInputField('饮水量', this.waterAmount, 'mL', (val: string) => {
        this.waterAmount = val;
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 睡眠 ====================

  @Builder
  SleepSection() {
    Column({ space: 14 }) {
      Text('睡眠')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      // 睡眠类型
      this.SegmentPicker<SleepType>(
        '睡眠类型',
        [
          { value: SleepType.MAIN, label: '夜间睡眠' } as SegmentOption<SleepType>,
          { value: SleepType.NAP, label: '小睡' } as SegmentOption<SleepType>
        ],
        this.sleepType,
        (val: SleepType) => { this.sleepType = val; }
      )

      // 入睡/醒来时间
      Column({ space: 8 }) {
        Text('入睡时间')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        Row({ space: 10 }) {
          TextInput({ text: this.sleepStartDate, placeholder: '日期' })
            .height(40)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .layoutWeight(1)
            .onChange((val: string) => { this.sleepStartDate = val; })
          TextInput({ text: this.sleepStartTime, placeholder: '时间' })
            .height(40)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .layoutWeight(1)
            .onChange((val: string) => { this.sleepStartTime = val; })
        }
      }

      Column({ space: 8 }) {
        Text('醒来时间')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        Row({ space: 10 }) {
          TextInput({ text: this.sleepEndDate, placeholder: '日期' })
            .height(40)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .layoutWeight(1)
            .onChange((val: string) => { this.sleepEndDate = val; })
          TextInput({ text: this.sleepEndTime, placeholder: '时间' })
            .height(40)
            .fontSize(14)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .layoutWeight(1)
            .onChange((val: string) => { this.sleepEndTime = val; })
        }
      }

      // 总睡眠时长
      this.NumberInputField('总睡眠时长（可选）', this.sleepTotalMinutes, '分钟', (val: string) => {
        this.sleepTotalMinutes = val;
      })

      // 睡眠分期（可选）
      Column({ space: 8 }) {
        Text('睡眠分期（可选，无数据请留空）')
          .fontSize(13)
          .fontColor(MUTED_TEXT)

        Row({ space: 10 }) {
          this.NumberInputField('浅睡', this.sleepLightMinutes, '分', (val: string) => {
            this.sleepLightMinutes = val;
          })
          this.NumberInputField('深睡', this.sleepDeepMinutes, '分', (val: string) => {
            this.sleepDeepMinutes = val;
          })
        }

        Row({ space: 10 }) {
          this.NumberInputField('REM', this.sleepRemMinutes, '分', (val: string) => {
            this.sleepRemMinutes = val;
          })
          this.NumberInputField('清醒', this.sleepAwakeMinutes, '分', (val: string) => {
            this.sleepAwakeMinutes = val;
          })
        }
      }

      // 觉醒次数
      this.NumberInputField('觉醒次数（可选）', this.sleepAwakenings, '次', (val: string) => {
        this.sleepAwakenings = val;
      })

      // 主观感受
      this.SegmentPicker<SleepSubjectiveFeeling>(
        '醒后感受',
        [
          { value: SleepSubjectiveFeeling.GOOD, label: '精神良好' } as SegmentOption<SleepSubjectiveFeeling>,
          { value: SleepSubjectiveFeeling.FAIR, label: '一般' } as SegmentOption<SleepSubjectiveFeeling>,
          { value: SleepSubjectiveFeeling.TIRED, label: '困倦' } as SegmentOption<SleepSubjectiveFeeling>
        ],
        this.sleepFeeling,
        (val: SleepSubjectiveFeeling) => { this.sleepFeeling = val; }
      )

      Text('💡 睡眠分期如无设备数据请留空，不要凭感觉填写')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 通用组件 ====================

  @Builder
  NumberInputField(label: string, value: string, unit: string, onChange: (val: string) => void) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
      Row() {
        TextInput({ text: value, placeholder: '请输入' })
          .height(40)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .type(InputType.Number)
          .layoutWeight(1)
          .onChange((val: string) => {
            onChange(val);
            this.errorText = '';
            this.successText = '';
          })
        Text(unit)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .margin({ left: 8 })
      }
    }
    .layoutWeight(1)
  }

  @Builder
  SegmentPicker<T>(label: string, options: SegmentOption<T>[], selected: T, onSelect: (val: T) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(options, (option: SegmentOption<T>) => {
          Text(option.label)
            .fontSize(13)
            .fontColor(option.value === selected ? Color.White : DEEP_TEXT)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .margin({ right: 6, bottom: 6 })
            .backgroundColor(option.value === selected ? BRAND_GREEN : '#F0F0F0')
            .borderRadius(16)
            .onClick(() => {
              onSelect(option.value);
            })
        }, (option: SegmentOption<T>) => option.label as string)
      }
    }
    .width('100%')
  }

  // ==================== 保存逻辑 ====================

  private handleSave(): void {
    if (this.isSaving) return;

    // 验证
    const validation = this.validate();
    if (!validation.valid) {
      this.errorText = validation.message || '请填写必要信息';
      return;
    }

    const measurement = this.buildMeasurement();
    if (!measurement) {
      this.errorText = '数据格式错误';
      return;
    }

    if (this.onSave) {
      this.isSaving = true;
      this.errorText = '';
      this.successText = '';
      this.onSave(measurement).then((saved: boolean) => {
        if (saved) {
          this.successText = buildSaveSuccessText('healthIndicator');
          this.errorText = '';
          // 清空表单
          this.resetForm();
        } else {
          this.errorText = buildSaveFailureText('healthIndicator');
        }
      }).catch(() => {
        this.errorText = buildSaveFailureText('healthIndicator');
      }).finally(() => {
        this.isSaving = false;
      });
    }
  }

  private validate(): ValidationResult {
    switch (this.metricCode) {
      case MetricCode.BLOOD_PRESSURE:
        if (!this.bpSystolic || !this.bpDiastolic) {
          return { valid: false, message: '请填写收缩压和舒张压' } as ValidationResult;
        }
        const sys = parseFloat(this.bpSystolic);
        const dia = parseFloat(this.bpDiastolic);
        if (isNaN(sys) || isNaN(dia) || sys <= 0 || dia <= 0) {
          return { valid: false, message: '血压数值无效' } as ValidationResult;
        }
        break;
      case MetricCode.BLOOD_SUGAR:
        if (!this.bsValue) return { valid: false, message: '请填写血糖值' } as ValidationResult;
        break;
      case MetricCode.HEART_RATE:
        if (!this.hrValue) return { valid: false, message: '请填写心率值' } as ValidationResult;
        break;
      case MetricCode.BLOOD_OXYGEN:
        if (!this.boValue) return { valid: false, message: '请填写血氧值' } as ValidationResult;
        break;
      case MetricCode.TEMPERATURE:
        if (!this.tempValue) return { valid: false, message: '请填写体温' } as ValidationResult;
        break;
      case MetricCode.BODY:
        if (!this.bodyHeight && !this.bodyWeight) {
          return { valid: false, message: '请填写身高或体重' } as ValidationResult;
        }
        break;
      case MetricCode.STEPS:
        if (!this.stepsValue) return { valid: false, message: '请填写步数' } as ValidationResult;
        break;
      case MetricCode.EXERCISE:
        if (!this.exerciseDuration) return { valid: false, message: '请填写运动时长' } as ValidationResult;
        break;
      case MetricCode.WATER:
        if (!this.waterAmount) return { valid: false, message: '请填写饮水量' } as ValidationResult;
        break;
      case MetricCode.SLEEP:
        if (!this.sleepStartDate || !this.sleepStartTime || !this.sleepEndDate || !this.sleepEndTime) {
          return { valid: false, message: '请填写入睡和醒来时间' } as ValidationResult;
        }
        break;
    }
    return { valid: true } as ValidationResult;
  }

  private buildMeasurement(): HealthMeasurement | null {
    const measuredAt = this.buildMeasuredAtTimestamp();
    const note = this.recordNote.length > 0 ? this.recordNote : undefined;

    switch (this.metricCode) {
      case MetricCode.BLOOD_PRESSURE:
        return {
          metricCode: MetricCode.BLOOD_PRESSURE,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          systolic: parseFloat(this.bpSystolic),
          diastolic: parseFloat(this.bpDiastolic),
          pulse: this.bpPulse.length > 0 ? parseFloat(this.bpPulse) : undefined,
          position: this.bpPosition,
          arm: this.bpArm
        } as BloodPressureMeasurement;

      case MetricCode.BLOOD_SUGAR:
        return {
          metricCode: MetricCode.BLOOD_SUGAR,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          value: parseFloat(this.bsValue),
          sugarType: this.bsType,
          measureMethod: this.bsMeasureMethod.length > 0 ? this.bsMeasureMethod : undefined
        } as BloodSugarMeasurement;

      case MetricCode.HEART_RATE:
        return {
          metricCode: MetricCode.HEART_RATE,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          value: parseFloat(this.hrValue),
          context: this.hrContext
        } as HeartRateMeasurement;

      case MetricCode.BLOOD_OXYGEN:
        return {
          metricCode: MetricCode.BLOOD_OXYGEN,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          value: parseFloat(this.boValue)
        } as BloodOxygenMeasurement;

      case MetricCode.TEMPERATURE:
        return {
          metricCode: MetricCode.TEMPERATURE,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          value: parseFloat(this.tempValue),
          site: this.tempSite
        } as TemperatureMeasurement;

      case MetricCode.BODY: {
        const height = this.bodyHeight.length > 0 ? parseFloat(this.bodyHeight) : undefined;
        const weight = this.bodyWeight.length > 0 ? parseFloat(this.bodyWeight) : undefined;
        let bmi: number | undefined = undefined;
        if (height !== undefined && weight !== undefined && height > 0) {
          bmi = parseFloat((weight / ((height / 100) * (height / 100))).toFixed(1));
        }
        return {
          metricCode: MetricCode.BODY,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          heightCm: height,
          weightKg: weight,
          waistCm: this.bodyWaist.length > 0 ? parseFloat(this.bodyWaist) : undefined,
          bmi
        } as BodyMeasurement;
      }

      case MetricCode.STEPS:
        return {
          metricCode: MetricCode.STEPS,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          steps: parseInt(this.stepsValue) || 0
        } as StepsMeasurement;

      case MetricCode.EXERCISE:
        return {
          metricCode: MetricCode.EXERCISE,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          durationMinutes: parseInt(this.exerciseDuration) || 0,
          exerciseType: this.exerciseType.length > 0 ? this.exerciseType : undefined,
          calories: this.exerciseCalories.length > 0 ? parseFloat(this.exerciseCalories) : undefined
        } as ExerciseMeasurement;

      case MetricCode.WATER:
        return {
          metricCode: MetricCode.WATER,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          amountMl: parseInt(this.waterAmount) || 0
        } as WaterMeasurement;

      case MetricCode.SLEEP: {
        const sleepStart = this.combineDateTime(this.sleepStartDate, this.sleepStartTime);
        const sleepEnd = this.combineDateTime(this.sleepEndDate, this.sleepEndTime);
        let totalMin = this.sleepTotalMinutes.length > 0 ? parseInt(this.sleepTotalMinutes) : 0;
        if (totalMin === 0 && sleepStart.length > 0 && sleepEnd.length > 0) {
          totalMin = Math.round((new Date(sleepEnd).getTime() - new Date(sleepStart).getTime()) / 60000);
        }
        return {
          metricCode: MetricCode.SLEEP,
          measuredAt,
          source: DataSource.MANUAL,
          note,
          version: 1,
          sleepStartAt: sleepStart,
          sleepEndAt: sleepEnd,
          totalSleepMinutes: totalMin,
          lightMinutes: this.sleepLightMinutes.length > 0 ? parseInt(this.sleepLightMinutes) : undefined,
          deepMinutes: this.sleepDeepMinutes.length > 0 ? parseInt(this.sleepDeepMinutes) : undefined,
          remMinutes: this.sleepRemMinutes.length > 0 ? parseInt(this.sleepRemMinutes) : undefined,
          awakeMinutes: this.sleepAwakeMinutes.length > 0 ? parseInt(this.sleepAwakeMinutes) : undefined,
          awakenings: this.sleepAwakenings.length > 0 ? parseInt(this.sleepAwakenings) : undefined,
          sleepType: this.sleepType,
          subjectiveFeeling: this.sleepFeeling,
          feelingNote: this.sleepNote.length > 0 ? this.sleepNote : undefined
        } as SleepMeasurement;
      }

      default:
        return null;
    }
  }

  private resetForm(): void {
    this.bpSystolic = '';
    this.bpDiastolic = '';
    this.bpPulse = '';
    this.bsValue = '';
    this.hrValue = '';
    this.boValue = '';
    this.tempValue = '';
    this.bodyHeight = '';
    this.bodyWeight = '';
    this.bodyWaist = '';
    this.stepsValue = '';
    this.exerciseDuration = '';
    this.exerciseType = '';
    this.exerciseCalories = '';
    this.waterAmount = '';
    this.sleepTotalMinutes = '';
    this.sleepLightMinutes = '';
    this.sleepDeepMinutes = '';
    this.sleepRemMinutes = '';
    this.sleepAwakeMinutes = '';
    this.sleepAwakenings = '';
    this.recordNote = '';
  }

  // ==================== 工具方法 ====================

  private formTitle(): string {
    const titles: Record<string, string> = {
      [MetricCode.BLOOD_PRESSURE]: '记录血压',
      [MetricCode.BLOOD_SUGAR]: '记录血糖',
      [MetricCode.HEART_RATE]: '记录心率',
      [MetricCode.BLOOD_OXYGEN]: '记录血氧',
      [MetricCode.TEMPERATURE]: '记录体温',
      [MetricCode.BODY]: '记录体格',
      [MetricCode.STEPS]: '记录步数',
      [MetricCode.EXERCISE]: '记录运动',
      [MetricCode.WATER]: '记录饮水',
      [MetricCode.SLEEP]: '记录睡眠'
    };
    return titles[this.metricCode] || '记录指标';
  }

  private buildMeasuredAtTimestamp(): string {
    if (this.measuredAtDate && this.measuredAtTime) {
      return `${this.measuredAtDate}T${this.measuredAtTime}:00`;
    }
    return new Date().toISOString();
  }

  private combineDateTime(dateStr: string, timeStr: string): string {
    if (!dateStr || !timeStr) return new Date().toISOString();
    return `${dateStr}T${timeStr}:00`;
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  private formatTime(date: Date): string {
    const h = String(date.getHours()).padStart(2, '0');
    const m = String(date.getMinutes()).padStart(2, '0');
    return `${h}:${m}`;
  }

  private canCalculateBmi(): boolean {
    const height = parseFloat(this.bodyHeight) / 100;
    const weight = parseFloat(this.bodyWeight);
    return !isNaN(height) && !isNaN(weight) && height > 0;
  }

  private calculateBmiText(): string {
    const height = parseFloat(this.bodyHeight) / 100;
    const weight = parseFloat(this.bodyWeight);
    if (isNaN(height) || isNaN(weight) || height <= 0) return '';
    return (weight / (height * height)).toFixed(1);
  }

  private bmiStatusColor(bmi: string): ResourceColor {
    const val = parseFloat(bmi);
    if (isNaN(val)) return MUTED_TEXT;
    if (val < 18.5) return '#2196F3'; // 偏瘦-蓝
    if (val < 24) return BRAND_GREEN;   // 正常-绿
    if (val < 28) return WARM_ACCENT;   // 偏胖-橙
    return '#E53935';                    // 肥胖-红
  }

  private bmiStatusText(bmi: string): string {
    const val = parseFloat(bmi);
    if (isNaN(val)) return '';
    if (val < 18.5) return '偏瘦';
    if (val < 24) return '正常';
    if (val < 28) return '偏胖';
    return '肥胖';
  }
}
