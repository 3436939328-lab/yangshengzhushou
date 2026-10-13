import { ConnectionPanel } from './ConnectionPanel';
import {
  AuthSession,
  PasswordResetTarget,
  SmsCodeResult,
  buildAuthFailureText,
  identifyPasswordResetAccount,
  isValidPhone,
  loginWithPhone,
  loginWithSmsCode,
  registerWithPhone,
  resetPasswordWithSmsCode,
  sendAuthSmsCode
} from '../services/AuthService';
import { discoverBackendOnLan } from '../services/BackendDiscoveryService';
import { saveConnectionSettings } from '../services/ConnectionSettings';
import { common } from '@kit.AbilityKit';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  LINE_BG,
  MUTED_TEXT,
  PAGE_BG,
  WARM_ACCENT
} from '../theme/WellnessTheme';

@Component
export struct AuthView {
  onAuthenticated?: (session: AuthSession) => void;
  @Prop initialNotice: string = '';

  @State authMode: string = 'login';
  @State loginMode: string = 'password';
  @State phone: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State code: string = '';
  @State registerRoleCode: string = 'USER';
  @State resetAccount: string = '';
  @State resetPhone: string = '';
  @State resetMaskedPhone: string = '';
  @State resetCode: string = '';
  @State resetPassword: string = '';
  @State resetConfirmPassword: string = '';
  @State resetStep: number = 1;
  @State actionText: string = '';
  @State isSubmitting: boolean = false;
  @State isSendingCode: boolean = false;
  @State isAutoDiscovering: boolean = false;

