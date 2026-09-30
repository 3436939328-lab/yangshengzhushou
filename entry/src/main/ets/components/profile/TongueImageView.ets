import { common } from '@kit.AbilityKit';
import picker from '@ohos.file.picker';
import {
  TongueImageRecord,
  TongueImageQualityStatus,
  TongueAnalysisStatus,
  TongueObservationNote
} from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { SectionTitle } from '../cards/CommonCards';
import { EmptyStateBlock } from '../cards/EmptyStateBlock';
import { getEmptyStateInfo } from '../../services/EmptyStateService';

/**
 * 舌象照片页面模式
 */
export enum TongueImageViewMode {
  LIST = 'LIST',           // 列表视图
  CAPTURE = 'CAPTURE',     // 拍照/选图
  PREVIEW = 'PREVIEW',     // 预览确认
  ANALYZING = 'ANALYZING', // 分析中
  DETAIL = 'DETAIL'        // 详情
}

@Component
export struct TongueImageView {
  @Prop images: TongueImageRecord[];
  @Prop isLoading: boolean;

  @State viewMode: TongueImageViewMode = TongueImageViewMode.LIST;
  @State selectedImage: TongueImageRecord | null = null;
  @State capturedImageUri: string = '';
  @State imageSource: 'CAMERA' | 'ALBUM' = 'CAMERA';
  @State analysisProgress: number = 0;
  @State showSourcePicker: boolean = false;

  onCaptureFromCamera?: () => void;
  onPickFromAlbum?: () => void;
  onUploadImage?: (uri: string, source: 'CAMERA' | 'ALBUM') => void;
  onRequestAnalysis?: (imageId: string) => void;
  onViewDetail?: (image: TongueImageRecord) => void;
  onDeleteImage?: (imageId: string) => void;
  onBack?: () => void;

  build() {
    Stack() {
      Column({ space: 14 }) {
        // 头部
        this.HeaderSection()

        // 内容区域
        if (this.viewMode === TongueImageViewMode.LIST) {
          this.ListView()
        } else if (this.viewMode === TongueImageViewMode.CAPTURE) {
          this.CaptureGuideView()
        } else if (this.viewMode === TongueImageViewMode.PREVIEW) {
          this.PreviewView()
        } else if (this.viewMode === TongueImageViewMode.ANALYZING) {
          this.AnalyzingView()
        } else if (this.viewMode === TongueImageViewMode.DETAIL && this.selectedImage) {
          this.DetailView(this.selectedImage)
        }
      }
      .width('100%')
      .margin({ top: 14 })

      // 来源选择弹层
      if (this.showSourcePicker) {
        this.SourcePickerSheet()
      }
    }
    .width('100%')
  }

  @Builder
  SourcePickerSheet() {
    Column() {
      Blank()
        .layoutWeight(1)
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.showSourcePicker = false;
        })

