# VOID — Neural Interface｜OpenMontage 單金鑰（OpenAI）實作手冊

本文件描述如何在 **OpenMontage** 內複刻「一支產品廣告：4 張 gpt-image-1 圖、OpenAI TTS 旁白、免版稅音樂、WhisperX 字級對齊字幕、Remotion 資料視覺化」之**可執行工具鏈**（對齊 repo 既有工具，而非外部單次腳本硬呼叫 API）。

---

## 0. 交付鎖定：**60 秒** · **16:9（1920×1080）**

| 欄位 | 鎖定值 | 說明 |
|------|--------|------|
| 總時長 | **60 s** | 旁白 + 畫面 timeline 以 60 s 設計；`edit_decisions`／`scene_plan` 最後一個 cut 的 `out_seconds` 建議約 **59.0**，以便 Remotion `calculateMetadata` 加上 1 s padding 後仍落在 **≈60 s**（見 `remotion-composer/src/Root.tsx` 內 `Explainer` 的 `(lastEnd + 1) * 30`）。 |
| 畫幅 | **16:9** | **1920×1080**、**30 fps**；與 `Root.tsx` 中 **`Explainer`** composition 預設一致（`width={1920}` `height={1080}` `fps={30}`）。 |
| 合成 | `video_compose` | `render_runtime=remotion`，composition **`Explainer`**（非 `TalkingHead` 直式）。 |
| 圖像比例 | 橫幅 | `openai_image` 可選 **`1536x1024`** 或 **`1024x1024`**（16:9 構圖請在 prompt 要求 letterbox-safe center）。 |
| 旁白字數（英文） | 約 **130–170 詞** | 以中等語速 TTS 對齊 ~60 s（實際依 voice 微調）；script stage 必註明 **hard cap 60 s**。 |

**一鍵給 Agent 的指令（含本節）：** 見文末 **§8**。

---

## 1. 建議 Pipeline

| 項目 | 選擇 |
|------|------|
| Pipeline | `animated-explainer`（`pipeline_defs/animated-explainer.yaml`） |
| 視覺 runtime | `render_runtime=remotion`（`video_compose` → Remotion `Explainer`） |
| 圖像 | `openai_image`，`model=gpt-image-1` |
| 旁白 | `openai_tts`（經 `tts_selector`，`preferred_provider=openai`） |
| 字級轉寫 | `transcriber`（內建 **faster-whisper**；**WhisperX** 用於 `align`／選用 `diarize`） |
| 字幕檔 | `subtitle_gen`（吃 transcriber 的 word segments → SRT／VTT／caption JSON） |
| 成片合成 | `video_compose`（`remotion_render` 或 `compose` + `audio_mixer`） |

執行時請遵守 `AGENT_GUIDE.md` **Rule Zero**：讀 manifest → 各 stage 的 director skill → preflight `provider_menu_summary()`。

---

## 2. 環境變數（金鑰策略）

### 模式 A — 「只要 OpenAI 一張帳單」（嚴格單金鑰）

- **必填：** `OPENAI_API_KEY`
- **音樂：** OpenMontage **沒有**「僅用 OpenAI 下載免版稅音樂」的專用工具；若堅持不加第二把金鑰，請改為：
  - **無音樂**；或
  - **Remotion 內建節奏／環境音感**（僅視覺與旁白，無第三方 bed）；或
  - 後期在本機以 **CC0** 檔案手動置入（不屬「零手動素材」）。

### 模式 B — 「OpenAI 付費 + 音樂 $0」（與常見 VOID 案例一致）

- **必填：** `OPENAI_API_KEY`
- **選填（免費 API）：** `PIXABAY_API_KEY` 或改用 `pixabay_music`／`freesound_music` 等 **registry 內免費額度**工具（仍無訂閱費，但多一把免費 key）。

以下工具鏈以 **模式 B** 撰寫；若你走模式 A，刪除音樂 stage 即可。

### 本機依賴（不計入「API 金鑰」）

- **WhisperX 字級對齊：** `pip install whisperx`（`transcriber` 會在可用時走 align；見 `tools/analysis/transcriber.py`）。
- **faster-whisper：** `pip install faster-whisper` 或 `faster-whisper[gpu]`。

---

## 3. 資產規格（VOID 產品廣告）

| 資產 | 工具 | 建議參數／備註 |
|------|------|----------------|
| 圖 1–4 | `openai_image` | `model=gpt-image-1`，`n=1` 每 prompt 一次；`size` 建議 `1536x1024` 或 `1024x1024`（與 Remotion 1080p 構圖一致即可） |
| 旁白 WAV/MP3 | `openai_tts` | 經 `tts_selector`，鎖 `preferred_provider=openai`；輸出對齊 script 分段 |
| 音樂（模式 B） | `pixabay_music` | 關鍵字：`corporate ambient sci-fi minimal` 等；下載後由 `audio_mixer` ducking |
| 字級轉寫 | `transcriber` | `input_path` = 旁白音檔；`output_dir` 寫入 `projects/void-neural-interface/assets/audio/`；啟用 WhisperX 時確保已安裝 `whisperx` |
| 字幕 | `subtitle_gen` | `format`: `srt` 或 `json`；`highlight_style`: `word_by_word` 或 `karaoke` 若 brief 要卡拉 OK 感 |
| Remotion 圖表 | scene_plan | 使用 `bar_chart`／`line_chart`／`stat_card`／`kpi_grid` 等（見 `remotion-composer/SCENE_TYPES.md`） |