  build() {
    Column() {
      Blank()
      Text('茹安阁')
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('登录后保存你的本地健康档案入口')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .margin({ top: 8, bottom: 28 })

      Column({ space: 14 }) {
        Text(this.titleText())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(BRAND_GREEN)

        if (this.authMode === 'login') {
          this.LoginForm()
        } else if (this.authMode === 'register') {
          this.RegisterForm()
        } else {
          this.PasswordResetForm()
        }

        if (this.actionText.length > 0 || this.initialNotice.length > 0) {
          Text(this.actionText.length > 0 ? this.actionText : this.initialNotice)
            .fontSize(12)
            .fontColor(WARM_ACCENT)
            .lineHeight(18)
        }

        Button(this.primaryButtonText())
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(BRAND_GREEN)
          .width('100%')
          .height(48)
          .borderRadius(CARD_RADIUS)
          .enabled(!this.isSubmitting && !this.isAutoDiscovering)
          .onClick(() => {
            this.submitAuth();
          })

        this.FooterActions()
        ConnectionPanel()
      }
      .width('100%')
      .padding(20)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22 })
    .backgroundColor(Color.Transparent)
  }

  @Builder
  LoginForm() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        this.LoginModeButton('密码登录', 'password')
        this.LoginModeButton('验证码登录', 'sms')
      }
      .width('100%')

      this.PhoneInput()

      if (this.loginMode === 'password') {
        this.PasswordInput('密码', this.password, 'password')
      } else {
        this.CodeInput('短信验证码', this.code, 'LOGIN', 'code')
      }
    }
    .width('100%')
  }

  @Builder
  RegisterForm() {
    Column({ space: 12 }) {
      this.PhoneInput()
      this.PasswordInput('密码（至少6位）', this.password, 'password')
      this.PasswordInput('确认密码', this.confirmPassword, 'confirmPassword')

      Column({ space: 8 }) {
        Text('选择注册身份')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        Row({ space: 10 }) {
          this.RoleOptionButton('普通用户', 'USER')
          this.RoleOptionButton('医生入驻', 'DOCTOR')
        }
        .width('100%')
        Text(this.registerRoleCode === 'DOCTOR' ? '健康顾问身份用于提供养生咨询与健康建议。' : '普通用户可使用健康助手、健康档案和养生咨询。')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      this.CodeInput('注册验证码', this.code, 'REGISTER', 'code')
    }
    .width('100%')
  }

  @Builder
  PasswordResetForm() {
    Column({ space: 12 }) {
      if (this.resetStep === 1) {
        TextInput({ placeholder: '手机号', text: this.resetAccount })
          .height(48)
          .fontSize(15)
          .backgroundColor('#F6F8F5')
          .borderRadius(CARD_RADIUS)
          .onChange((value: string) => {
            this.resetAccount = value;
          })
      } else {
        Text(this.resetMaskedPhone.length > 0 ? `验证手机号：${this.resetMaskedPhone}` : '验证绑定手机号')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(18)

        this.CodeInput('短信验证码', this.resetCode, 'RESET_PASSWORD', 'resetCode')
        this.PasswordInput('新密码（至少6位）', this.resetPassword, 'resetPassword')
        this.PasswordInput('确认新密码', this.resetConfirmPassword, 'resetConfirmPassword')
      }
    }
    .width('100%')
  }

  @Builder
  FooterActions() {
    if (this.authMode === 'login') {
      Row({ space: 10 }) {
        Button('没有账号，去注册')
          .fontSize(14)
          .fontColor(BRAND_GREEN)
          .backgroundColor(CARD_BG)
          .border({ width: 1, color: LINE_BG })
          .height(44)
          .layoutWeight(1)
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.switchAuthMode('register');
          })
        Button('忘记密码')
          .fontSize(14)
          .fontColor(BRAND_GREEN)
          .backgroundColor(CARD_BG)
          .border({ width: 1, color: LINE_BG })
          .height(44)
          .layoutWeight(1)
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.switchAuthMode('reset');
          })
      }
      .width('100%')
    } else {
      Button(this.authMode === 'register' ? '已有账号，去登录' : '返回登录')
        .fontSize(14)
        .fontColor(BRAND_GREEN)
        .backgroundColor(CARD_BG)
        .border({ width: 1, color: LINE_BG })
        .width('100%')
        .height(44)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          this.switchAuthMode('login');
        })
    }
  }

  @Builder
  PhoneInput() {
    TextInput({ placeholder: '手机号', text: this.phone })
      .type(InputType.PhoneNumber)
      .height(48)
      .fontSize(15)
      .backgroundColor('#F6F8F5')
      .borderRadius(CARD_RADIUS)
      .onChange((value: string) => {
        this.phone = value;
      })
  }

  @Builder
  PasswordInput(placeholder: string, value: string, stateKey: string) {
    TextInput({ placeholder, text: value })
      .type(InputType.Password)
      .height(48)
      .fontSize(15)
      .backgroundColor('#F6F8F5')
      .borderRadius(CARD_RADIUS)
      .onChange((inputValue: string) => {
        this.updatePasswordValue(stateKey, inputValue);
      })
  }

  @Builder
  CodeInput(placeholder: string, value: string, purpose: string, stateKey: string) {
    Row({ space: 10 }) {
      TextInput({ placeholder, text: value })
        .type(InputType.Number)
        .height(48)
        .fontSize(15)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .layoutWeight(1)
        .onChange((inputValue: string) => {
          this.updateCodeValue(stateKey, inputValue);
        })
      Button(this.isSendingCode ? '发送中' : '获取验证码')
        .fontSize(13)
        .fontColor(BRAND_GREEN)
        .backgroundColor('#EEF7F1')
        .height(48)
        .width(104)
        .borderRadius(CARD_RADIUS)
        .enabled(!this.isSendingCode)
        .onClick(() => {
          this.sendCode(purpose);
        })
    }
    .width('100%')
  }

  @Builder
  LoginModeButton(label: string, mode: string) {
    Button(label)
      .fontSize(14)
      .fontColor(this.loginMode === mode ? '#FFFFFF' : BRAND_GREEN)
      .backgroundColor(this.loginMode === mode ? BRAND_GREEN : '#EEF7F1')
      .height(40)
      .layoutWeight(1)
      .borderRadius(CARD_RADIUS)
      .onClick(() => {
        this.loginMode = mode;
        this.actionText = '';
      })
  }

  @Builder
  RoleOptionButton(label: string, roleCode: string) {
    Button(label)
      .fontSize(14)
      .fontColor(this.registerRoleCode === roleCode ? '#FFFFFF' : BRAND_GREEN)
      .backgroundColor(this.registerRoleCode === roleCode ? BRAND_GREEN : '#EEF7F1')
      .height(40)
      .layoutWeight(1)
      .borderRadius(CARD_RADIUS)
      .onClick(() => {
        this.registerRoleCode = roleCode;
      })
  }

  private titleText(): string {
    if (this.authMode === 'register') {
      return '注册账号';
    }
    if (this.authMode === 'reset') {
      return this.resetStep === 1 ? '找回密码' : '重设密码';
    }
    return '登录账号';
  }

  private primaryButtonText(): string {
    if (this.isAutoDiscovering) {
      return '查找后端中...';
    }
    if (this.isSubmitting) {
      return '处理中...';
    }
    if (this.authMode === 'register') {
      return '注册并进入';
    }
    if (this.authMode === 'reset') {
      return this.resetStep === 1 ? '下一步验证身份' : '修改密码';
    }
    return '登录';
  }

  private switchAuthMode(mode: string): void {
    this.authMode = mode;
    this.actionText = '';
    if (mode === 'reset') {
      this.resetStep = 1;
      this.resetAccount = this.phone.trim();
      this.resetPhone = '';
      this.resetMaskedPhone = '';
      this.resetCode = '';
      this.resetPassword = '';
      this.resetConfirmPassword = '';
    }
  }

  private updatePasswordValue(stateKey: string, value: string): void {
    if (stateKey === 'confirmPassword') {
      this.confirmPassword = value;
    } else if (stateKey === 'resetPassword') {
      this.resetPassword = value;
    } else if (stateKey === 'resetConfirmPassword') {
      this.resetConfirmPassword = value;
    } else {
      this.password = value;
    }
  }

  private updateCodeValue(stateKey: string, value: string): void {
    if (stateKey === 'resetCode') {
      this.resetCode = value;
    } else {
      this.code = value;
    }
  }

  private validatePhone(value: string): boolean {
    if (value.trim().length !== 11) {
      this.actionText = '请输入11位手机号';
      return false;
    }
    return true;
  }

  private validatePassword(value: string): boolean {
    if (value.length < 6) {
      this.actionText = '密码至少需要6位';
      return false;
    }
    return true;
  }

  private validateCode(value: string): boolean {
    if (value.trim().length === 0) {
      this.actionText = '请输入短信验证码';
      return false;
    }
    return true;
  }

  private sendCode(purpose: string): void {
    const targetPhone = purpose === 'RESET_PASSWORD' ? this.resetPhone : this.phone;
    if (!this.validatePhone(targetPhone)) {
      return;
    }
    this.isSendingCode = true;
    this.actionText = '';
    this.executeSmsRequest(sendAuthSmsCode(targetPhone, purpose), purpose).then((result: SmsCodeResult) => {
      this.isSendingCode = false;
      this.actionText = '验证码已发送，请查看手机短信';
    }).catch((error: Error) => {
      this.isSendingCode = false;
      this.actionText = buildAuthFailureText(this.authMode === 'register', error.message);
    });
  }

  private executeSmsRequest(request: Promise<SmsCodeResult>, purpose: string): Promise<SmsCodeResult> {
    return request.catch((error: Error) => {
      if (!this.isNetworkError(error.message)) {
        return Promise.reject(error);
      }
      this.isAutoDiscovering = true;
      this.actionText = '网络连接失败，正在自动查找后端...';
      return discoverBackendOnLan().then((found: string) => {
        this.isAutoDiscovering = false;
        if (found.length === 0) {
          return Promise.reject(new Error('无法连接后端，请确认 8181 后端已启动。'));
        }
        return saveConnectionSettings(this.getUIContext().getHostContext() as common.UIAbilityContext, found)
          .then(() => {
            this.actionText = `已自动切换到后端：${found}，正在重发验证码...`;
            const targetPhone = purpose === 'RESET_PASSWORD' ? this.resetPhone : this.phone;
            return sendAuthSmsCode(targetPhone, purpose);
          });
      }).catch(() => {
        this.isAutoDiscovering = false;
        return Promise.reject(new Error('网络连接失败，请点击"服务器连接设置"自动查找后端。'));
      });
    });
  }

  private submitAuth(): void {
    if (this.authMode === 'reset') {
      this.submitPasswordReset();
      return;
    }
    if (!this.validatePhone(this.phone)) {
      return;
    }

    let request: Promise<AuthSession>;
    if (this.authMode === 'register') {
      if (!this.validatePassword(this.password)) {
        return;
      }
      if (this.password !== this.confirmPassword) {
        this.actionText = '两次输入的密码不一致';
        return;
      }
      if (!this.validateCode(this.code)) {
        return;
      }
      request = registerWithPhone(this.phone, this.password, this.registerRoleCode, this.code);
    } else if (this.loginMode === 'sms') {
      if (!this.validateCode(this.code)) {
        return;
      }
      request = loginWithSmsCode(this.phone, this.code);
    } else {
      if (!this.validatePassword(this.password)) {
        return;
      }
      request = loginWithPhone(this.phone, this.password);
    }

    this.isSubmitting = true;
    this.actionText = '';
    this.executeAuthRequest(request).then((session: AuthSession) => {
      this.isSubmitting = false;
      if (this.onAuthenticated) {
        this.onAuthenticated(session);
      }
    }).catch((error: Error) => {
      this.isSubmitting = false;
      this.actionText = buildAuthFailureText(this.authMode === 'register', error.message);
    });
  }

  /**
   * 执行认证请求，遇到网络错误时自动发现后端并重试一次。
   */
  private executeAuthRequest(request: Promise<AuthSession>): Promise<AuthSession> {
    return request.catch((error: Error) => {
      if (!this.isNetworkError(error.message)) {
        return Promise.reject(error);
      }
      return this.autoDiscoverAndRetry(() => {
        // 重新构建请求，因为 baseUrl 可能已变更
        return this.rebuildAuthRequest();
      });
    });
  }

  private rebuildAuthRequest(): Promise<AuthSession> {
    if (this.authMode === 'register') {
      return registerWithPhone(this.phone, this.password, this.registerRoleCode, this.code);
    }
    if (this.loginMode === 'sms') {
      return loginWithSmsCode(this.phone, this.code);
    }
    return loginWithPhone(this.phone, this.password);
  }

  private autoDiscoverAndRetry(retryFactory: () => Promise<AuthSession>): Promise<AuthSession> {
    this.isAutoDiscovering = true;
    this.actionText = '网络连接失败，正在自动查找后端...';
    return discoverBackendOnLan().then((found: string) => {
      this.isAutoDiscovering = false;
      if (found.length === 0) {
        return Promise.reject(new Error('无法连接后端，请确认 8181 后端已启动，且手机和电脑在同一网络。'));
      }
      return saveConnectionSettings(this.getUIContext().getHostContext() as common.UIAbilityContext, found)
        .then(() => {
          this.actionText = `已自动切换到后端：${found}，正在重试...`;
          return retryFactory();
        });
    }).catch((discoveryError: Error) => {
      this.isAutoDiscovering = false;
      return Promise.reject(new Error('网络连接失败，请点击"服务器连接设置"使用电脑名或自动查找后端。'));
    });
  }

  private isNetworkError(message: string): boolean {
    const lower = message.toLowerCase();
    return lower.indexOf('无法连接') >= 0
      || lower.indexOf('响应超时') >= 0
      || lower.indexOf('timeout') >= 0
      || lower.indexOf('econnrefused') >= 0
      || lower.indexOf('connection refused') >= 0
      || lower.indexOf('failed to fetch') >= 0
      || lower.indexOf('network') >= 0;
  }

  private submitPasswordReset(): void {
    if (this.resetStep === 1) {
      if (!isValidPhone(this.resetAccount.trim())) {
        this.actionText = '请输入正确的手机号';
        return;
      }
      this.isSubmitting = true;
      this.actionText = '';
      identifyPasswordResetAccount(this.resetAccount).then((target: PasswordResetTarget) => {
        this.isSubmitting = false;
        this.resetPhone = this.resetAccount.trim();
        this.resetMaskedPhone = target.maskedPhone;
        this.resetStep = 2;
        this.actionText = target.maskedPhone.length > 0 ? `已确认账号，绑定手机号：${target.maskedPhone}` : '已确认账号';
      }).catch((error: Error) => {
        this.isSubmitting = false;
        this.actionText = buildAuthFailureText(false, error.message);
      });
      return;
    }

    if (!this.validateCode(this.resetCode) || !this.validatePassword(this.resetPassword)) {
      return;
    }
    if (this.resetPassword !== this.resetConfirmPassword) {
      this.actionText = '两次输入的新密码不一致';
      return;
    }
    this.isSubmitting = true;
    this.actionText = '';
    resetPasswordWithSmsCode(this.resetPhone, this.resetCode, this.resetPassword).then(() => {
      this.isSubmitting = false;
      this.phone = this.resetPhone;
      this.password = '';
      this.code = '';
      this.loginMode = 'password';
      this.authMode = 'login';
      this.actionText = '密码已修改，请使用新密码登录。';
    }).catch((error: Error) => {
      this.isSubmitting = false;
      this.actionText = buildAuthFailureText(false, error.message);
    });
  }
}
