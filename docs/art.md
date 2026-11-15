# 圖和程式的約定（安全小隊）

全部的圖都是 `design/art/` 的 Python 畫的 SVG（漫畫網點風，見 `docs/design.md`「畫風」），APP 用 flutter_svg 畫出來。

## 怎麼做
- `python3 design/art/build.py all`：重畫全部，並檢查（不用 pattern／mask／filter／text／style，每個檔案 70 KB 以下）。
- `python3 design/art/build.py sheet OUT.png "hero,road/*"`：把一些檔案排成一張總覽圖看。
- `python3 design/art/build.py fluttercheck`：用真的 flutter_svg 畫每個檔案，和 Chromium 比對（在 /dev/shm 做一個臨時的 Flutter 專案，做完刪掉）。
- `python3 design/art/icon.py preview OUT.png`／`export`：APP 圖示。

## 網點、外框、亮光（`kit.py`）
- 每樣東西是一個 shapely 形狀，寫三次：平塗的顏色、陰影那邊的網點（真的小圓，一個形狀的點合成一個 `<path>`，用 `<clipPath>` 切在形狀裡）、深藍色 `#1E3A6E` 的細外框。
- 陰影區＝形狀減掉往左上移約 11 點的自己；點排成轉 30 度、間距 5.5 點的格子，半徑從 0 漸漸變大到 1.4 點；顏色是底色加深 45%。白色、很淺的顏色和皮膚不加網點。
- 「點」是手機畫面上的點：每張圖告訴 `Pic` 它平常在手機上多寬（`display=`），線寬和網點就照這個換算，大圖小圖看起來一樣粗。
- 檔案超過 68 KB 時，`Pic.save` 自動把網點間距加大再寫一次。
- 速度線（`fx/speed`）和爆炸框（`fx/burst`、`fx/burst_yellow`）是獨立的小圖，由 Flutter 控制出現和淡出；框裡的漫畫字由 Flutter 用粉圓字型畫。

## 資料夾
| 資料夾 | 內容 | 程式 |
|---|---|---|
| `hero/` | 小隊員的姿勢 `<姿勢>_h<髮型>.svg`（4 種髮型），`swim_h*` 是身體紅綠燈的泳衣圖 | `hero.py` |
| `helpers/` | 汪汪警察、喵喵消防員、兔兔護士（stand、salute，汪汪多 stop，喵喵多 phone） | `helpers.py` |
| `road/` | 馬路世界的背景和東西（紅綠燈的小綠人、車子、安全帶⋯⋯），也有媽媽、店員、路人 | `road.py`、`helpers.py` |
| `rescue/` | 救災世界（客廳、樓梯間、淡淡的灰煙、颱風的窗戶⋯⋯） | `rescue.py` |
| `body/` | 身體世界（泳池邊、公園、圓點、紅綠燈卡、熊阿姨這些動物朋友） | `body.py`、`helpers.py` |
| `home/` | 家裡世界的四個房間，危險的東西和弄安全的樣子 | `home.py` |
| `badges/` | 每關的徽章、每個世界的隊徽、金徽章 | `badges.py` |
| `ui/`、`fx/` | 世界的路牌、箭頭、安全大人的臉、基地、安全帽、爆炸框、速度線 | `ui.py` |

## 小隊員的顏色
`hero/*.svg` 用替代色畫：安全帽 `#FEC401`（網點 `#FEC402`）、皮膚 `#F6D3B1`。APP（`lib/app/hero_art.dart`）讀進來以後換成小朋友選的安全帽顏色和膚色；髮型是不同的檔案。

## 場景怎麼擺
- 背景都是 400 × 300（4:3），APP 的畫面框也是 4:3。
- 東西的位置寫在 `app/lib/core/levels.dart`：中心 x、y 和寬高 w、h，都是畫面框的比例（0～1）。圖用 contain 放進那個框。
- `@hero/<姿勢>` 是小隊員；沒有圖的東西（`Look(null, …)`）是可以拖進去或點的地方。
- `test/art_test.dart` 檢查程式要的每一張圖都存在。
