const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const cors = require('cors');
const fs = require('fs').promises;

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());
app.use(cors());

const downloadsDir = path.join(__dirname, 'downloads');
const cookiesPath = path.join(__dirname, 'youtube-cookies.txt'); // Set your cookies file path here

// Ensure the downloads directory exists
(async () => {
  try {
    await fs.mkdir(downloadsDir, { recursive: true });
    await fs.chmod(downloadsDir, '777');
  } catch (err) {
    console.error('Error creating downloads directory:', err);
  }
})();

// Utility to run a shell command and return a promise
const runCommand = (command) => {
  console.log("Executing:", command);
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error("Command error:", stderr);
        return reject(error);
      }
      resolve(stdout);
    });
  });
};

/**
 * /caption-video Endpoint
 * Expected JSON payload:
 * {
 *    "videoUrl": "https://youtu.be/XXXX",
 *    "startSeconds": "optional start seconds",    // Optional – if not provided, process entire video
 *    "endSeconds": "optional end seconds"
 * }
 */
app.post('/caption-video', async (req, res) => {
  const { videoUrl, startSeconds, endSeconds } = req.body;
  if (!videoUrl) {
    return res.status(400).json({ error: "Missing field: videoUrl" });
  }

  // Parse start/end if provided (optional)
  let section = "";
  if (startSeconds && endSeconds && !isNaN(startSeconds) && !isNaN(endSeconds) && parseFloat(startSeconds) < parseFloat(endSeconds)) {
    section = `--download-sections "*${startSeconds}-${endSeconds}"`;
  }

  const timestamp = Date.now();
  const videoPath = path.join(downloadsDir, `video-${timestamp}.mp4`);
  const audioPath = path.join(downloadsDir, `video-${timestamp}.wav`);
  const srtPath = path.join(downloadsDir, `video-${timestamp}.srt`);
  const assPath = path.join(downloadsDir, `video-${timestamp}.ass`);
  const outputPath = path.join(downloadsDir, `captioned-${timestamp}.mp4`);

  try {
    // 1. Download video using yt-dlp (with optional trimming)
    const ytDlpCmd = `yt-dlp --no-check-certificate --cookies "${cookiesPath}" ${section} -f "bestvideo+bestaudio/best" --merge-output-format mp4 -o "${videoPath}" "${videoUrl}"`;
    await runCommand(ytDlpCmd);

    // 2. Extract audio from video (mono, 16kHz)
    const extractAudioCmd = `ffmpeg -y -i "${videoPath}" -vn -ac 1 -ar 16000 "${audioPath}"`;
    await runCommand(extractAudioCmd);

    // 3. Generate captions using Whisper (output SRT)
    // Whisper will generate output files in the same directory with the same base name.
    // For example: if input is video-<timestamp>.wav, it will output video-<timestamp>.srt.
    const whisperCmd = `whisper "${audioPath}" --model small --output_format srt --output_dir "${downloadsDir}"`;
    await runCommand(whisperCmd);
    // (Assuming the output SRT file is named exactly as srtPath)

    // 4. Convert SRT to ASS for styling (this uses FFmpeg to do a basic conversion)
    // You can later edit the ASS file to change style options.
    const convertCmd = `ffmpeg -y -i "${srtPath}" "${assPath}"`;
    await runCommand(convertCmd);

    // 5. Burn captions into the video using FFmpeg (ASS styling)
    const burnCmd = `ffmpeg -y -i "${videoPath}" -vf "ass=${assPath}" -c:a copy "${outputPath}"`;
    await runCommand(burnCmd);

    // 6. Send the final captioned video and clean up temporary files
    res.sendFile(outputPath, async (err) => {
      if (err) {
        console.error("Error sending file:", err);
        return res.status(500).json({ error: "Failed to send output file." });
      }
      try {
        await Promise.all([
          fs.unlink(videoPath),
          fs.unlink(audioPath),
          fs.unlink(srtPath),
          fs.unlink(assPath),
          fs.unlink(outputPath)
        ]);
        console.log("Cleaned up temporary files.");
      } catch (cleanupError) {
        console.error("Cleanup error:", cleanupError);
      }
    });

  } catch (error) {
    console.error("Processing error:", error);
    res.status(500).json({ error: error.message });
    // Clean up any temporary files
    try {
      await Promise.all([
        fs.unlink(videoPath).catch(() => {}),
        fs.unlink(audioPath).catch(() => {}),
        fs.unlink(srtPath).catch(() => {}),
        fs.unlink(assPath).catch(() => {}),
        fs.unlink(outputPath).catch(() => {})
      ]);
    } catch (cleanupError) {
      console.error("Cleanup error after failure:", cleanupError);
    }
  }
});

app.get('/', (req, res) => {
  res.send('Caption-Video API is running!');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
