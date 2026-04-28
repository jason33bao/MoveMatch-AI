/**
 * Minimal Node.js backend for MoveMatch AI video analysis.
 * This file intentionally focuses only on the new AI analysis feature
 * and leaves the rest of the app architecture untouched.
 */
require("dotenv").config();

const cors = require("cors");
const express = require("express");
const fs = require("fs");
const fsp = require("fs/promises");
const os = require("os");
const path = require("path");
const { execFile } = require("child_process");
const { promisify } = require("util");
const multer = require("multer");

const execFileAsync = promisify(execFile);
const app = express();

const MIN_VIDEO_SEC = 10;
const MAX_VIDEO_SEC = 120; // 2 minutes

let ffmpegStaticBin = null;
let ffprobeStaticBin = null;
try {
  ffmpegStaticBin = require("ffmpeg-static");
} catch {
  /* optional: rely on system ffmpeg */
}
try {
  const ff = require("ffprobe-static");
  ffprobeStaticBin = typeof ff === "string" ? ff : ff?.path;
} catch {
  /* optional */
}

function getFfmpegPath() {
  if (process.env.FFMPEG_PATH && String(process.env.FFMPEG_PATH).trim()) {
    return String(process.env.FFMPEG_PATH).trim();
  }
  if (ffmpegStaticBin && typeof ffmpegStaticBin === "string") {
    return ffmpegStaticBin;
  }
  return "ffmpeg";
}

function getFfprobePath() {
  if (process.env.FFPROBE_PATH && String(process.env.FFPROBE_PATH).trim()) {
    return String(process.env.FFPROBE_PATH).trim();
  }
  if (ffprobeStaticBin && typeof ffprobeStaticBin === "string") {
    return ffprobeStaticBin;
  }
  return "ffprobe";
}

/**
 * Returns positive duration in seconds, or null if unknown.
 */
async function getVideoDurationSeconds(videoPath) {
  const probe = getFfprobePath();
  try {
    const { stdout } = await execFileAsync(
      probe,
      [
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        videoPath
      ],
      { maxBuffer: 4 * 1024 * 1024, encoding: "utf8" }
    );
    const s = parseFloat(String(stdout).trim().replace(",", "."));
    if (Number.isFinite(s) && s > 0) {
      return s;
    }
  } catch {
    /* fall through to ffmpeg -i */
  }

  const ffmpeg = getFfmpegPath();
  try {
    await execFileAsync(ffmpeg, ["-hide_banner", "-i", videoPath], {
      maxBuffer: 4 * 1024 * 1024,
      encoding: "utf8"
    });
  } catch (err) {
    const text = String((err && (err.stderr || err.stdout)) || err?.message || "");
    const m = text.match(/Duration:\s*(\d+):(\d+):(\d+\.?\d*)/);
    if (m) {
      const h = parseInt(m[1], 10);
      const min = parseInt(m[2], 10);
      const sec = parseFloat(m[3]);
      const total = h * 3600 + min * 60 + sec;
      if (Number.isFinite(total) && total > 0) {
        return total;
      }
    }
  }
  return null;
}

const PORT = Number(process.env.PORT || 3000);
const AI_MODEL = process.env.AI_MODEL || "glm-4.6v";
const AI_FALLBACK_MODEL = process.env.AI_FALLBACK_MODEL || "";
const ALLOW_CLIENT_MODEL_OVERRIDE = String(process.env.ALLOW_CLIENT_MODEL_OVERRIDE || "").toLowerCase() === "true";
const AI_API_KEY = process.env.AI_API_KEY || "";
const AI_BASE_URL = (process.env.AI_BASE_URL || "https://open.bigmodel.cn/api/paas/v4").replace(/\/$/, "");
const DEFAULT_ALLOWED_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:5173",
  "https://movematch-ai-1.onrender.com"
];
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || DEFAULT_ALLOWED_ORIGINS.join(","))
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);

/** Fixed NTRP-style bands (source of truth for level + ntrpEquivalent in API responses). */
const TENNIS_SCORE_BANDS = [
  { min: 0, max: 20, level: "Complete Beginner", ntrpEquivalent: "NTRP 1.0–1.5" },
  { min: 21, max: 35, level: "Beginner", ntrpEquivalent: "NTRP 2.0" },
  { min: 36, max: 50, level: "Developing Amateur", ntrpEquivalent: "NTRP 2.5" },
  { min: 51, max: 65, level: "Intermediate Recreational", ntrpEquivalent: "NTRP 3.0" },
  { min: 66, max: 75, level: "Strong Club Player", ntrpEquivalent: "NTRP 3.5" },
  { min: 76, max: 84, level: "Advanced Club Player", ntrpEquivalent: "NTRP 4.0" },
  { min: 85, max: 91, level: "Competitive Advanced", ntrpEquivalent: "NTRP 4.5–5.0" },
  { min: 92, max: 96, level: "Elite", ntrpEquivalent: "NTRP 5.5–6.0" },
  { min: 97, max: 100, level: "Professional", ntrpEquivalent: "NTRP 6.5–7.0" }
];

function tennisLevelFromScore(score) {
  const s = Math.max(0, Math.min(100, Math.round(Number(score) || 0)));
  for (const b of TENNIS_SCORE_BANDS) {
    if (s >= b.min && s <= b.max) {
      return { level: b.level, ntrpEquivalent: b.ntrpEquivalent };
    }
  }
  const b0 = TENNIS_SCORE_BANDS[0];
  return { level: b0.level, ntrpEquivalent: b0.ntrpEquivalent };
}

function findTennisBandIndex(score) {
  const s = Math.max(0, Math.min(100, Math.round(Number(score) || 0)));
  for (let i = 0; i < TENNIS_SCORE_BANDS.length; i += 1) {
    const b = TENNIS_SCORE_BANDS[i];
    if (s >= b.min && s <= b.max) {
      return i;
    }
  }
  return 0;
}

