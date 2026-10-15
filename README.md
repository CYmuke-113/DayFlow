# DayFlow

DayFlow 是一个使用 Flutter 开发的轻量日程与待办应用，用于记录每日安排和追踪任务完成情况。数据保存在本地，无需登录。

## 当前功能

- **日程管理**：选择日期和时间、填写标题，添加日程；新增后按开始时间排序，支持删除。
- **待办管理**：添加待办、勾选完成或恢复未完成状态，支持删除。
- **本地保存**：日程、待办及完成状态通过 `shared_preferences` 保存，重新打开应用后恢复。
- **双页切换**：通过底部导航在日程和待办之间切换。

首次打开且没有本地记录时，会显示内置示例数据。目前尚未实现内容编辑、通知提醒和云端同步。

## 技术栈

- Flutter / Dart
- Material 组件
- `shared_preferences`：使用 `SharedPreferencesAsync` 存储 JSON 数据

## 本地运行

### 环境准备

- 安装 Flutter，并确保其内置 Dart 版本满足 `pubspec.yaml` 中的约束：`^3.12.2`。
- Android 开发需要配置 Android SDK，并准备 Android 模拟器或开启 USB 调试的真机。
- 可使用 Android Studio 或 VS Code 进行开发。

在项目根目录执行：

```sh
flutter doctor
flutter pub get
flutter devices
flutter run -d <设备ID>
```

将 `<设备ID>` 替换为 `flutter devices` 列出的实际 ID。例如，模拟器 ID 为 `emulator-5554` 时：

```sh
flutter run -d emulator-5554
```

使用 Android Studio 时，打开项目根目录，选择 Android 设备，并运行 `lib/main.dart`。

仓库包含 Android、iOS 和 Web 工程目录，未包含 Windows 桌面工程。iOS 构建需要 macOS 和 Xcode；各平台实际兼容性以运行验证为准。

## 构建 Android APK

生成用于本地调试的 APK：

```sh
flutter build apk --debug
```

输出位置：`build/app/outputs/flutter-apk/app-debug.apk`。

当前 Android 应用 ID 和命名空间均为 `com.example.dayflow`，桌面显示名称为 `DayFlow`。更换应用 ID 后，Android 会视其为新应用，旧应用的本地数据不会自动迁移。

当前 release 配置仍使用调试签名，正式发布前需要配置自己的发布签名。

## 项目结构

```text
lib/
├── main.dart            # 应用入口、页面交互与本地读写
├── schedule_event.dart  # 日程模型与 JSON 转换
└── todo.dart            # 待办模型与 JSON 转换
android/                # Android 平台配置
ios/                    # iOS 平台配置
web/                    # Web 平台配置
test/                   # 测试目录
pubspec.yaml            # 项目信息与依赖
```

## 开发检查

静态分析：

```sh
flutter analyze
```

`test/widget_test.dart` 目前仍是默认计数器示例测试，尚未适配日程和待办页面，不能作为当前功能的有效验证。后续可补充新增、删除、完成状态切换和本地数据恢复的测试。
