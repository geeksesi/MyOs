# Voice Recording & AI Transcription Workflow

## Quick Start

1. **Reload i3 configuration** (if not done yet):
   - Press `Mod+Shift+R` or run `i3-msg reload`

2. **Start recording**:
   - Press `Mod+S`
   - You'll see "🎤 Recording" notification
   - Status bar shows "🎤 Recording" in red

3. **Stop, transcribe, and process with AI**:
   - Press `Mod+A`
   - Watch notifications progress through:
     - ⏸️  Processing
     - 📝 Transcribing
     - 🤖 AI Processing
     - 📋 Success
   - AI response is automatically copied to clipboard
   - Paste anywhere with `Ctrl+V`

## Keybindings

- `Mod+S` - Start voice recording
- `Mod+A` - Stop recording, transcribe, and process with AI

## Status Bar Indicators

The i3 status bar will show recording status:
- 🎤 Recording (red) - Currently recording
- ⏸️  Processing (yellow) - Stopping recording
- 📝 Transcribing (yellow) - Converting speech to text
- 🤖 AI (blue) - Processing with Claude AI
- ❌ Error (red) - An error occurred
- (no indicator) - Idle/ready

## Logs

All transcripts and AI responses are logged to:
```
~/Downloads/bin/log/YYYY-MM-DD-HH-MM-SS.log
```

Each log file contains:
- Timestamp
- Original transcript
- Claude AI response

Example:
```bash
# View latest log
ls -lt ~/Downloads/bin/log/ | head -n 2

# Read a specific log
cat ~/Downloads/bin/log/2026-02-11-19-45-30.log
```

## Troubleshooting

### Recording doesn't start
- Check if sa daemon is running: `~/Downloads/bin/sa status`
- Restart daemon: Kill it and reload i3 (`Mod+Shift+R`)

### No notification appears
- Check dunst is running: `pgrep dunst`
- Test notifications: `notify-send "Test" "Testing notifications"`

### Clipboard doesn't update
- Test xclip: `echo "test" | xclip -selection clipboard`
- Paste with: `xclip -o -selection clipboard`

### Status bar doesn't show indicator
- Check status file: `cat ~/.cache/sa-recording-status`
- Verify wrapper is running: `pgrep -f sa-status-wrapper`

### Verification script
Run the verification script to check all components:
```bash
~/.local/bin/sa-verify
```

## Script Locations

- **Start recording**: `~/.local/bin/sa-start`
- **Stop & transcribe**: `~/.local/bin/sa-stop-transcribe`
- **Status wrapper**: `~/.local/bin/sa-status-wrapper`
- **Verification**: `~/.local/bin/sa-verify`

## Workflow Details

1. Press `Mod+S` → sa daemon starts recording audio
2. Speak your message
3. Press `Mod+A` → workflow begins:
   - Stops recording
   - Extracts transcript from audio
   - Sends transcript to Claude Haiku (fast, cost-effective)
   - Claude processes the text as-is (no additional prompting)
   - Response copied to clipboard
   - Both transcript and response logged

## Claude Processing

The transcript is sent directly to Claude Haiku with `-p` (pipe mode):
- Fast processing (Haiku model)
- No additional prompting - Claude receives the transcript as-is
- You can modify the script to add custom prompting if needed

To customize Claude's behavior, edit `~/.local/bin/sa-stop-transcribe` and modify the Claude command line.

## Tips

- Keep recordings short for faster processing
- Speak clearly for better transcription accuracy
- Check logs to review past transcripts and AI responses
- Use clipboard history tool to access previous AI responses
- The sa tool uses Whisper small-q5_1 model for transcription

## Advanced Usage

### Change Claude model
Edit `~/.local/bin/sa-stop-transcribe` and change:
```bash
claude -p --model 'haiku'
```
to:
```bash
claude -p --model 'sonnet'  # More capable, slower, more expensive
```

### Add custom prompting
Modify the Claude command in the script:
```bash
echo "Please summarize this: $TRANSCRIPT" | claude -p --model 'haiku'
```

### View real-time status
```bash
watch -n 1 cat ~/.cache/sa-recording-status
```

## File Structure

```
~/.i3/config                           # i3 configuration with keybindings
~/.local/bin/sa-start                  # Recording start script
~/.local/bin/sa-stop-transcribe        # Stop, transcribe, AI process script
~/.local/bin/sa-status-wrapper         # i3status wrapper
~/.local/bin/sa-verify                 # Verification script
~/.cache/sa-recording-status           # Current status file
~/Downloads/bin/sa                     # speak-to-ai binary
~/Downloads/bin/log/*.log              # Transcript and AI response logs
```