/** Move the score to at most the top of the previous band (one NTRP band down). */
function stepDownTennisOneBand(score) {
  const s = Math.max(0, Math.min(100, Math.round(Number(score) || 0)));
  const i = findTennisBandIndex(s);
  if (i === 0) {
    return Math.min(s, TENNIS_SCORE_BANDS[0].max);
  }
  return Math.min(s, TENNIS_SCORE_BANDS[i - 1].max);
}

function shouldApplyTennisUncertaintyPenalty(frameCount, note) {
  if (frameCount < 2) {
    return true;
  }
  const n = (note || "").toLowerCase();
  if (
    n.includes("no video frames were extracted") ||
    n.includes("no preview frames") ||
    n.includes("not extract") ||
    n.includes("could not read") ||
    n.includes("limited") ||
    n.includes("ffprobe")
  ) {
    return true;
  }
  return false;
}

/**
 * True only when at least one decoded frame was produced. Do not infer from
 * the optional "note" string alone (older logic mistook empty note as success).
 */
function hasUsableVideoFrames(frameCount) {
  return frameCount >= 1;
}

function buildTennisNoVideoFramesResponse(note) {
  const extra = (note && String(note).trim()) ? ` (${String(note).trim()})` : "";
  return {
    score: 0,
    level: "Rating unavailable (no frames)",
    ntrpEquivalent: "N/A",
    confidence: "low",
    summary:
      "The server could not extract any still images from this video, so a tennis skill or NTRP-style rating is not available. " +
      "This is usually a codec or ffmpeg issue, not a reflection of the player's true level. " +
      "Re-export as H.264 MP4 and re-upload, or check that ffmpeg is installed." +
      extra,
    strengths: [
      "Your upload was received. After frames decode successfully, the AI can rate visible technique."
    ],
    weaknesses: [
      "Video frame extraction failed — no decoded frames, so there is no visual evidence to score."
    ],
    trainingPlan: [
      "In Photos: export or share a copy encoded as H.264/AAC; avoid sending only a reference to iCloud-optimized HEVC if your server cannot decode it.",
      "Re-upload a 5–40s clip with a clear side or diagonal view and the full body in frame.",
      "On the server host, run: ffmpeg -version (and install ffmpeg if missing)."
    ],
    issues: [
      "Video frame extraction failed — no decoded stills from this file; rating cannot be based on NTRP evidence."
    ],
    suggestions: [
      "Re-export the clip with H.264 (MP4) and upload again for reliable analysis.",
      "Use a 5–40s side-view segment with the athlete fully visible in frame.",
      "Ensure the Node backend can run `ffmpeg` on the machine where the server runs."
    ],
    training_plan: [
      "Re-export the clip with H.264 (MP4) and upload again for reliable analysis.",
      "Use a 5–40s side-view segment with the athlete fully visible in frame.",
      "Ensure the Node backend can run `ffmpeg` on the machine where the server runs."
    ],
    shotPlacements: [],
    depth_control_line:
      "No valid video frames; cannot build a shot heatmap. Fix decoding, then re-analyze."
  };
}

function buildGenericNoVideoFramesResponse(sport, note) {
  const extra = (note && String(note).trim()) ? ` (${String(note).trim()})` : "";
  return {
    score: 0,
    level: "Unknown",
    summary:
      "No video frames were extracted, so no technical analysis of movement is possible. Re-export the video as H.264/MP4 and try again." +
      extra,
    strengths: [
      "Your upload was received. After frames are extracted, the AI can score visible technique."
    ],
    issues: [
      "Video frame extraction failed — no decoded stills, so the model had no images to review."
    ],
    suggestions: [
      "Re-export the clip with H.264 (MP4) and upload again.",
      "Use a 5–40s side-view with the full body visible and stable camera.",
      "Install or verify `ffmpeg` on the server: ffmpeg -version."
    ],
    training_plan: [
      "Re-export the clip with H.264 (MP4) and upload again.",
      "Use a 5–40s side-view with the full body visible and stable camera.",
      "Install or verify `ffmpeg` on the server: ffmpeg -version."
    ]
  };
}

function stripJsonMarkdownWrapper(text) {
  if (!text || typeof text !== "string") {
    return "";
  }
  let t = text.trim();
  t = t.replace(/^\s*```(?:json)?\s*/i, "");
  t = t.replace(/\s*```\s*$/g, "");
  t = t.trim();
  if (t.startsWith("{") && t.endsWith("}")) {
    return t;
  }
  const i = t.indexOf("{");
  const j = t.lastIndexOf("}");
  if (i !== -1 && j > i) {
    return t.slice(i, j + 1);
  }
  return t;
}

/** Extract a top-level JSON object (best-effort) when extra prose wraps the object. */
function extractBalancedJsonObject(text) {
  const t = (text || "").trim();
  const start = t.indexOf("{");
  if (start === -1) {
    return t;
  }
  let depth = 0;
  for (let i = start; i < t.length; i += 1) {
    const c = t[i];
    if (c === "{") {
      depth += 1;
    } else if (c === "}") {
      depth -= 1;
      if (depth === 0) {
        return t.slice(start, i + 1);
      }
    }
  }
  return t.slice(start);
}

function parseModelJsonString(rawText) {
  const step1 = stripJsonMarkdownWrapper(rawText);
  try {
    return JSON.parse(step1);
  } catch {
    /* fall through */
  }
  const step2 = extractBalancedJsonObject(step1);
  return JSON.parse(step2);
}