**專案目錄（建議）：** `projects/void-neural-interface/`（gitignore，可隨時刪除重跑）

```
projects/void-neural-interface/
├── assets/images/void_01.png … void_04.png
├── assets/audio/narration.mp3
├── assets/audio/transcript_words.json
├── assets/subtitles/captions.srt
├── assets/music/bed.mp3
└── renders/final.mp4
```

---

## 4. Agent 執行順序（濃縮）

1. **Preflight** — `provider_menu_summary()`；鎖定 `openai_image`、`openai_tts` 為 **AVAILABLE**；確認 `video_compose` 的 `render_engines.remotion`。
2. **Research / Proposal** — 產品：虛構「VOID — Neural Interface」；概念含 3 組差異化 angle、成本表含 **gpt-image-1 ×4 + TTS 字數 +（選）pixabay_music**。
3. **Script** — **固定 60 s 旁白**（見 §0 字數）；標註 `enhancement_cues` 對應 4 張圖與 2–3 個圖表 beat。
4. **Scene plan** — 每 cut 指定 `type`（`hero_title` / `stat_card` / `bar_chart` 等）與 `required_assets` 路徑。
5. **Assets**
   - `image_selector` 或 **`openai_image` 直接**（若 selector 支援 `preferred_provider=openai`）：四張圖。
   - `tts_selector` → `openai_tts`：整段或分段旁白。
   - （模式 B）`pixabay_music`：一條 bed。
6. **Edit** — `edit_decisions`：字幕來源指向 `subtitle_gen` 輸出；ducking 參數。
7. **Transcribe（可與 assets 並行或緊接旁白後）** — `transcriber` 對旁白音檔 → 產 word-level JSON。
8. **subtitle_gen** — 轉 SRT 或 Remotion caption JSON。
9. **Compose** — `video_compose`，`render_runtime=remotion`，`subtitle_path`／`narration_transcript_path` 依 `video_compose` schema；必要時 `remotion_caption_burn`（見工具說明）。
10. **Publish** — 輸出 hero mp4 + 縮圖概念。

---

## 5. 成本備註（約 $0.69 的量級）

實際金額依 **OpenAI 當前定價**、圖片 `quality`、TTS 字數、是否走 `gpt-image-1` 多張而變。請在 **proposal** 階段用 `cost_tracker`／各 tool `estimate_cost()` 寫入 `proposal_packet.cost_estimate`，不要手寫固定數字。

---

## 6. 與「零手動素材」的對齊

- **圖／聲／字幕／圖表**：皆可由上述工具自動產出。  
- **音樂（模式 B）**：仍須 **搜尋／挑選** 一筆免費曲（或寫死 query + 取第一筆以完全自動化，但品質風險自負）。

---

## 7. 相關原始碼索引

| 能力 | 檔案 |
|------|------|
| gpt-image-1 | `tools/graphics/openai_image.py` |
| OpenAI TTS | `tools/audio/openai_tts.py` |
| WhisperX / faster-whisper | `tools/analysis/transcriber.py` |
| 字幕 | `tools/subtitle/subtitle_gen.py` |
| Remotion 場景表 | `remotion-composer/SCENE_TYPES.md` |
| 合成與字幕燒錄 | `tools/video/video_compose.py` |

---

## 8. 下一步（給操作者）

在 Cursor／Agent **新對話**中整段貼上（會驅動完整 pipeline 與 **60 s / 16:9**）：

> 依 `docs/VOID-NEURAL-INTERFACE-RUNBOOK.md`（**§0：60 秒、1920×1080、30fps、Remotion `Explainer`**）執行 **animated-explainer**。產品：**VOID — Neural Interface**。圖像：**openai_image**、`model=gpt-image-1`、共 4 張。旁白：**tts_selector**、`preferred_provider=openai`。音樂：**模式 B** 時用 **pixabay_music**（需免費 `PIXABAY_API_KEY`）；**模式 A** 則無 bed。字幕：**transcriber**（WhisperX 字級）→ **subtitle_gen**。成片：**video_compose**、`render_runtime=remotion`。專案目錄：`projects/void-neural-interface/`。先 **preflight** `provider_menu_summary()`，並遵守 `AGENT_GUIDE.md` Rule Zero 與各 stage director。

Agent 即應按 `AGENT_GUIDE.md` 走 pipeline 與 checkpoint，而非跳過 director skills。

**說明：** 此環境無法替你代跑付費 API 與本機 Remotion render；貼上後須由 **你本機已設定 `OPENAI_API_KEY`（及選用 Pixabay key）** 的 Agent 實際執行到 `compose` 才有 `final.mp4`。
