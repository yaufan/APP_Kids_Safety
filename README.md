# 安全小隊

給 **3～6 歲**的小朋友，在台灣，國語為主：學安全。小朋友自己當戴安全帽的小隊員，跟著三位幫手（汪汪警察、喵喵消防員、兔兔護士）走過四個世界：過馬路、地震火災颱風、身體紅綠燈、家裡找危險。每一關都是「看一看、想一想、自己做做看」，最後有給爸爸媽媽的問題卡和「回真實生活做做看」。不嚇人：平靜、就事論事。

- 設計：[docs/design.md](docs/design.md)，草圖在 `docs/mockups/`，圖和程式的約定在 [docs/art.md](docs/art.md)。
- 和「畫畫小鎮」「字母寵物」「動物小餐廳」「小卡認天下」「想一想樂園」「眼尖尖大挑戰」「迷宮小冒險」「小小生活家」「小小音樂家」「心情小屋」「晚安小鎮」是兄弟 APP：同一個作者、同一套技術、不同畫風。
- 不連網、不定位、沒有廣告、沒有帳號、不要任何權限；爸媽的電話只存在手機裡，不存地址。

## 下載（Android）
- 最新版：[Releases](https://github.com/yaufan/APP_Kids_Safety/releases/latest)，一般手機下載 `safety-team-版本-arm64.apk`。
- 用手機掃描 [docs/download-qr.png](docs/download-qr.png)。

## 目前進度
- 0.1.0（測試版）：小隊員（選髮型、膚色、安全帽顏色）、三位幫手、四個世界共 14 關（馬路 5、救災 3、身體 2、家裡 4）、兩個難度、家長問題卡和回真實生活、安全帽徽章和隊徽、真實生活金徽章、休息時間、家長模式（電話和稱呼、安全大人、身體世界開關）、音樂音效、APP 圖示。漫畫網點風。版本紀錄在 [CHANGELOG.md](CHANGELOG.md)。

## 程式和素材在哪裡
- `app/`：Flutter 程式。`lib/core/` 是世界和關卡的名字（`content.dart`）、每一關的畫面和步驟（`levels.dart`，用 `scene.dart`、`steps.dart` 描述）、一關玩到哪裡（`run.dart`）、存檔和設定（`game.dart`）、聲音、語音；`lib/features/` 是基地、世界、關卡（`level/`）、安全帽、身體世界的說明、休息、家長模式。
- `design/art/`：用 Python 畫的圖（漫畫網點風，網點是真的小圓）。`python3 build.py all` 全部重畫，`fluttercheck` 用真的 flutter_svg 比對；`icon.py` 是 APP 圖示。
- `design/sounds/make_sounds.py`：合成全部的音樂和聲音。
- 測試：在 `app/` 裡 `flutter test`；完整流程 `flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`；示範影片 `flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true`，再 `python3 tools/demo_audio.py`。

## 授權
- 非商業使用授權：自己、家人使用，或學校、非營利團體的教學，都可以免費使用、修改、分享，要註明出處。
- 商業用途（販賣、收費、廣告、上架）要先取得作者書面同意。也不可以拿來訓練 AI。
- 細節見 [LICENSE](LICENSE)；別人做的部分（字型）見 [NOTICE.md](NOTICE.md)。