const tennisRatingSystemPrompt = (frameCount, fallbackReason) => `
You are a strict tennis (NTRP/USTA-style) movement and technique rater for the MoveMatch AI app.

## Workflow (mandatory)
1) First, evaluate ONLY observable, video-supported behaviors: footwork, balance, unit turn, spacing, contact point, swing path, follow-through, recovery, rally tolerance if visible, serve/return if visible, pace/spin evidence if clear.
2) Map those observations to the NTRP **behavior anchors** below (verbally, in your head).
3) Then choose a single integer "score" from 0 to 100 that matches the anchors. Do not invent a score before behaviors.

## Fixed score → level + NTRP (the app will also derive labels from "score" for stability)
- 0–20: Complete Beginner / NTRP 1.0–1.5
- 21–35: Beginner / NTRP 2.0
- 36–50: Developing Amateur / NTRP 2.5
- 51–65: Intermediate Recreational / NTRP 3.0
- 66–75: Strong Club Player / NTRP 3.5
- 76–84: Advanced Club Player / NTRP 4.0
- 85–91: Competitive Advanced / NTRP 4.5–5.0
- 92–96: Elite / NTRP 5.5–6.0
- 97–100: Professional / NTRP 6.5–7.0

## NTRP behavior anchors
- 1.0–2.0: Can make contact but lacks consistency, incomplete swing, poor recovery, little control.
- 2.5: Can rally slowly for a few shots, basic swing path, limited footwork, inconsistent contact.
- 3.0: Can sustain simple rallies, better preparation, basic directional control, but struggles under pace.
- 3.5: More consistent rallies, improved movement, can generate moderate pace/spin, still inconsistent under pressure.
- 4.0: Reliable technique, complete follow-through, good recovery, can control depth/direction and handle moderate pace.
- 4.5–5.0: Strong timing, advanced footwork, effective spin/pace, tactical shot selection, consistent under pressure.
- 5.5–6.0: Tournament-level player, high shot quality, excellent movement, strong serve/return, repeatable advanced mechanics.
- 6.5–7.0: Professional or semi-professional level. Assign ONLY if the video **clearly** shows elite movement, timing, pace, spin, and match-level consistency **across multiple clear frames**. Otherwise cap the score at 96 or lower.

## Uncertainty (mandatory to apply in your choice of "score" and "confidence")
- If the video is short, blurry, has too few frames, only a front view, missing lower body/feet, or ball contact is unclear: choose a LOWER "score" as if you had dropped by **one full band** in the table above, and set "confidence" to "low" or "medium" (not "high").
- If evidence is insufficient, never place the score in the top two bands (85–100) unless the quality is unambiguous.
- For any 6.5+ / NTRP 6.5+ equivalent, require multiple clear frames and obvious professional or semi-professional quality.
- The "summary" must explicitly state limitations (e.g. few frames, angle, no feet visible) when confidence is not "high".

## Shot placement heatmap (for the in-app top-down court view)
- Add "shotPlacements": an array of up to 16 objects, each: { "x": number 0-1, "y": number 0-1, "player": 1 or 2 }.
- Coordinates are for a full tennis court as seen from above: x=0 left sideline, x=1 right sideline, y=0 top/far baseline, y=1 bottom/near baseline (closer to typical camera). Place each point where the ball bounces or lands for that rally shot you can infer from the frames.
- player=1: the primary uploader / main subject in frame when two players exist; or the player whose stroke is shown if single-player drill. player=2: the opponent. If you cannot tell sides, use player=1 for any visible return.
- If you cannot see the ball or court well, return an empty array (do not guess random dots).

## Output
Return ONLY a single JSON object. No markdown, no code fences, no text before or after. Keys and types:
{
  "score": <integer 0-100>,
  "level": "<string — short label that matches the band for your score; server may normalize>",
  "ntrpEquivalent": "<string, e.g. NTRP 3.0>",
  "confidence": "low" | "medium" | "high",
  "summary": "<1-2 short sentences, plain language>",
  "strengths": <array of short strings, max 4>,
  "weaknesses": <array of short strings, max 4>,
  "trainingPlan": <array of 3-4 short drill strings>,
  "shotPlacements": [ { "x": 0-1, "y": 0-1, "player": 1 or 2 } ],
  "depthControlLine": "<one short line about depth/positioning, or empty string if unknown>"
}

Context for this request:
- Extracted frame count: ${frameCount}
- Frame note: ${fallbackReason || "Frames extracted successfully from the uploaded video."}
`;

const promptForNonTennis = (sport, frameCount, fallbackReason) => `
You are an elite ${sport} movement analyst for the MoveMatch AI mobile app.

The user uploaded a ${sport} training video. Analyze the athlete's visible technique and return a professional,
practical, execution-focused evaluation. The goal is an MVP coaching result for an app user reviewing their own video.

You must return ONLY valid JSON. Do not wrap the output in markdown. Do not add explanation before or after the JSON.

Important rules:
- Base your analysis only on visible evidence from the supplied frames and metadata.
- If the frames are limited, stay conservative and explicitly keep advice practical rather than pretending precision.
- Focus on overall level, movement quality, preparation, timing, balance, recovery, contact mechanics, and footwork.
- Be specific and actionable. Avoid vague praise.
- Write for an everyday athlete, not a coach or biomechanics expert.
- Keep "summary" to 1-2 short sentences in plain language.
- Keep "strengths", "issues", and "suggestions" as short user-facing bullet strings.
- Return "training_plan" as 3 short strings only. Do not return nested objects.
- Do not reveal your reasoning process, internal analysis steps, or chain-of-thought.
- The JSON must match the schema exactly.

Context:
- Sport: ${sport}
- Extracted frames available: ${frameCount}
- Frame extraction note: ${fallbackReason || "Frames extracted successfully from the uploaded video."}

Return this exact JSON shape:
{
  "score": 0,
  "level": "",
  "summary": "",
  "strengths": [],
  "issues": [],
  "suggestions": [],
  "training_plan": []
}
`;

app.use(
  cors({
    origin: ALLOWED_ORIGINS.includes("*") ? true : ALLOWED_ORIGINS
  })
);

app.use(express.json());

const uploadDirectory = path.join(os.tmpdir(), "movematch-ai-uploads");
fs.mkdirSync(uploadDirectory, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDirectory),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || "").toLowerCase();
    const safeExt = ext === ".mp4" || ext === ".mov" ? ext : pickVideoExtFromUpload(file);
    const base = `upload-${Date.now()}-${process.pid}${Math.random().toString(16).slice(2, 8)}${safeExt}`;
    cb(null, base);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 250 * 1024 * 1024
  },
  fileFilter: (_req, file, callback) => {
    const ext = path.extname(file.originalname || "").toLowerCase();
    const allowedMime = ["video/mp4", "video/quicktime", "application/octet-stream", "video/x-m4v", "video/m4v"];
    const allowedExt = [".mp4", ".mov", ".m4v"];

    if (allowedMime.includes(file.mimetype) || allowedExt.includes(ext)) {
      callback(null, true);
      return;
    }

    callback(new Error("Only .mp4 and .mov videos are supported."));
  }
});

