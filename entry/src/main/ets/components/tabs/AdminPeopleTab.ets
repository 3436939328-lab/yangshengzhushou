import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  AdminUserItem,
  createAdminUser,
  deleteAdminUser,
  fetchAdminUsers,
  updateAdminUser
} from '../../services/AdminPeopleService';
import {
  AdminRoleItem,
  AdminUserRoleItem,
  assignAdminUserRole,
  deleteAdminUserRole,
  fetchAdminRoles,
  fetchAdminUserRoles
} from '../../services/AdminRoleService';
import { AdminPeopleFilter, buildFilteredAdminUsers } from '../../services/AdminPeopleFilterService';

@Component
export struct AdminPeopleTab {
  @State users: AdminUserItem[] = [];
  @State selectedUserId: string = '';
  @State username: string = '';
  @State realName: string = '';
  @State phone: string = '';
  @State newPassword: string = '123456';
  @State newRoleCode: string = 'USER';
  @State feedback: string = '';
  @State roles: AdminRoleItem[] = [];
  @State userRoles: AdminUserRoleItem[] = [];
  @State visibleUsers: AdminUserItem[] = [];
  @State currentFilter: AdminPeopleFilter = 'ALL';

  aboutToAppear() {
    this.refreshUsers();
    this.refreshRoleData();
  }

