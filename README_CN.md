[English](README.md) | 简体中文

<p align="center">
  <a href="https://github.com/LanceHuang245/Zephyr">
    <img src="./public/zephyr.png" height="200"/>
  </a>
</p>

> **临时通知**
> 
> 当前项目的后端处于开发阶段，概率性出现服务不可用状态，请谨慎使用。

# Zephyr

一款简洁美观的天气应用，基于 Flutter 开发，数据来源于 OpenMeteo API 与 QWeather API，搜索功能由 OpenStreetMap API 提供。
> **注意**
> 
> 本项目仅供学习交流使用，请勿用于商业用途。且每个API接口都有一定用量限制，请勿滥用。
---
## 功能特性
- 实时天气查询：支持多城市天气信息获取
- 城市管理：可添加、删除、设为默认
- 7天天气预报：未来一周天气趋势一目了然
- 天气预警：实时天气预警信息
- 多样天气图标与动态背景
- 主题设置：支持Monet取色
- 温度单位切换（℃/℉）
- 多语言本地化（l10n）(简体中文、繁体中文、英语、德语、西班牙语、法语、意大利语)

## 使用方法
1. 点击右上角搜索按钮，输入城市名进行搜索，选择城市后自动返回主界面并保存至城市列表，或使用定位功能自动获取您所在地的天气信息。
2. 在设置页面可管理已保存城市，支持设为默认和删除操作。
3. 可在设置中切换主题、语言和温度单位。

## 贡献
欢迎社区用户参与贡献！您可以自由 Fork 本仓库，提交 Pull Request，或通过 Issue 提出建议和报告 Bug。

### 翻译
1. 语言文件位于/lib/l10n目录下
2. 您需要复制一份`app_en.arb`后修改文件名称为您所想翻译的语言，例如`app_fr.arb`
3. 完善语言文件的翻译
4. (必须)在终端中在项目根目录中执行`flutter gen-l10n`，检查终端输出是否有未翻译的字段（若有则可查看`untranslated.json`，然后进行修改）
5. (必须)在lib/core/languages.dart中按照格式添加语言
6. 推送你的代码并提交 [Pull Request](https://github.com/ClaretWheel1481/Zephyr/pulls)

## 截图
<table>
  <tr>
    <td><img src="./public/sample_main_light.png" width="200"/></td>
    <td><img src="./public/sample_main2_light.png" width="200"/></td>
    <td><img src="./public/sample_main_alert_light.png" width="200"/></td>
    <td><img src="./public/sample_settings_light.png" width="200"/></td>
  </tr>
  <tr>
    <td><img src="./public/sample_main_dark.png" width="200"/></td>
    <td><img src="./public/sample_main2_dark.png" width="200"/></td>
    <td><img src="./public/sample_main_alert_dark.png" width="200"/></td>
    <td><img src="./public/sample_settings_dark.png" width="200"/></td>
  </tr>
</table>

更多详细请查看[图片文件夹](https://github.com/LanceHuang245/Zephyr/tree/master/public)

## 下载
[点击前往下载最新版本](https://github.com/LanceHuang245/Zephyr/releases/latest)

## 许可
[MIT License](LICENSE) © Huang LinXing