function pickVideoExtFromUpload(file) {
  const fromName = path.extname(file.originalname || "").toLowerCase();
  if (fromName === ".mp4" || fromName === ".mov" || fromName === ".m4v") {
    return fromName;
  }
  const m = (file.mimetype || "").toLowerCase();
  if (m.includes("mp4") || m.includes("m4v")) {
    return ".mp4";
  }
  if (m.includes("quicktime") || m.includes("mov")) {
    return ".mov";
  }
  return ".mp4";
}

/**
 * multer "memory" and older configs saved files without an extension, which breaks
 * ffmpeg format probing. Ensure we always have a .mov / .mp4 / .m4v suffix.
 */
async function materializeVideoPathForFfmpeg(file) {
  const p = file.path;
  if (!p) {
    return p;
  }
  const pl = p.toLowerCase();
  if (pl.endsWith(".mp4") || pl.endsWith(".mov") || pl.endsWith(".m4v")) {
    return p;
  }
  const ext = pickVideoExtFromUpload(file);
  const withExt = p + ext;
  await fsp.copyFile(p, withExt);
  return withExt;
}

app.get("/", (_req, res) => {
  res.send("MoveMatch AI backend is running");
});

app.get("/health", async (_req, res) => {
  const ff = getFfmpegPath();
  const fp = getFfprobePath();
  let ffmpegOk = false;
  let ffprobeOk = false;
  try {
    await execFileAsync(ff, ["-version"], { maxBuffer: 1 * 1024 * 1024, encoding: "utf8" });
    ffmpegOk = true;
  } catch {
    ffmpegOk = false;
  }
  try {
    await execFileAsync(fp, ["-version"], { maxBuffer: 1 * 1024 * 1024, encoding: "utf8" });
    ffprobeOk = true;
  } catch {
    ffprobeOk = false;
  }
  res.json({
    status: "ok",
    service: "MoveMatch AI backend",
    provider: "compatible-vlm",
    model: AI_MODEL,
    ffmpeg: ffmpegOk ? path.basename(ff) : "not found",
    ffprobe: ffprobeOk ? path.basename(fp) : "not found",
    minVideoSec: MIN_VIDEO_SEC,
    maxVideoSec: MAX_VIDEO_SEC
  });
});

app.get("/debug/model-access", async (_req, res) => {
  if (!AI_API_KEY) {
    return res.status(500).json({
      status: "error",
      model: AI_MODEL,
      message: "AI_API_KEY is missing on the backend."
    });
  }

  try {
    const response = await fetch(`${AI_BASE_URL}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${AI_API_KEY}`
      },
      body: JSON.stringify({
        model: AI_MODEL,
        messages: [
          {
            role: "user",
            content: "Reply with exactly OK."
          }
        ],
        temperature: 0
      })
    });

    const rawText = await response.text();
    const payload = tryParseJson(rawText);

    if (!response.ok) {
      return res.status(response.status).json({
        status: "error",
        model: AI_MODEL,
        httpStatus: response.status,
        message: extractCompatibleApiError(response.status, payload, rawText)
      });
    }

    const replyText = payload?.choices?.[0]?.message?.content;
    return res.json({
      status: "ok",
      model: AI_MODEL,
      upstreamStatus: response.status,
      replyPreview: typeof replyText === "string" ? replyText.slice(0, 120) : ""
    });
  } catch (error) {
    return res.status(500).json({
      status: "error",
      model: AI_MODEL,
      message: error?.message || "Unknown error while probing model access."
    });
  }
});

async function handleAnalyzeVideo(req, res) {
  const tempPathsToDelete = [];

  try {
    if (!req.file) {
      return res.status(400).json({
        error: true,
        message: "No video file was uploaded."
      });
    }

    if (!AI_API_KEY) {
      return res.status(500).json({
        error: true,
        message: "AI_API_KEY is missing on the backend."
      });
    }

    tempPathsToDelete.push(req.file.path);

    const sport = (req.body?.sport ?? req.query?.sport ?? "Tennis").toString().trim() || "Tennis";
    const requestedModel = typeof req.body?.model === "string" ? req.body.model.trim() : "";
    // Keep production predictable: by default use Render env AI_MODEL only.
    // Optional override is available for debugging via ALLOW_CLIENT_MODEL_OVERRIDE=true.
    const model = ALLOW_CLIENT_MODEL_OVERRIDE && requestedModel ? requestedModel : AI_MODEL;
    const bodyProfile = {
      heightCm: typeof req.body?.height_cm === "string" ? req.body.height_cm.trim() : "",
      weightKg: typeof req.body?.weight_kg === "string" ? req.body.weight_kg.trim() : "",
      chestCm: typeof req.body?.chest_cm === "string" ? req.body.chest_cm.trim() : "",
      waistCm: typeof req.body?.waist_cm === "string" ? req.body.waist_cm.trim() : "",
      hipCm: typeof req.body?.hip_cm === "string" ? req.body.hip_cm.trim() : "",
      armSpanCm: typeof req.body?.arm_span_cm === "string" ? req.body.arm_span_cm.trim() : ""
    };

    const inputVideo = await materializeVideoPathForFfmpeg(req.file);
    if (inputVideo && inputVideo !== req.file.path) {
      tempPathsToDelete.push(inputVideo);
    }

    const durationSec = await getVideoDurationSeconds(inputVideo);
    if (durationSec === null) {
      return res.status(400).json({
        error: true,
        code: "DURATION_UNKNOWN",
        message: "无法读取视频时长。请将视频另存为 H.264 MP4 后重试，并确认服务器已正确安装 ffmpeg/ffprobe（npm 依赖 ffmpeg-static / ffprobe-static）。"
      });
    }
    if (durationSec < MIN_VIDEO_SEC) {
      return res.status(400).json({
        error: true,
        code: "VIDEO_TOO_SHORT",
        message: "上传视频时长过短，请重新上传。请上传 10 秒至 2 分钟之间的视频。"
      });
    }
    if (durationSec > MAX_VIDEO_SEC) {
      return res.status(400).json({
        error: true,
        code: "VIDEO_TOO_LONG",
        message: "视频时长过长，请重新上传。请上传 10 秒至 2 分钟之间的视频。"
      });
    }

    const { frames, note, tempFramePaths } = await extractFrames(inputVideo, {
      originalName: req.file.originalname,
      mimetype: req.file.mimetype
    });
    tempPathsToDelete.push(...tempFramePaths);

    const responsePayload = await analyzeWithCompatibleVisionModel({
      apiKey: AI_API_KEY,
      model,
      sport,
      file: req.file,
      frames,
      note,
      bodyProfile
    });

    res.json(responsePayload);
  } catch (error) {
    console.error("[analyze-video] failed:", error);

    res.status(500).json({
      error: true,
      message: formatServerError(error)
    });
  } finally {
    for (const filePath of tempPathsToDelete) {
      try {
        const stats = await fsp.stat(filePath);
        if (stats.isDirectory()) {
          await fsp.rm(filePath, { recursive: true, force: true });
        } else {
          await fsp.unlink(filePath);
        }
      } catch (cleanupError) {
        console.warn("[analyze-video] cleanup warning:", cleanupError.message);
      }
    }
  }
}

