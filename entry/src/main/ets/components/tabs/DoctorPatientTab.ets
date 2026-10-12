import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  ConsultationThread,
  fetchDoctorConsultations
} from '../../services/ConsultationService';

interface PatientItem {
  userId: string;
  name: string;
  gender: string;
  age: number;
  consultationCount: number;
  lastConsultationTime: string;
  lastSymptom: string;
  statusText: string;
  statusCode: number;
  latestConsultationId: string;
}

interface DoctorPatientTabParams {
  doctorId: string;
  onOpenConsultation?: (consultationId: string) => void;
}

@Component
export struct DoctorPatientTab {
  @Prop doctorId: string;
  onOpenConsultation?: (consultationId: string) => void;

  @State patients: PatientItem[] = [];
  @State filteredPatients: PatientItem[] = [];
  @State isLoading: boolean = true;
  @State feedback: string = '';
  @State searchKeyword: string = '';
  @State selectedPatient: PatientItem | null = null;
  @State showDetail: boolean = false;
  @State patientConsultations: ConsultationThread[] = [];

  aboutToAppear() {
    this.refresh();
  }

  aboutToReappear() {
    this.refresh();
  }

  private refresh(): void {
    if (this.doctorId.length === 0) return;
    this.isLoading = true;
    this.feedback = '';
    fetchDoctorConsultations(this.doctorId)
      .then((threads: ConsultationThread[]) => {
        this.patients = this.groupByPatient(threads);
        this.applyFilter();
      })
      .catch((err: Error) => {
        this.feedback = err.message;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  private groupByPatient(threads: ConsultationThread[]): PatientItem[] {
    const map: Record<string, PatientItem> = {};
    for (let i = 0; i < threads.length; i++) {
      const t = threads[i];
      const uid = t.userId;
      if (!map[uid]) {
        const name = t.sharedName && t.sharedName.length > 0
          ? t.sharedName
          : ('用户' + (uid ? uid.slice(-4) : ''));
        map[uid] = {
          userId: uid,
          name: name,
          gender: t.sharedGender || '',
          age: t.sharedAge || 0,
          consultationCount: 0,
          lastConsultationTime: t.createTime,
          lastSymptom: t.symptom || '',
          statusText: t.statusText,
          statusCode: t.statusCode,
          latestConsultationId: t.id
        };
      }
      map[uid].consultationCount++;
      // 按时间找最新的
      if (t.createTime > map[uid].lastConsultationTime) {
        map[uid].lastConsultationTime = t.createTime;
        map[uid].lastSymptom = t.symptom || '';
        map[uid].statusText = t.statusText;
        map[uid].statusCode = t.statusCode;
        map[uid].latestConsultationId = t.id;
      }
    }
    // 按最后问诊时间倒序
    return Object.values(map).sort((a: PatientItem, b: PatientItem) => {
      return b.lastConsultationTime.localeCompare(a.lastConsultationTime);
    });
  }

  private applyFilter(): void {
    if (!this.searchKeyword || this.searchKeyword.trim().length === 0) {
      this.filteredPatients = this.patients;
      return;
    }
    const kw = this.searchKeyword.trim().toLowerCase();
    this.filteredPatients = this.patients.filter((p: PatientItem) => {
      return p.name.toLowerCase().indexOf(kw) >= 0
        || p.lastSymptom.toLowerCase().indexOf(kw) >= 0;
    });
  }

  private onSearchChange(value: string): void {
    this.searchKeyword = value;
    this.applyFilter();
  }

  private openPatientDetail(patient: PatientItem): void {
    this.selectedPatient = patient;
    this.patientConsultations = this.getPatientConsultations(patient.userId);
    this.showDetail = true;
  }

  private getPatientConsultations(userId: string): ConsultationThread[] {
    // 由于我们没有直接的患者问诊列表接口，这里先返回空
    // 实际使用时可以从已加载的问诊中过滤
    // 这里简化处理
    return [];
  }

  private formatTime(timeStr: string): string {
    if (!timeStr) return '';
    // 简单格式化：取日期部分
    return timeStr.substring(0, 10);
  }

  build() {
    Stack() {
      Column() {
        if (this.showDetail && this.selectedPatient) {
          this.PatientDetailView()
        } else {
          this.PatientListView()
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 患者列表 ====================
  @Builder
  PatientListView() {
    Column({ space: 0 }) {
      // 顶部标题
      Text('我的患者')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')
        .padding({ left: 18, top: 18, bottom: 12 })

      // 搜索框
      Row() {
        Text('🔍')
          .fontSize(14)
          .margin({ right: 6 })
        TextInput({ placeholder: '搜索患者姓名或症状', text: this.searchKeyword })
          .fontSize(13)
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => { this.onSearchChange(value); })
      }
      .width('100%')
      .height(36)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#F5F6F5')
      .borderRadius(18)
      .margin({ left: 14, right: 14, bottom: 10 })

      // 患者统计
      Row() {
        Text(`共 ${this.patients.length} 位患者`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        Blank()
        if (this.searchKeyword.length > 0) {
          Text(`找到 ${this.filteredPatients.length} 位`)
            .fontSize(12)
            .fontColor(BRAND_GREEN)
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, bottom: 8 })

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
        }
        .layoutWeight(1)
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredPatients.length === 0) {
        Column({ space: 8 }) {
          Text('暂无患者')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
          Text('有患者向你发起问诊后，这里会显示患者列表')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .maxLines(2)
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 40, right: 40 })
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.filteredPatients, (patient: PatientItem) => {
              this.PatientCardItem(patient)
            }, (patient: PatientItem) => patient.userId)
          }
          .width('100%')
          .padding({ left: 14, right: 14, bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PatientCardItem(patient: PatientItem) {
    Row({ space: 12 }) {
      // 头像
      Column() {
        Text(patient.name.charAt(0))
          .fontSize(18)
          .fontColor(Color.White)
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor('#5BA839')
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(patient.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          if (patient.age > 0 || patient.gender) {
            Text([patient.gender, patient.age > 0 ? `${patient.age}岁` : ''].filter(s => s).join(' · '))
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
        }
        if (patient.lastSymptom) {
          Text('最近：' + patient.lastSymptom)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        Row({ space: 8 }) {
          Text(`共 ${patient.consultationCount} 次问诊`)
            .fontSize(11)
            .fontColor(MUTED_TEXT)
          Text(patient.statusText)
            .fontSize(11)
            .fontColor(patient.statusCode === 0 ? WARM_ACCENT : BRAND_GREEN)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .backgroundColor(patient.statusCode === 0 ? '#FFF4E6' : '#EEF7F1')
            .borderRadius(6)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('查看 ▶')
        .fontSize(12)
        .fontColor(BRAND_GREEN)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .onClick(() => {
      this.openPatientDetail(patient);
    })
  }

  // ==================== 患者详情 ====================
  @Builder
  PatientDetailView() {
    Column({ space: 0 }) {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor(DEEP_TEXT)
          .onClick(() => { this.showDetail = false; this.selectedPatient = null; })
        Text('患者详情')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column({ space: 14 }) {
          // 患者基本信息卡片
          this.PatientInfoCard(this.selectedPatient!)

          // 最近问诊
          this.LatestConsultationCard(this.selectedPatient!)

          // 操作按钮
          this.PatientActionButtons(this.selectedPatient!)
        }
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 20, top: 10 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F5')
  }

  @Builder
  PatientInfoCard(patient: PatientItem) {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Column() {
          Text(patient.name.charAt(0))
            .fontSize(22)
            .fontColor(Color.White)
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#5BA839')
        .justifyContent(FlexAlign.Center)

        Column({ space: 4 }) {
          Text(patient.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Row({ space: 8 }) {
            if (patient.gender) {
              Text(patient.gender)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
            }
            if (patient.age > 0) {
              Text(`${patient.age} 岁`)
                .fontSize(12)
                .fontColor(MUTED_TEXT)
            }
            Text(`问诊 ${patient.consultationCount} 次`)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  LatestConsultationCard(patient: PatientItem) {
    Column({ space: 10 }) {
      Row() {
        Column()
          .width(3)
          .height(12)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text('最近问诊')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 6 })
        Blank()
        Text(this.formatTime(patient.lastConsultationTime))
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')

      Column({ space: 6 }) {
        Row() {
          Text('主诉：')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text(patient.lastSymptom || '暂无')
            .fontSize(13)
            .fontColor(DEEP_TEXT)
            .maxLines(2)
        }
        .width('100%')

        Row() {
          Text('状态：')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text(patient.statusText)
            .fontSize(12)
            .fontColor(patient.statusCode === 0 ? WARM_ACCENT : BRAND_GREEN)
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  PatientActionButtons(patient: PatientItem) {
    Row({ space: 10 }) {
      Button() {
        Text('查看历史问诊')
          .fontSize(14)
          .fontColor(BRAND_GREEN)
      }
      .layoutWeight(1)
      .height(40)
      .backgroundColor('#EEF7F1')
      .borderRadius(20)
      .enabled(false) // 暂无独立接口，先禁用
      .onClick(() => {})

      Button() {
        Text(patient.statusCode === 2 ? '发起新问诊' : '继续问诊')
          .fontSize(14)
          .fontColor(Color.White)
      }
      .layoutWeight(1)
      .height(40)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(20)
      .onClick(() => {
        if (this.onOpenConsultation) {
          this.onOpenConsultation(patient.latestConsultationId);
        }
      })
    }
    .width('100%')
  }
}
