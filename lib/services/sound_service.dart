import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sound service for managing audio playback throughout the app
class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _soundsEnabled = true;

  /// Enable or disable sounds
  void setSoundsEnabled(bool enabled) {
    _soundsEnabled = enabled;
  }

  bool get soundsEnabled => _soundsEnabled;

  /// Play a sound effect
  Future<void> playSound(String assetPath, {double volume = 0.7}) async {
    if (!_soundsEnabled) return;

    try {
      await _player.play(AssetSource(assetPath), volume: volume);
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
      // Fallback: Use system sound if asset not found
      // This allows the app to work even without sound files
    }
  }

  /// Play "Whoosh" sound for paper plane animation
  Future<void> playWhoosh() async {
    await playSound('sounds/whoosh.mp3', volume: 0.6);
  }

  /// Play "Whistle" sound for rider arrival
  Future<void> playWhistle() async {
    await playSound('sounds/whistle.mp3', volume: 0.8);
  }

  /// Play "Ding" sound for success
  Future<void> playDing() async {
    await playSound('sounds/ding.mp3', volume: 0.7);
  }

  /// Stop all sounds
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}