app.post("/api/analyze-video", upload.single("video"), handleAnalyzeVideo);
app.post("/api/analyze", upload.single("video"), handleAnalyzeVideo);

async function analyzeWithCompatibleVisionModel({ apiKey, model, sport, file, frames, note, bodyProfile }) {
  const isTennis = (sport || "").trim().toLowerCase() === "tennis";

  if (frames.length === 0) {
    return isTennis
      ? buildTennisNoVideoFramesResponse(note)
      : buildGenericNoVideoFramesResponse(sport, note);
  }

  const bodyProfileLine = formatBodyProfileForPrompt(bodyProfile);
  const metadataText = [
    `Original filename: ${file.originalname || "unknown"}`,
    `Uploaded mime type: ${file.mimetype || "unknown"}`,
    `Uploaded size bytes: ${file.size || 0}`,
    note ? `Frame extraction note: ${note}` : null,
    bodyProfileLine
  ]
    .filter(Boolean)
    .join("\n");

  const systemContent = isTennis
    ? tennisRatingSystemPrompt(frames.length, note)
    : promptForNonTennis(sport, frames.length, note);

  async function requestOnce(modelName) {
    const response = await fetch(
      `${AI_BASE_URL}/chat/completions`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: modelName,
          response_format: {
            type: "json_object"
          },
          messages: [
            {
              role: "system",
              content: systemContent
            },
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: metadataText
                },
                ...frames.map((frame) => ({
                  type: "image_url",
                  image_url: {
                    url: `data:${frame.mimeType};base64,${frame.base64}`
                  }
                }))
              ]
            }
          ],
          temperature: isTennis ? 0.1 : 0.2
        })
      }
    );

    const rawResponseText = await response.text();
    const responseJson = tryParseJson(rawResponseText);
    return { response, rawResponseText, responseJson, modelName };
  }

  const primaryAttempt = await requestOnce(model);
  let successful = primaryAttempt;

  if (!primaryAttempt.response.ok) {
    const canFallback =
      shouldRetryWithFallback(primaryAttempt.response.status, primaryAttempt.responseJson, primaryAttempt.rawResponseText) &&
      AI_FALLBACK_MODEL &&
      AI_FALLBACK_MODEL !== model;

    if (!canFallback) {
      throw new Error(
        extractCompatibleApiError(
          primaryAttempt.response.status,
          primaryAttempt.responseJson,
          primaryAttempt.rawResponseText
        )
      );
    }

    console.warn(`[analyze-video] primary model "${model}" unavailable, retrying with fallback "${AI_FALLBACK_MODEL}"`);
    const fallbackAttempt = await requestOnce(AI_FALLBACK_MODEL);

    if (!fallbackAttempt.response.ok) {
      const primaryMessage = extractCompatibleApiError(
        primaryAttempt.response.status,
        primaryAttempt.responseJson,
        primaryAttempt.rawResponseText
      );
      const fallbackMessage = extractCompatibleApiError(
        fallbackAttempt.response.status,
        fallbackAttempt.responseJson,
        fallbackAttempt.rawResponseText
      );
      throw new Error(`${primaryMessage} | Fallback "${AI_FALLBACK_MODEL}" failed: ${fallbackMessage}`);
    }

    successful = fallbackAttempt;
  }

  const rawContent = successful.responseJson?.choices?.[0]?.message?.content;
  const outputText = Array.isArray(rawContent)
    ? rawContent
        .map((part) => (typeof part === "string" ? part : part?.text || ""))
        .join("")
        .trim()
    : typeof rawContent === "string"
      ? rawContent.trim()
      : "";

  if (!outputText) {
    throw new Error("Compatible vision model returned no text output.");
  }

  let parsed;
  try {
    parsed = parseModelJsonString(outputText);
  } catch (parseError) {
    throw new Error("Compatible vision model returned invalid JSON after stripping markdown.");
  }

  if (isTennis) {
    return normalizeTennisAnalysisPayload(parsed, note, frames.length);
  }

  return normalizeAnalysisPayload(parsed, sport, note, frames.length);
}