      Column({ space: 0 }) {
        Text('选择舌象照片来源')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .margin({ top: 16, bottom: 12 })

        Button() {
          Text('📷 拍照')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .height(50)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(0)
        .onClick(() => {
          this.showSourcePicker = false;
          this.captureFromCamera();
        })

        Column().height(0.5).width('100%').backgroundColor('#EEEEEE')

        Button() {
          Text('🖼️ 从相册选择')
            .fontSize(16)
            .fontColor(DEEP_TEXT)
        }
        .width('100%')
        .height(50)
        .backgroundColor(Color.White)
        .borderRadius(0)
        .onClick(() => {
          this.showSourcePicker = false;
          this.pickFromAlbum();
        })

        Button() {
          Text('取消')
            .fontSize(15)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(0)
        .margin({ top: 8 })
        .onClick(() => {
          this.showSourcePicker = false;
        })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 头部 ====================

  @Builder
  HeaderSection() {
    Row() {
      if (this.viewMode !== TongueImageViewMode.LIST && this.onBack) {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => {
            if (this.onBack) this.onBack();
            this.viewMode = TongueImageViewMode.LIST;
          })
      }

      Text(this.headerTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .margin({ left: this.viewMode !== TongueImageViewMode.LIST ? 12 : 0 })
        .layoutWeight(1)

      if (this.viewMode === TongueImageViewMode.LIST) {
        Button() {
          Text('+ 添加')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .height(34)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(17)
        .onClick(() => {
          this.showSourcePicker = true;
        })
      }
    }
    .width('100%')
  }

  private headerTitle(): string {
    switch (this.viewMode) {
      case TongueImageViewMode.LIST: return '舌象记录';
      case TongueImageViewMode.CAPTURE: return '拍摄舌象';
      case TongueImageViewMode.PREVIEW: return '照片预览';
      case TongueImageViewMode.ANALYZING: return '正在分析';
      case TongueImageViewMode.DETAIL: return '舌象详情';
      default: return '舌象记录';
    }
  }

  // ==================== 列表视图 ====================

  @Builder
  ListView() {
    Column({ space: 14 }) {
      // 拍摄引导提示
      this.CaptureTipCard()

      // 照片历史
      SectionTitle('舌象照片')
      if (this.isLoading) {
        EmptyStateBlock({ info: { title: '加载中...', detail: '正在加载舌象记录' } })
      } else if (this.images.length === 0) {
        this.EmptyImagesView()
      } else {
        this.ImagesGridView()
      }

      // 文字记录入口
      SectionTitle('文字记录')
      Text('舌色、舌苔、干湿等文字观察记录')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  CaptureTipCard() {
    Column({ space: 8 }) {
      Row() {
        Text('💡')
          .fontSize(18)
        Text('拍摄小贴士')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
          .margin({ left: 8 })
      }
      .width('100%')

      Column({ space: 4 }) {
        Text('• 自然光下拍摄，关闭美颜和滤镜')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        Text('• 舌体完整伸出，尽量保持平静')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        Text('• 避免刚食用染色食物后立即拍摄')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        Text('• 辅助观察仅供参考，不作为诊断依据')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('rgba(76, 175, 80, 0.08)')
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  EmptyImagesView() {
    Column({ space: 16 }) {
      EmptyStateBlock({ info: getEmptyStateInfo('tongue') })

      Button() {
        Text('拍摄舌象')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width(200)
      .height(44)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(22)
      .onClick(() => {
        this.showSourcePicker = true;
      })
    }
    .width('100%')
    .margin({ top: 30 })
  }

  @Builder
  ImagesGridView() {
    Grid() {
      ForEach(this.images, (image: TongueImageRecord) => {
        GridItem() {
          this.ImageGridItem(image)
        }
      }, (image: TongueImageRecord) => image.id)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
  }

  @Builder
  ImageGridItem(image: TongueImageRecord) {
    Stack() {
      // 图片占位（实际使用时替换为真实图片）
      Column() {
        Text('👅')
          .fontSize(36)
      }
      .width('100%')
      .height(120)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)

      // 质量/分析状态角标
      if (image.qualityStatus === TongueImageQualityStatus.NEED_RETAKE) {
        Text('需重拍')
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#E53935')
          .borderRadius({ bottomLeft: 8, topRight: 8 })
          .position({ top: 0, right: 0 })
      } else if (image.analysisStatus === TongueAnalysisStatus.SUCCESS) {
        Text('已分析')
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(BRAND_GREEN)
          .borderRadius({ bottomLeft: 8, topRight: 8 })
          .position({ top: 0, right: 0 })
      } else if (image.analysisStatus === TongueAnalysisStatus.ANALYZING ||
                 image.analysisStatus === TongueAnalysisStatus.QUEUED) {
        Text('分析中')
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(WARM_ACCENT)
          .borderRadius({ bottomLeft: 8, topRight: 8 })
          .position({ top: 0, right: 0 })
      }
    }
    .width('100%')
    .height(120)
    .borderRadius(8)
    .onClick(() => {
      this.selectedImage = image;
      this.viewMode = TongueImageViewMode.DETAIL;
      if (this.onViewDetail) {
        this.onViewDetail(image);
      }
    })
  }

  // ==================== 拍摄引导 ====================

  @Builder
  CaptureGuideView() {
    Column({ space: 20 }) {
      Column({ space: 12 }) {
        Text('请将舌体自然伸出')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('保持光线充足，舌面放松，不要用力')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 拍摄框占位
      Circle({ width: 200, height: 200 })
        .stroke(BRAND_GREEN)
        .strokeWidth(3)
        .fill('rgba(76, 175, 80, 0.1)')

      Column({ space: 8 }) {
        Text('拍摄前请注意')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
        Column({ space: 4 }) {
          Text('• 自然光或柔和白光下拍摄')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text('• 关闭美颜、滤镜等效果')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text('• 避免刚吃有色食物后立即拍摄')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      Button() {
        Text('开始拍摄')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(48)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(24)
      .onClick(() => {
        this.captureFromCamera();
      })

      Button() {
        Text('从相册选择')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
      }
      .width('100%')
      .height(44)
      .backgroundColor(Color.Transparent)
      .border({ width: 1, color: BRAND_GREEN })
      .borderRadius(22)
      .onClick(() => {
        this.pickFromAlbum();
      })
    }
    .width('100%')
    .padding({ top: 20 })
  }

  // ==================== 预览确认 ====================

  @Builder
  PreviewView() {
    Column({ space: 20 }) {
      Text('确认照片')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      // 预览图占位
      Column() {
        Text('👅')
          .fontSize(80)
        Text('照片预览')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .margin({ top: 12 })
      }
      .width('100%')
      .height(280)
      .backgroundColor('#F5F5F5')
      .borderRadius(CARD_RADIUS)
      .justifyContent(FlexAlign.Center)

      // 质量检查结果
      Column({ space: 10 }) {
        Row() {
          Text('质量检查')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(DEEP_TEXT)
          .layoutWeight(1)
          Text('通过')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
        }

        Column({ space: 4 }) {
          Text('✓ 舌体完整可见')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text('✓ 光线充足')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text('✓ 图像清晰')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      // 用途说明
      Column({ space: 8 }) {
        Text('📋 用途说明')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
        Text('照片将用于辅助观察舌象特征，仅本人可查看。分析结果仅供参考，不作为诊断依据。')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(76, 175, 80, 0.05)')
      .borderRadius(CARD_RADIUS)

      Button() {
        Text('上传并分析')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(48)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(24)
      .onClick(() => {
        this.viewMode = TongueImageViewMode.ANALYZING;
        this.analysisProgress = 0;
        this.startMockAnalysis();
        if (this.onUploadImage) {
          this.onUploadImage(this.capturedImageUri, this.imageSource);
        }
      })

      Button() {
        Text('重新拍摄')
          .fontSize(15)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .height(44)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.viewMode = TongueImageViewMode.CAPTURE;
      })
    }
    .width('100%')
  }

  private async pickFromAlbum(): Promise<void> {
    try {
      const photoViewPicker = new picker.PhotoViewPicker();
      const selectOption: picker.PhotoSelectOptions = {
        maxSelectNumber: 1
      };
      const result = await photoViewPicker.select(selectOption);
      if (result.photoUris.length > 0) {
        this.capturedImageUri = result.photoUris[0];
        this.imageSource = 'ALBUM';
        this.viewMode = TongueImageViewMode.PREVIEW;
        if (this.onPickFromAlbum) {
          this.onPickFromAlbum();
        }
      }
    } catch {
      this.capturedImageUri = '';
    }
  }

  private async captureFromCamera(): Promise<void> {
    try {
      const photoViewPicker = new picker.PhotoViewPicker();
      const selectOption: picker.PhotoSelectOptions = {
        maxSelectNumber: 1
      };
      const result = await photoViewPicker.select(selectOption);
      if (result.photoUris.length > 0) {
        this.capturedImageUri = result.photoUris[0];
        this.imageSource = 'CAMERA';
        this.viewMode = TongueImageViewMode.PREVIEW;
        if (this.onCaptureFromCamera) {
          this.onCaptureFromCamera();
        }
      }
    } catch {
      this.capturedImageUri = '';
    }
  }

  private startMockAnalysis(): void {
    const timer = setInterval(() => {
      this.analysisProgress += 10;
      if (this.analysisProgress >= 100) {
        clearInterval(timer);
      }
    }, 300);
  }

  // ==================== 分析中 ====================

  @Builder
  AnalyzingView() {
    Column({ space: 20 }) {
      Column({ space: 12 }) {
        // 加载动画
        Text('🔬')
          .fontSize(48)
        Text('正在分析舌象...')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('请稍候，AI 正在识别舌象特征')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 40 })

      // 进度条
      Column({ space: 8 }) {
        Row() {
          Text('分析进度')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
          .layoutWeight(1)
          Text(`${this.analysisProgress}%`)
            .fontSize(13)
            .fontColor(BRAND_GREEN)
        }

        // 进度条
        Stack() {
          Column()
            .width('100%')
            .height(8)
            .backgroundColor('#E0E0E0')
            .borderRadius(4)
          Column()
            .width(`${this.analysisProgress}%`)
            .height(8)
            .backgroundColor(BRAND_GREEN)
            .borderRadius(4)
            .alignSelf(ItemAlign.Start)
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      // 分析步骤
      Column({ space: 10 }) {
        this.AnalysisStepItem('图像质量校验', this.analysisProgress >= 20)
        this.AnalysisStepItem('舌色识别', this.analysisProgress >= 40)
        this.AnalysisStepItem('舌苔分析', this.analysisProgress >= 60)
        this.AnalysisStepItem('润燥判断', this.analysisProgress >= 80)
        this.AnalysisStepItem('生成辅助观察结果', this.analysisProgress >= 100)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      Text('⚠️ 辅助观察结果仅供参考，不能替代医生诊断')
        .fontSize(12)
        .fontColor(WARM_ACCENT)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  AnalysisStepItem(title: string, completed: boolean) {
    Row({ space: 10 }) {
      Circle({ width: 20, height: 20 })
        .fill(completed ? BRAND_GREEN : '#E0E0E0')

      Text(title)
        .fontSize(14)
        .fontColor(completed ? DEEP_TEXT : MUTED_TEXT)
        .layoutWeight(1)

      if (completed) {
        Text('✓')
          .fontSize(14)
          .fontColor(BRAND_GREEN)
      }
    }
    .width('100%')
  }

  // ==================== 详情视图 ====================

  @Builder
  DetailView(image: TongueImageRecord) {
    Column({ space: 16 }) {
      // 大图
      Column() {
        Text('👅')
          .fontSize(100)
      }
      .width('100%')
      .height(300)
      .backgroundColor('#F5F5F5')
      .borderRadius(CARD_RADIUS)
      .justifyContent(FlexAlign.Center)

      // 基本信息
      Column({ space: 10 }) {
        this.DetailRowItem('拍摄时间', image.capturedAt)
        this.DetailRowItem('来源', image.source === 'CAMERA' ? '相机拍摄' : '相册选择')
        if (image.uploadedAt) {
          this.DetailRowItem('上传时间', image.uploadedAt)
        }
        this.DetailRowItem('质量状态', this.qualityStatusText(image.qualityStatus))
        this.DetailRowItem('分析状态', this.analysisStatusText(image.analysisStatus))
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      // 分析结果
      if (image.analysisResult && image.analysisStatus === TongueAnalysisStatus.SUCCESS) {
        Column({ space: 12 }) {
          Row() {
            Text('辅助观察结果')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
            .layoutWeight(1)
            if (image.modelVersion) {
              Text(image.modelVersion)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
          }
          .width('100%')

          this.DetailRowItem('舌色', image.analysisResult.color)
          this.DetailRowItem('舌苔', image.analysisResult.coating)
          this.DetailRowItem('润燥', image.analysisResult.dryness)

          if (image.analysisResult.note) {
            Column({ space: 4 }) {
              Text('备注')
                .fontSize(13)
                .fontColor(MUTED_TEXT)
              Text(image.analysisResult.note)
                .fontSize(14)
                .fontColor(DEEP_TEXT)
                .lineHeight(22)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          Text('⚠️ 以上为 AI 辅助观察结果，仅供参考，不作为诊断依据')
            .fontSize(12)
            .fontColor(WARM_ACCENT)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(CARD_RADIUS)
      }

      // 操作按钮
      if (image.analysisStatus === TongueAnalysisStatus.FAILED ||
          image.qualityStatus === TongueImageQualityStatus.NEED_RETAKE) {
        Button() {
          Text('重新分析')
            .fontSize(15)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .height(44)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(22)
        .onClick(() => {
          if (this.onRequestAnalysis) {
            this.onRequestAnalysis(image.id);
          }
        })
      }

      // 删除
      Button() {
        Text('删除此照片')
          .fontSize(14)
          .fontColor('#E53935')
      }
      .width('100%')
      .height(44)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        if (this.onDeleteImage) {
          this.onDeleteImage(image.id);
        }
        this.viewMode = TongueImageViewMode.LIST;
      })
    }
    .width('100%')
  }

  @Builder
  DetailRowItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .width(80)
      Text(value)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .layoutWeight(1)
    }
    .width('100%')
  }

  private qualityStatusText(status: TongueImageQualityStatus): string {
    switch (status) {
      case TongueImageQualityStatus.PENDING: return '待检查';
      case TongueImageQualityStatus.ANALYZABLE: return '可分析';
      case TongueImageQualityStatus.NEED_RETAKE: return '需要重拍';
      default: return '未知';
    }
  }

  private analysisStatusText(status: TongueAnalysisStatus): string {
    switch (status) {
      case TongueAnalysisStatus.PENDING_UPLOAD: return '待上传';
      case TongueAnalysisStatus.UPLOADING: return '上传中';
      case TongueAnalysisStatus.QUEUED: return '排队中';
      case TongueAnalysisStatus.ANALYZING: return '分析中';
      case TongueAnalysisStatus.SUCCESS: return '分析完成';
      case TongueAnalysisStatus.FAILED: return '分析失败';
      case TongueAnalysisStatus.CANCELLED: return '已取消';
      default: return '未知';
    }
  }
}
