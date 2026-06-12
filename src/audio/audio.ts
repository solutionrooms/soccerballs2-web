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
  private currentMusic: string | null = null;
  private unlocked = false;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  unlock(): void {
    if (this.unlocked) return;
    try {
      this.ctx = new AudioContext();
      void this.ctx.resume();
      this.unlocked = true;
    } catch {
      this.ctx = null;
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
    if (this.currentMusic === name) return;
    this.currentMusic = name;
    this.stopMusicFade();
    if (!this.musicOn || !this.ctx) return;
    void this.getBuffer(`music/${name}`).then((buf) => {
      if (!buf || !this.ctx || this.currentMusic !== name || !this.musicOn) return;
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
    this.currentMusic = null;
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
      const name = this.currentMusic;
      this.stopMusic();
      this.currentMusic = name; // remember to resume on re-enable
    } else if (this.currentMusic) {
      const name = this.currentMusic;
      this.currentMusic = null;
      this.playMusic(name);
    }
  }
}