  build() {
    Column({ space: 14 }) {
      Text('人员管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('管理员可查看、新增、编辑和删除人员基础信息，并按身份筛选。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)

      this.EditorPanel()
      this.RolePanel()
      this.FilterPanel()
      this.UserList()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  EditorPanel() {
    Column({ space: 10 }) {
      Text(this.selectedUserId.length > 0 ? `编辑用户 #${this.selectedUserId}` : '新增用户')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      TextInput({ placeholder: '用户名', text: this.username })
        .height(42)
        .fontSize(14)
        .enabled(this.selectedUserId.length === 0)
        .onChange((value: string) => {
          this.username = value;
        })
      TextInput({ placeholder: '姓名', text: this.realName })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.realName = value;
        })
      TextInput({ placeholder: '手机号', text: this.phone })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.phone = value;
        })
      if (this.selectedUserId.length === 0) {
        TextInput({ placeholder: '初始密码，默认 123456', text: this.newPassword })
          .height(42)
          .fontSize(14)
          .type(InputType.Password)
          .onChange((value: string) => {
            this.newPassword = value;
          })
        Row({ space: 8 }) {
          this.CreateRoleButton('普通用户', 'USER')
          this.CreateRoleButton('医生', 'DOCTOR')
          this.CreateRoleButton('管理员', 'ADMIN')
        }
        .width('100%')
      }
      Row({ space: 10 }) {
        Button(this.selectedUserId.length > 0 ? '保存修改' : '新增人员')
          .layoutWeight(1)
          .height(40)
          .fontColor('#FFFFFF')
          .backgroundColor(BRAND_GREEN)
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.saveUser();
          })
        Button('清空')
          .layoutWeight(1)
          .height(40)
          .fontColor(BRAND_GREEN)
          .backgroundColor('#EEF7F1')
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.clearForm();
          })
      }
      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(12)
          .fontColor(this.feedback.indexOf('成功') >= 0 ? BRAND_GREEN : WARM_ACCENT)
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  CreateRoleButton(label: string, roleCode: string) {
    Button(label)
      .layoutWeight(1)
      .height(34)
      .fontSize(12)
      .fontColor(this.newRoleCode === roleCode ? '#FFFFFF' : BRAND_GREEN)
      .backgroundColor(this.newRoleCode === roleCode ? BRAND_GREEN : '#EEF7F1')
      .borderRadius(14)
      .onClick(() => {
        this.newRoleCode = roleCode;
      })
  }

  @Builder
  RolePanel() {
    Column({ space: 10 }) {
      Text('角色分配')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      if (this.selectedUserId.length === 0) {
        Text('先在人员列表中选择一个人，再分配普通用户、医生或管理员角色。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else {
        Text(`当前人员 #${this.selectedUserId}`)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.displayRoles(), (role: AdminRoleItem) => {
            Button(this.roleDisplayName(role))
              .fontSize(12)
              .fontColor(this.isRoleAssigned(role.id) ? '#FFFFFF' : BRAND_GREEN)
              .backgroundColor(this.isRoleAssigned(role.id) ? BRAND_GREEN : '#EEF7F1')
              .borderRadius(14)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.assignRole(role.id);
              })
          }, (role: AdminRoleItem) => role.id)
        }
        .width('100%')
        if (this.selectedUserRoles().length === 0) {
          Text('当前未绑定角色。')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
        } else {
          ForEach(this.selectedUserRoles(), (binding: AdminUserRoleItem) => {
            Row({ space: 10 }) {
              Text(this.roleName(binding.roleId))
                .fontSize(14)
                .fontColor(DEEP_TEXT)
                .layoutWeight(1)
              Button('移除')
                .fontSize(12)
                .fontColor(WARM_ACCENT)
                .backgroundColor('#FFF2E8')
                .borderRadius(12)
                .onClick(() => {
                  this.removeRoleBinding(binding.id);
                })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#FAFCFA')
            .borderRadius(CARD_RADIUS)
          }, (binding: AdminUserRoleItem) => binding.id)
        }
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  FilterPanel() {
    Column({ space: 10 }) {
      Text('身份筛选')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Flex({ wrap: FlexWrap.Wrap }) {
        this.FilterChip('全部', 'ALL')
        this.FilterChip('普通用户', 'USER')
        this.FilterChip('管理员', 'ADMIN')
        this.FilterChip('医生', 'DOCTOR')
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  FilterChip(label: string, filter: AdminPeopleFilter) {
    Button(label)
      .fontSize(12)
      .fontColor(this.currentFilter === filter ? '#FFFFFF' : BRAND_GREEN)
      .backgroundColor(this.currentFilter === filter ? BRAND_GREEN : '#EEF7F1')
      .borderRadius(14)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.setFilter(filter);
      })
  }

  @Builder
  UserList() {
    Column({ space: 10 }) {
      Text(`人员列表 · ${this.visibleUsers.length}`)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      if (this.visibleUsers.length === 0) {
        Text('当前筛选条件下暂无人员数据。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else {
        ForEach(this.visibleUsers, (user: AdminUserItem) => {
          Column({ space: 10 }) {
            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text(user.realName.length > 0 ? user.realName : user.username)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(DEEP_TEXT)
                Text(`${user.phone} · ${user.statusText}`)
                  .fontSize(12)
                  .fontColor(MUTED_TEXT)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Button('编辑')
                .fontSize(12)
                .fontColor(BRAND_GREEN)
                .backgroundColor('#EEF7F1')
                .borderRadius(12)
                .onClick(() => {
                  this.pickUser(user);
                })
              Button('删除')
                .fontSize(12)
                .fontColor(WARM_ACCENT)
                .backgroundColor('#FFF2E8')
                .borderRadius(12)
                .onClick(() => {
                  this.removeUser(user.id);
                })
            }
            Text(this.userRoleSummary(user.id))
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(this.selectedUserId === user.id ? '#EEF7F1' : '#FAFCFA')
          .borderRadius(CARD_RADIUS)
        }, (user: AdminUserItem) => user.id)
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private refreshUsers(): void {
    fetchAdminUsers().then((items: AdminUserItem[]) => {
      this.users = items;
      this.applyFilter();
    }).catch((error: Error) => {
      this.users = [];
      this.applyFilter();
      this.feedback = error.message.length > 0 ? error.message : '人员数据加载失败。';
    });
  }

  private refreshRoleData(): void {
    fetchAdminRoles().then((items: AdminRoleItem[]) => {
      this.roles = items;
      this.applyFilter();
    }).catch(() => {
      this.roles = [];
      this.applyFilter();
    });
    fetchAdminUserRoles().then((items: AdminUserRoleItem[]) => {
      this.userRoles = items;
      this.applyFilter();
    }).catch(() => {
      this.userRoles = [];
      this.applyFilter();
    });
  }

  private pickUser(user: AdminUserItem): void {
    this.selectedUserId = user.id;
    this.username = user.username;
    this.realName = user.realName;
    this.phone = user.phone;
    this.feedback = '';
  }

  private clearForm(): void {
    this.selectedUserId = '';
    this.username = '';
    this.realName = '';
    this.phone = '';
    this.newPassword = '123456';
    this.newRoleCode = 'USER';
    this.feedback = '';
  }

  private saveUser(): void {
    if (this.selectedUserId.length > 0) {
      updateAdminUser(this.selectedUserId, this.realName.trim(), this.phone.trim()).then((saved: boolean) => {
        this.feedback = saved ? '修改成功。' : '修改失败。';
        this.refreshUsers();
      }).catch((error: Error) => {
        this.feedback = error.message.length > 0 ? error.message : '修改失败。';
      });
      return;
    }
    if (this.username.trim().length === 0) {
      this.feedback = '请填写用户名。';
      return;
    }
    createAdminUser(
      this.username.trim(),
      this.realName.trim(),
      this.phone.trim(),
      this.newPassword.trim(),
      this.newRoleCode
    ).then((saved: boolean) => {
      this.feedback = saved ? '新增成功。' : '新增失败。';
      if (saved) {
        this.clearForm();
        this.feedback = '新增成功。';
        this.refreshUsers();
      }
    }).catch((error: Error) => {
      this.feedback = error.message.length > 0 ? error.message : '新增失败。';
    });
  }

  private removeUser(id: string): void {
    deleteAdminUser(id).then((deleted: boolean) => {
      this.feedback = deleted ? '删除成功。' : '删除失败。';
      if (deleted && this.selectedUserId === id) {
        this.clearForm();
      }
      this.refreshUsers();
      this.refreshRoleData();
    }).catch((error: Error) => {
      this.feedback = error.message.length > 0 ? error.message : '删除失败。';
    });
  }

  private selectedUserRoles(): AdminUserRoleItem[] {
    return this.userRoles.filter((binding: AdminUserRoleItem) => binding.userId === this.selectedUserId);
  }

  private isRoleAssigned(roleId: string): boolean {
    return this.selectedUserRoles().filter((binding: AdminUserRoleItem) => binding.roleId === roleId).length > 0;
  }

  private roleName(roleId: string): string {
    for (let index = 0; index < this.roles.length; index++) {
      if (this.roles[index].id === roleId) {
        return this.roleDisplayName(this.roles[index]);
      }
    }
    return `角色 #${roleId}`;
  }

  private roleDisplayName(role: AdminRoleItem): string {
    if (role.normalizedRoleCode === 'DOCTOR') {
      return '医生';
    }
    if (role.normalizedRoleCode === 'ADMIN') {
      return '管理员';
    }
    if (role.normalizedRoleCode === 'USER') {
      return '普通用户';
    }
    return role.roleName.length > 0 ? role.roleName : role.roleCode;
  }

  private displayRoles(): AdminRoleItem[] {
    const values: AdminRoleItem[] = [];
    for (let index = 0; index < this.roles.length; index++) {
      const role = this.roles[index];
      let existingIndex = -1;
      for (let valueIndex = 0; valueIndex < values.length; valueIndex++) {
        if (values[valueIndex].normalizedRoleCode === role.normalizedRoleCode) {
          existingIndex = valueIndex;
          break;
        }
      }
      if (existingIndex < 0) {
        values.push(role);
      } else if (role.normalizedRoleCode === 'DOCTOR' && role.roleCode === 'DOCTOR') {
        values[existingIndex] = role;
      }
    }
    return values;
  }

  private setFilter(filter: AdminPeopleFilter): void {
    this.currentFilter = filter;
    this.applyFilter();
  }

  private applyFilter(): void {
    this.visibleUsers = buildFilteredAdminUsers(this.users, this.roles, this.userRoles, this.currentFilter);
  }

  private userRoleSummary(userId: string): string {
    const names: string[] = [];
    for (let index = 0; index < this.userRoles.length; index++) {
      const binding = this.userRoles[index];
      if (binding.userId === userId) {
        names.push(this.roleName(binding.roleId));
      }
    }
    if (names.length === 0) {
      return '身份：普通用户';
    }
    return `身份：${names.join('、')}`;
  }

  private assignRole(roleId: string): void {
    if (this.selectedUserId.length === 0) {
      this.feedback = '请先选择人员。';
      return;
    }
    if (this.isRoleAssigned(roleId)) {
      this.feedback = '该角色已绑定。';
      return;
    }
    assignAdminUserRole(this.selectedUserId, roleId).then((saved: boolean) => {
      this.feedback = saved ? '角色绑定成功。' : '角色绑定失败。';
      this.refreshRoleData();
    }).catch((error: Error) => {
      this.feedback = error.message.length > 0 ? error.message : '角色绑定失败。';
    });
  }

  private removeRoleBinding(id: string): void {
    deleteAdminUserRole(id).then((deleted: boolean) => {
      this.feedback = deleted ? '角色移除成功。' : '角色移除失败。';
      this.refreshRoleData();
    }).catch((error: Error) => {
      this.feedback = error.message.length > 0 ? error.message : '角色移除失败。';
    });
  }
}