function shouldRetryWithFallback(status, responseJson, rawText) {
  if (status !== 404 && status !== 400) {
    return false;
  }
  const combined = [
    responseJson?.error?.message,
    responseJson?.message,
    responseJson?.detail,
    responseJson?.error?.code,
    responseJson?.code,
    rawText
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  return (
    combined.includes("model_not_found") ||
    combined.includes("model not found") ||
    combined.includes("does not exist") ||
    combined.includes("no access") ||
    combined.includes("not access")
  );
}

function formatBodyProfileForPrompt(bodyProfile) {
  if (!bodyProfile || typeof bodyProfile !== "object") {
    return null;
  }
  const parts = [];
  if (bodyProfile.heightCm) parts.push(`height ${bodyProfile.heightCm} cm`);
  if (bodyProfile.weightKg) parts.push(`weight ${bodyProfile.weightKg} kg`);
  if (bodyProfile.chestCm) parts.push(`chest ${bodyProfile.chestCm} cm`);
  if (bodyProfile.waistCm) parts.push(`waist ${bodyProfile.waistCm} cm`);
  if (bodyProfile.hipCm) parts.push(`hip ${bodyProfile.hipCm} cm`);
  if (bodyProfile.armSpanCm) parts.push(`arm span ${bodyProfile.armSpanCm} cm`);
  if (parts.length === 0) {
    return null;
  }
  return `Athlete body profile (self-reported): ${parts.join(", ")}. Use this only to tailor drills/load and movement constraints; do not infer medical conditions.`;
}

/**
 * @param {string} videoPath
 * @param {{ originalName?: string, mimetype?: string }} [meta]
 */
async function extractFrames(videoPath, meta = {}) {
  const frameDirectory = await fsp.mkdtemp(path.join(os.tmpdir(), "movematch-ai-frames-"));
  const tempFramePaths = [frameDirectory];
  const discovered = [];
  const lastFfmpegErrors = [];

  async function addFrameFile(filePath) {
    if (!filePath) {
      return;
    }
    try {
      const st = await fsp.stat(filePath);
      if (st.size < 800) {
        return;
      }
      discovered.push({ filePath, size: st.size });
    } catch {
      /* ignore */
    }
  }

  const runFfmpeg = async (args, label) => {
    try {
      await execFileAsync(getFfmpegPath(), args, { maxBuffer: 80 * 1024 * 1024, encoding: "utf8" });
    } catch (err) {
      const msg = (err && (err.stderr || err.message)) || String(err);
      if (label) {
        lastFfmpegErrors.push(`${label}: ${String(msg).slice(0, 400)}`);
      }
      throw err;
    }
  };

  const inputProbes = ["-analyzeduration", "100M", "-probesize", "100M", "-fflags", "+genpts+discardcorrupt"];
  const commonIn = (extraBeforeI = []) => [
    "-hide_banner",
    "-loglevel",
    "error",
    "-y",
    ...extraBeforeI,
    ...inputProbes,
    "-i",
    videoPath
  ];

  // Try a few input demux hints (useful when extension probing still mis-detects)
  const inputVariants = (() => {
    const n = (meta.originalName || "").toLowerCase();
    const m = (meta.mimetype || "").toLowerCase();
    if (m.includes("quicktime") || n.endsWith(".mov")) {
      return [
        { label: "default", before: [] },
        { label: "mov", before: ["-f", "mov"] },
        { label: "mp4", before: ["-f", "mp4"] }
      ];
    }
    return [
      { label: "default", before: [] },
      { label: "mp4", before: ["-f", "mp4"] },
      { label: "mov", before: ["-f", "mov"] }
    ];
  })();

  const patternJpg = path.join(frameDirectory, "seq-%02d.jpg");

  try {
    for (const variant of inputVariants) {
      if (discovered.length >= 1) {
        break;
      }
      // Attempt 1: short window + sparse fps
      try {
        await runFfmpeg(
          [
            ...commonIn(variant.before),
            "-t",
            "12",
            "-vf",
            "fps=0.35,scale=1280:-2:flags=bicubic",
            "-frames:v",
            "8",
            "-q:v",
            "2",
            patternJpg
          ],
          `seq:${variant.label}`
        );
      } catch {
        /* next variant */
      }

      const seqFiles = (await fsp.readdir(frameDirectory))
        .filter((n) => n.startsWith("seq-") && n.endsWith(".jpg"))
        .sort();
      for (const name of seqFiles) {
        const fp = path.join(frameDirectory, name);
        await addFrameFile(fp);
        if (!tempFramePaths.includes(fp)) {
          tempFramePaths.push(fp);
        }
      }
    }

    // Attempt 2: fast input seek (before -i) + single frame at several timestamps
    if (discovered.length < 1) {
      for (const variant of inputVariants) {
        if (discovered.length >= 1) {
          break;
        }
        const seekSeconds = [0, 0.1, 0.25, 0.4, 0.7, 1, 1.4, 2, 2.5, 3.2, 4, 5, 6, 8];
        for (let i = 0; i < seekSeconds.length; i += 1) {
          const out = path.join(frameDirectory, `sk-${variant.label}-${i}.jpg`);
          try {
            await runFfmpeg(
              [
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                ...variant.before,
                ...inputProbes,
                "-ss",
                String(seekSeconds[i]),
                "-i",
                videoPath,
                "-vframes",
                "1",
                "-an",
                "-sn",
                "-vf",
                "scale=1280:-2:flags=bicubic",
                "-q:v",
                "2",
                out
              ],
              `ss:${variant.label}@${seekSeconds[i]}`
            );
            await addFrameFile(out);
            tempFramePaths.push(out);
          } catch {
            /* next */
          }
          if (discovered.length >= 6) {
            break;
          }
        }
      }
    }

    // Attempt 3: seek after -i (accurate) on a few key times
    if (discovered.length < 1) {
      for (const t of [0.3, 0.8, 1.2, 2, 3.5, 5]) {
        const out = path.join(frameDirectory, `acc-${t}.jpg`);
        try {
          await runFfmpeg(
            [
              ...commonIn([]),
              "-ss",
              String(t),
              "-vframes",
              "1",
              "-an",
              "-sn",
              "-vf",
              "scale=1280:-2:flags=bicubic",
              "-q:v",
              "2",
              out
            ],
            `acc@${t}`
          );
          await addFrameFile(out);
          tempFramePaths.push(out);
        } catch {
          /* next */
        }
        if (discovered.length >= 1) {
          break;
        }
      }
    }

    if (process.env.NODE_ENV !== "test" && discovered.length < 1) {
      console.error("[movematch] ffmpeg could not produce frames for:", videoPath, meta);
      for (const line of lastFfmpegErrors.slice(-4)) {
        console.error("[movematch]", line);
      }
    }

    discovered.sort((a, b) => b.size - a.size);
    const maxFrames = 8;
    const chosen = discovered.slice(0, maxFrames);

    const frames = await Promise.all(
      chosen.map(async (entry) => ({
        mimeType: "image/jpeg",
        base64: await fsp.readFile(entry.filePath, { encoding: "base64" })
      }))
    );

    const failHint =
      lastFfmpegErrors.length > 0
        ? ` Last ffmpeg: ${String(lastFfmpegErrors[lastFfmpegErrors.length - 1]).slice(0, 220)}`
        : "";

    return {
      frames,
      note: frames.length
        ? ""
        : `ffmpeg could not generate preview frames (check codec, file, or that ffmpeg is installed; upload must use .mp4 / .mov path).${failHint}`,
      tempFramePaths
    };
  } catch (error) {
    return {
      frames: [],
      note: `No video frames were extracted. ${error?.message || "ffmpeg failed or is not available."}`,
      tempFramePaths
    };
  }
}

function formatServerError(error) {
  const message = error?.message || "Unknown server error.";
  const normalized = message.toLowerCase();

  if (
    normalized.includes("api key") ||
    normalized.includes("access key") ||
    normalized.includes("invalid api-key") ||
    normalized.includes("unauthorized")
  ) {
    return "The configured API key is invalid or missing. Check AI_API_KEY in backend-node/.env.";
  }

  if (
    normalized.includes("model does not exist") ||
    normalized.includes("invalid model") ||
    normalized.includes("model not found") ||
    normalized.includes("unknown model")
  ) {
    return `The selected model is unavailable: ${message}`;
  }

  if (
    normalized.includes("invalid parameter") ||
    normalized.includes("bad request") ||
    normalized.includes("unsupported") ||
    normalized.includes("image_url")
  ) {
    return `The provider rejected the request format: ${message}`;
  }

  if (normalized.includes("invalid json")) {
    return "The model did not return valid JSON. Please try again.";
  }

  if (normalized.includes("quota") || normalized.includes("429")) {
    return "The provider rate limit or quota was reached. Please wait and try again.";
  }

  return message;
}

function tryParseJson(text) {
  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

// DashScope/Qwen-compatible gateways do not always return the same error
// envelope, so we inspect several common shapes and preserve request ids when available.
function extractCompatibleApiError(status, responseJson, rawText) {
  const errorObject = responseJson?.error;
  const message =
    errorObject?.message ||
    responseJson?.message ||
    responseJson?.msg ||
    responseJson?.detail ||
    responseJson?.error_msg ||
    summarizeRawErrorText(rawText) ||
    `Compatible vision model request failed with HTTP ${status}.`;

  const code =
    errorObject?.code ||
    errorObject?.type ||
    responseJson?.code ||
    responseJson?.type ||
    responseJson?.status;

  const requestId =
    responseJson?.request_id ||
    responseJson?.requestId ||
    responseJson?.id ||
    errorObject?.request_id;

  const details = [
    code ? `code: ${code}` : null,
    requestId ? `request_id: ${requestId}` : null,
    status ? `http: ${status}` : null
  ]
    .filter(Boolean)
    .join(", ");

  return details.length === 0 ? message : `${message} (${details})`;
}

function summarizeRawErrorText(rawText) {
  if (!rawText) {
    return "";
  }

  const singleLine = rawText.replace(/\s+/g, " ").trim();
  if (!singleLine) {
    return "";
  }

  return singleLine.length > 280 ? `${singleLine.slice(0, 277)}...` : singleLine;
}

function normalizeConfidence(value) {
  const c = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (c === "low" || c === "medium" || c === "high") {
    return c;
  }
  return "medium";
}

function normalizeTennisAnalysisPayload(payload, note, frameCount) {
  const hasUsable = hasUsableVideoFrames(frameCount);
  let score = normalizeScore(payload?.score, hasUsable ? 50 : 0);
  if (shouldApplyTennisUncertaintyPenalty(frameCount, note)) {
    score = stepDownTennisOneBand(score);
  }

  const { level, ntrpEquivalent } = tennisLevelFromScore(score);
  const confidenceRaw = normalizeConfidence(payload?.confidence);
  const confidence = shouldApplyTennisUncertaintyPenalty(frameCount, note) && confidenceRaw === "high" ? "medium" : confidenceRaw;

  const strengths = normalizeList(payload?.strengths, hasUsable ? [
    "Shows a usable athletic base in the visible frames."
  ] : [
    "The video upload completed successfully."
  ]);
  const weaknesses = normalizeList(
    payload?.weaknesses,
    hasUsable
      ? ["Some technical details are hard to see clearly in this clip."]
      : ["Unable to assess technique because clear movement frames were not available."]
  );
  const trainingPlan = normalizeTrainingPlanTennis(
    payload?.trainingPlan,
    hasUsable
  );

  const issues = weaknesses;
  const suggestions = trainingPlan.length
    ? trainingPlan
    : [
        "Upload a full-body, side-on clip with stable lighting and 3-5 full strokes.",
        "Repeat 10-15 slow shadow swings with early unit turn and balance.",
        "Film again after a week to compare the same shot type."
      ];

  const shotPlacements = normalizeShotPlacements(payload?.shotPlacements);
  const depthControlLine = normalizeDepthControlLine(
    payload?.depthControlLine,
    hasUsable,
    shotPlacements.length
  );

  return {
    score,
    level,
    ntrpEquivalent,
    confidence,
    summary: normalizeSummary(payload?.summary, hasUsable),
    strengths,
    weaknesses,
    trainingPlan,
    issues,
    suggestions,
    training_plan: trainingPlan,
    shotPlacements,
    depth_control_line: depthControlLine
  };
}

function normalizeShotPlacements(raw) {
  if (!Array.isArray(raw) || raw.length === 0) {
    return [];
  }
  const out = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") {
      /* skip */
    } else {
      const x = Number(item.x);
      const y = Number(item.y);
      const player = Number(item.player) === 2 ? 2 : 1;
      if (Number.isFinite(x) && Number.isFinite(y)) {
        out.push({
          x: Math.max(0, Math.min(1, x)),
          y: Math.max(0, Math.min(1, y)),
          player
        });
      }
    }
    if (out.length >= 20) {
      break;
    }
  }
  return out;
}

