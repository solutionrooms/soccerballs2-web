// Sample-based audio mirroring Audio.as behaviour: one-shot sfx with
// volume/pan, looping music with crossfade (old fades out, new starts at 0.3),
// and silent tolerance of missing sounds.
export class GameAudio {
  sfxOn = true;
  musicOn = true;

  private ctx: AudioContext | null = null;
  private buffers = new Map<string, AudioBuffer>();
  private pending = new Map<string, Promise<AudioBuffer | null>>();
  private baseUrl: string;
  private musicSource: AudioBufferSourceNode | null = null;
  private musicGain: GainNode | null = null;
  /** the track we want playing (retried once audio unlocks) */
  private wantMusic: string | null = null;
  private wantMusicVol = 0.3;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  /**
   * Must be called from a user gesture. Mobile browsers (esp. iOS Safari)
   * keep the AudioContext suspended until a gesture resumes it AND a buffer
   * is played; resume() can also lapse, so this is safe to call on every
   * gesture, not just the first.
   */
  unlock(): void {
    if (!this.ctx) {
      try {
        const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
        this.ctx = new Ctor();
      } catch {
        this.ctx = null;
        return;
      }
    }
    if (this.ctx.state === 'suspended') void this.ctx.resume();
    // iOS: a near-silent buffer played in the gesture actually unlocks output
    try {
      const buf = this.ctx.createBuffer(1, 1, 22050);
      const src = this.ctx.createBufferSource();
      src.buffer = buf;
      src.connect(this.ctx.destination);
      src.start(0);
    } catch {
      // ignore
    }
    // start (or resume) the music we wanted before audio was available
    if (this.wantMusic && !this.musicSource && this.musicOn) {
      this.startMusic(this.wantMusic, this.wantMusicVol);
    }
  }

  private async getBuffer(path: string): Promise<AudioBuffer | null> {
    if (!this.ctx) return null;
    const cached = this.buffers.get(path);
    if (cached) return cached;
    let p = this.pending.get(path);
    if (!p) {
      p = (async () => {
        try {
          const url = `${this.baseUrl}${path}.${this.preferredExt()}`;
          const res = await fetch(url);
          if (!res.ok) return null;
          const buf = await this.ctx!.decodeAudioData(await res.arrayBuffer());
          this.buffers.set(path, buf);
          return buf;
        } catch {
          return null; // missing sounds are tolerated, like Audio.as
        }
      })();
      this.pending.set(path, p);
    }
    return p;
  }

  private preferredExt(): string {
    const el = document.createElement('audio');
    return el.canPlayType('audio/ogg; codecs=vorbis') ? 'ogg' : 'm4a';
  }

  playSfx(name: string, volume = 1, pan = 0): void {
    if (!this.sfxOn || !this.ctx) return;
    void this.getBuffer(`sfx/${name}`).then((buf) => {
      if (!buf || !this.ctx || !this.sfxOn) return;
      const src = this.ctx.createBufferSource();
      src.buffer = buf;
      const gain = this.ctx.createGain();
      gain.gain.value = volume;
      const panner = this.ctx.createStereoPanner();
      panner.pan.value = Math.max(-1, Math.min(1, pan));
      src.connect(gain).connect(panner).connect(this.ctx.destination);
      src.start();
    });
  }

  playMusic(name: string, volume = 0.3): void {
    if (this.wantMusic === name && this.musicSource) return; // already playing
    this.wantMusic = name;
    this.wantMusicVol = volume;
    this.stopMusicFade();
    this.startMusic(name, volume);
  }

  /** Begin a track if audio is ready; otherwise it's retried on unlock. */
  private startMusic(name: string, volume: number): void {
    if (!this.musicOn || !this.ctx || this.ctx.state !== 'running') return;
    void this.getBuffer(`music/${name}`).then((buf) => {
      if (!buf || !this.ctx || this.wantMusic !== name || !this.musicOn || this.musicSource) return;
      const src = this.ctx.createBufferSource();
      src.buffer = buf;
      src.loop = true;
      const gain = this.ctx.createGain();
      gain.gain.value = volume;
      src.connect(gain).connect(this.ctx.destination);
      src.start();
      this.musicSource = src;
      this.musicGain = gain;
    });
  }

  stopMusic(): void {
    this.wantMusic = null;
    this.stopMusicFade();
  }

  private stopMusicFade(): void {
    if (this.musicSource && this.musicGain && this.ctx) {
      const src = this.musicSource;
      // Audio.as StartFadeOut: ramp down then stop
      this.musicGain.gain.linearRampToValueAtTime(0, this.ctx.currentTime + 0.8);
      setTimeout(() => {
        try {
          src.stop();
        } catch {
          // already stopped
        }
      }, 900);
    }
    this.musicSource = null;
    this.musicGain = null;
  }

  setMusicOn(on: boolean): void {
    this.musicOn = on;
    if (!on) {
      // keep wantMusic so it resumes when re-enabled; just stop playback
      this.stopMusicFade();
    } else if (this.wantMusic && !this.musicSource) {
      this.startMusic(this.wantMusic, this.wantMusicVol);
    }
  }
}
