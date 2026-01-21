# Sound Assets

This directory contains sound effects for the GrabIt app.

## Required Sound Files

Please add the following sound files to this directory:

1. **whoosh.mp3** - Sound for the paper plane animation when adding items to cart
   - Duration: ~1-2 seconds
   - Suggested: A whooshing/swishing sound effect

2. **whistle.mp3** - Sound for rider arrival (doorbell phase)
   - Duration: ~1-2 seconds
   - Suggested: A whistle or notification sound

3. **ding.mp3** - Sound for success (unboxing phase after OTP verification)
   - Duration: ~0.5-1 second
   - Suggested: A pleasant ding/chime sound

## File Format

- Format: MP3
- Sample Rate: 44.1 kHz (recommended)
- Bitrate: 128 kbps or higher
- Channels: Mono or Stereo

## Free Sound Resources

You can find free sound effects at:
- https://freesound.org/
- https://mixkit.co/free-sound-effects/
- https://www.zapsplat.com/

## Notes

- The app will work without these files, but sounds won't play
- The SoundService handles missing files gracefully
- All sounds are optional and the app functions normally without them