function normalizeDepthControlLine(value, hasUsable, placementCount) {
  const t = typeof value === "string" ? cleanUserFacingText(value) : "";
  if (t) {
    return t;
  }
  if (!hasUsable) {
    return "No usable frames were extracted; placement lines below are informational only.";
  }
  if (placementCount === 0) {
    return "This clip could not reliably locate ball bounces. Try a sideline or high camera angle with the full court in view.";
  }
  return "Placements are inferred from the video for coaching reference (not line-call tracking).";
}

function normalizeAnalysisPayload(payload, sport, note, frameCount) {
  const hasUsable = hasUsableVideoFrames(frameCount);
  const score = normalizeScore(payload?.score, hasUsable ? 72 : 0);
  const level = normalizePlainText(payload?.level, hasUsable ? "Needs Review" : "Unknown");

  return {
    score,
    level,
    summary: normalizeSummary(payload?.summary, hasUsable),
    strengths: normalizeList(payload?.strengths, hasUsable ? [
      "Shows a usable athletic base in parts of the clip."
    ] : [
      "The video upload completed successfully."
    ]),
    issues: normalizeList(payload?.issues, hasUsable ? [
      "Some key movement details are still unclear in this clip."
    ] : [
      "Unable to assess technique because clear movement frames were not available."
    ]),
    suggestions: normalizeList(payload?.suggestions, hasUsable ? [
      "Upload a side-view clip with full-body framing for clearer feedback."
    ] : [
      "Re-upload the video or enable frame extraction before analyzing again.",
      "Record from a side-on angle with your full body visible.",
      "Include 3-5 full strokes with clear follow-through."
    ]),
    training_plan: normalizeTrainingPlanNonTennis(payload?.training_plan ?? payload?.trainingPlan, hasUsable)
  };
}

function normalizeScore(value, fallback) {
  const numeric = Number(value);
  if (Number.isFinite(numeric)) {
    return Math.max(0, Math.min(100, Math.round(numeric)));
  }
  return fallback;
}

function normalizeSummary(value, hasFrames) {
  const text = normalizePlainText(value, "");
  if (!text) {
    return hasFrames
      ? "Your clip was analyzed successfully. Focus on the key issues and next steps below."
      : "We could not read clear movement frames from this video, so the feedback below is limited.";
  }

  if (text.startsWith("{") || text.startsWith("[")) {
    return hasFrames
      ? "Your clip was analyzed successfully. Review the simplified feedback below."
      : "We could not extract a clear technical summary from this upload.";
  }

  if (!hasFrames) {
    return "We could not read clear movement frames from this video, so the feedback below is limited.";
  }

  const firstTwoSentences = text
    .split(/(?<=[.!?])\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .join(" ")
    .trim();

  return firstTwoSentences || text;
}

function normalizeTrainingPlanTennis(value, hasFrames) {
  const normalized = normalizeList(
    value,
    hasFrames
      ? [
          "Repeat 10 forehand swings with early unit turn and a balanced finish.",
          "Film a side view with 3-5 full strokes and stable lighting.",
          "Add split-step and recovery footwork for every shot in a mini drill block."
        ]
      : [
          "Record a side-view clip with your full body in frame.",
          "Include 3-5 full strokes with clear follow-through.",
          "Retry the upload after checking lighting and camera stability."
        ]
  );

  return normalized.slice(0, 4);
}

function normalizeTrainingPlanNonTennis(value, hasFrames) {
  const normalized = normalizeList(
    value,
    hasFrames
      ? [
          "Repeat 10 shadow swings with early preparation.",
          "Film another side-view clip after your next session.",
          "Focus on balanced recovery after each stroke."
        ]
      : [
          "Record a side-view clip with your full body in frame.",
          "Include 3-5 full strokes with clear follow-through.",
          "Retry the upload after checking lighting and camera stability."
        ]
  );

  return normalized.slice(0, 4);
}

function normalizeList(value, fallback) {
  if (!Array.isArray(value) || value.length === 0) {
    return fallback;
  }

  const items = value
    .map((entry) => normalizeListItem(entry))
    .filter(Boolean)
    .slice(0, 4);

  return items.length ? items : fallback;
}

function normalizeListItem(entry) {
  if (typeof entry === "string") {
    return cleanUserFacingText(entry);
  }

  if (!entry || typeof entry !== "object") {
    return "";
  }

  const preferredKeys = ["text", "summary", "description", "suggestion", "issue", "goal", "drill", "focus", "title"];
  for (const key of preferredKeys) {
    if (typeof entry[key] === "string" && entry[key].trim()) {
      return cleanUserFacingText(entry[key]);
    }
  }

  const parts = [entry.phase, entry.goal, entry.drill]
    .filter((part) => typeof part === "string" && part.trim())
    .map((part) => cleanUserFacingText(part));

  if (parts.length) {
    return parts.join(": ");
  }

  return "";
}

function normalizePlainText(value, fallback) {
  if (typeof value !== "string") {
    return fallback;
  }
  const cleaned = cleanUserFacingText(value);
  return cleaned || fallback;
}

function cleanUserFacingText(value) {
  if (typeof value !== "string") {
    return "";
  }

  return value
    .replace(/\s+/g, " ")
    .replace(/^[-\u2022\s]+/, "")
    .trim();
}

if (!process.env.VERCEL) {
  app.listen(PORT, () => {
    console.log(`MoveMatch AI Node backend listening on http://127.0.0.1:${PORT}`);
  });
}

module.exports = app;
