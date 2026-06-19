package audioPackage;

import haxe.Constraints.Function;
import flash.events.Event;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.net.URLLoader;
import flash.system.Capabilities;
import flash.utils.ByteArray;
import org.flashdevelop.utils.FlashConnect;

/**
	 * ...
	 * @author ...
	 */
class Audio
{
    public static var soundDefs : Array<SoundEffectDef>;
    public static var activeSounds : Array<ActiveSoundEffectItem>;
    
    public static var muteSFX : Bool;
    public static var muteMusic : Bool;
    
    public static var soundAllowed : Bool;
    
    public static var isInitialised : Bool = false;
    
    
    public function new()
    {
    }
    
    
    
    public static function InitOnce()
    {
        isInitialised = true;
        soundAllowed = true;
        muteSFX = false;
        muteMusic = false;
        playingLocalFile = false;
        
        if (false)
        {
            muteSFX = true;
            muteMusic = true;
        }
        
        soundDefs = [];
        activeSounds = [];
        for (i in 0...32)
        {
            activeSounds.push(new ActiveSoundEffectItem());
        }
        
        
        // HTML5: the Web AudioContext starts SUSPENDED (browser autoplay policy) and only resumes
        // inside a user-gesture handler. The original startup probe disabled ALL audio when play()
        // returned null — but pre-gesture that's the normal web state, so it muted the game forever
        // on Mac and mobile alike. Keep sound enabled; unlock the shared context on the first gesture
        // (openfl sounds all use lime AudioManager.context.web — see openfl Sound.hx).
        var s : Sound = new SfxClick();
        try { s.play(0, 0, new SoundTransform(0, 0)); } catch (e : Dynamic) {}

        #if (js && html5)
        try {
            var resumeAudio : Dynamic = null;
            resumeAudio = function(ev : Dynamic) : Void {
                try {
                    var ctx = lime.media.AudioManager.context;
                    if (ctx != null && ctx.web != null) ctx.web.resume();
                } catch (err : Dynamic) {}
            };
            js.Browser.document.addEventListener("touchend", resumeAudio);
            js.Browser.document.addEventListener("mousedown", resumeAudio);
            js.Browser.document.addEventListener("keydown", resumeAudio);
        } catch (e : Dynamic) {}
        #end
    }
    
    public static function IsMuteSFX() : Bool
    {
        return muteSFX;
    }
    public static function ToggleMuteSFX() : Void
    {
        if (soundAllowed == false)
        {
            muteSFX = true;
            return;
        }
        
        muteSFX = (muteSFX == false);
        if (muteSFX)
        {
            MuteAll(false);
        }
        else
        {
            UnMuteAll(false);
        }
    }
    
    public static function IsMuteMusic() : Bool
    {
        return muteMusic;
    }
    public static function ToggleMuteMusic() : Void
    {
        if (soundAllowed == false)
        {
            muteMusic = true;
            return;
        }
        muteMusic = (muteMusic == false);
        if (muteMusic)
        {
            MuteAll(true);
        }
        else
        {
            UnMuteAll(true);
        }
    }
    
    
    public static function GetSoundDefByName(name : String)
    {
        for (def in soundDefs)
        {
            if (def.name == name)
            {
                return def;
            }
        }
        return AddSound(name);
    }
    
    
    public static function AddSound(_soundName : String) : SoundEffectDef
    {
        // Web port: the original game resolved SWF-embedded sound classes by name; we ship the
        // converted OGGs (assets/audio/{sfx,music}/<name>.ogg) and look them up by the SAME name the
        // game requests, so all the existing OneShot/PlayMusic/Loop call sites work unchanged.
        var s : Sound = LoadSoundByName(_soundName);

        // Legacy fallback: a directly-linked Sound class (e.g. the SfxClick stub).
        if (s == null)
        {
            var classRef : Class<Dynamic> = null;
            try { classRef = Type.getClass(Type.resolveClass(_soundName)); } catch (e : Dynamic) { classRef = null; }
            if (classRef != null) s = try cast(Type.createInstance(classRef, []), Sound) catch (e : Dynamic) null;
        }

        if (s == null) return null;

        var def : SoundEffectDef = new SoundEffectDef();
        def.name = _soundName;
        def.looped = false;
        def.flashSound = s;
        soundDefs.push(def);
        return def;
    }

    // Resolve a game sound name to a converted OGG asset. Tries sfx/ then music/. If the exact name
    // isn't found, strips a trailing digit so variant requests fall back to the base file (the game
    // asks for e.g. "sfx_pop1".."sfx_pop3" but only sfx_pop.ogg exists). Missing sounds return null
    // and play silently, exactly as the original engine tolerated.
    static function LoadSoundByName(name : String) : Sound
    {
        var path : String = FindSoundAsset(name);
        if (path == null)
        {
            var stripped : String = (~/[0-9]+$/).replace(name, "");
            if (stripped != name) path = FindSoundAsset(stripped);
        }
        if (path == null) return null;
        return try openfl.utils.Assets.getSound(path) catch (e : Dynamic) null;
    }

    static function FindSoundAsset(name : String) : String
    {
        for (folder in ["sfx", "music"])
        {
            var p : String = "assets/audio/" + folder + "/" + name + ".ogg";
            if (openfl.utils.Assets.exists(p)) return p;
        }
        return null;
    }
    
    
    public static function GetFreeActiveSound() : ActiveSoundEffectItem
    {
        for (act in activeSounds)
        {
            if (act.active == false)
            {
                act.ResetData();
                return act;
            }
        }
        return null;
    }
    
    public static function GetActiveMusic() : ActiveSoundEffectItem
    {
        for (act in activeSounds)
        {
            if (act.active && act.isMusic)
            {
                return act;
            }
        }
        return null;
    }
    
    
    public static function GetActiveSoundByName(_name : String) : ActiveSoundEffectItem
    {
        for (act in activeSounds)
        {
            if (act.active && act.name == _name)
            {
                return act;
            }
        }
        return null;
    }
    
    public static function SetSoundVolume(name : String, volume : Float)
    {
        var activeAct : ActiveSoundEffectItem = GetActiveSoundByName(name);
        if (activeAct == null)
        {
            return;
        }
        activeAct.SetVolume(volume);
    }
    
    public static function SetSoundPan(name : String, pan : Float)
    {
        var activeAct : ActiveSoundEffectItem = GetActiveSoundByName(name);
        if (activeAct == null)
        {
            return;
        }
        activeAct.SetPan(pan);
    }
    
    
    public static function SetCurrentMusicToFadeOut()
    {
        for (act in activeSounds)
        {
            if (act.active && act.isMusic)
            {
                act.StartFadeOut();
            }
        }
    }
    
    
    public static function StopMusic()
    {
        SetCurrentMusicToFadeOut();
    }
    public static function PlayMusic(name : String, volume : Float = 0.3)
    {
        if (IsMuteMusic())
        {
            return;
        }
        if (playingLocalFile)
        {
            return;
        }
        
        var def : SoundEffectDef = GetSoundDefByName(name);
        if (def == null)
        {
            return;
        }
        
        
        var activeAct : ActiveSoundEffectItem = GetActiveSoundByName(name);
        if (activeAct != null)
        {
            return;
        }
        
        SetCurrentMusicToFadeOut();
        
        var act : ActiveSoundEffectItem = GetFreeActiveSound();
        if (act != null)
        {
            var st : SoundTransform = new SoundTransform();
            st.volume = volume;
            st.pan = 0;
            var sc : SoundChannel = def.flashSound.play(0, Std.int(9999999999), st);
            act.StartMusic(name, sc);
        }
    }
    
    public static function Loop(name : String, numLoops : Int, pan : Float = 0, volume : Float = 1, unique : Bool = true)
    {
        var def : SoundEffectDef = GetSoundDefByName(name);
        
        if (unique)
        {
            var activeAct : ActiveSoundEffectItem = GetActiveSoundByName(name);
            if (activeAct != null)
            {
                return;
            }
        }
        
        var act : ActiveSoundEffectItem = GetFreeActiveSound();
        if (act != null)
        {
            var st : SoundTransform = new SoundTransform();
            st.volume = volume;
            st.pan = pan;
            var sc : SoundChannel = def.flashSound.play(0, numLoops, st);
            act.StartSFX(name, sc);
        }
    }
    
    public static function StartPitchControlSound(name : String, volume : Float = 0.3, unique : Bool = true)
    {
        var def : SoundEffectDef = GetSoundDefByName(name);
        
        if (unique)
        {
            var activeAct : ActiveSoundEffectItem = GetActiveSoundByName(name);
            if (activeAct != null)
            {
                return;
            }
        }
        
        var act : ActiveSoundEffectItem = GetFreeActiveSound();
        if (act != null)
        {
            var st : SoundTransform = new SoundTransform();
            
            act.StartPitchControlSound(name, null, volume);
            act.volume = volume;
            act.sc = null;
            st.volume = volume;
            st.pan = 0;
            act.sc.soundTransform = st;
        }
    }
    
    public static function OneShot_Random(names : Array<Dynamic>, pan : Float = 0, volume : Float = 1)
    {
        var r : Int = Utils.RandBetweenInt(0, names.length - 1);
        OneShot(names[r], pan, volume);
    }
    
    public static function OneShot(name : String, pan : Float = 0, volume : Float = 1)
    {
        if (isInitialised == false)
        {
            return;
        }
        if (IsMuteSFX())
        {
            return;
        }
        var def : SoundEffectDef = GetSoundDefByName(name);
        if (def == null)
        {
            return;
        }
        
        // Web Audio (Howler) throws on a non-finite pan/volume ("The provided float value is non-finite"),
        // unlike Flash which silently tolerated it. A NaN can arrive from SFX_OneShot when the emitter's
        // xpos (or the camera) is non-finite for a frame. Sanitize so audio can never crash the game.
        if (!Math.isFinite(pan)) pan = 0;
        if (!Math.isFinite(volume)) volume = 1;
        var st : SoundTransform = new SoundTransform();
        st.volume = volume;
        st.pan = pan;
        def.flashSound.play(0, 0, st);
    }
    
    
    public static function SetSoundPitch(name : String, pitch : Float)
    {
        for (act in activeSounds)
        {
            if (act.active && act.isPitchControl && act.name == name)
            {
                act.pitchControl.rate = pitch;
            }
        }
    }
    
    
    public static function StopSFX(name : String) : Void
    {
        var activeAct : ActiveSoundEffectItem = GetActiveSoundByName(name);
        if (activeAct == null)
        {
            return;
        }
        activeAct.Stop();
    }
    
    public static function StopAllSFX() : Void
    {
        for (act in activeSounds)
        {
            if (act.active && act.isMusic == false)
            {
                act.Stop();
            }
        }
    }
    public static function StopAllMusic() : Void
    {
        for (act in activeSounds)
        {
            if (act.active && act.isMusic)
            {
                act.Stop();
            }
        }
    }
    public static function UpdateOncePerFrame() : Void
    {
        for (act in activeSounds)
        {
            if (act.active)
            {
                act.UpdateOncePerFrame();
            }
        }
    }
    
    public static function MuteAll(_isMusic : Bool) : Void
    {
        for (act in activeSounds)
        {
            if (act.active)
            {
                if (act.isMusic == _isMusic)
                {
                    act.Mute();
                }
            }
        }
    }
    public static function UnMuteAll(_isMusic : Bool) : Void
    {
        for (act in activeSounds)
        {
            if (act.active)
            {
                if (act.isMusic == _isMusic)
                {
                    act.UnMute();
                }
            }
        }
    }
    
    
    
    public static var loadedMP3 : Sound;
    public static var loadedSoundChannel : SoundChannel;
    public static var playingLocalFileCallback : Function;
    public static var playingLocalFile : Bool;
    public static var fr : FileReference;
    
    public static function StopLocalFilePlayback()
    {
        if (playingLocalFile == false)
        {
            return;
        }
        if (loadedMP3 != null && loadedSoundChannel != null)
        {
            FlashConnect.trace("stopping local file playback");
            loadedSoundChannel.stop();
        }
    }
    
    public static function DontPlayLocalAnyMore()
    {
        StopLocalFilePlayback();
        playingLocalFile = false;
        loadedMP3 = null;
        loadedSoundChannel = null;
    }
    public static function PlayLocalFile(callback : Function)
    {
        playingLocalFileCallback = callback;
        var ff : FileFilter = new FileFilter("MP3 files", "*.mp3");
        fr = new FileReference();
        var loader : URLLoader = new URLLoader();
        fr.addEventListener(Event.SELECT, selectHandler);
        fr.addEventListener(Event.CANCEL, cancelHandler);
        fr.browse([ff]);
    }
    public static function cancelHandler(e : Event)
    {
        FlashConnect.trace("cancelled");
        if (playingLocalFileCallback != null)
        {
            playingLocalFileCallback();
        }
    }
    public static function selectHandler(e : Event)
    {
        var frl : MP3FileReferenceLoader = new MP3FileReferenceLoader();
        
        frl.addEventListener(MP3SoundEvent.COMPLETE, MP3Loaded);
        frl.getSound(fr);
    }
    public static function MP3Loaded(e : MP3SoundEvent)
    {
        StopAllMusic();
        StopLocalFilePlayback();
        
        loadedMP3 = e.sound;
        
        loadedSoundChannel = loadedMP3.play(0, 99999999);
        FlashConnect.trace("MP3Loaded");
        
        playingLocalFile = true;
        
        if (playingLocalFileCallback != null)
        {
            playingLocalFileCallback();
        }
    }
    public static function onLoadError(e : Event)
    {
        FlashConnect.trace("load error");
        if (playingLocalFileCallback != null)
        {
            playingLocalFileCallback();
        }
    }
    public static function completeHandler(e : Event)
    {
        FlashConnect.trace("complete handler");
        if (playingLocalFileCallback != null)
        {
            playingLocalFileCallback();
        }
        
        var data : ByteArray = fr.data;
        FlashConnect.trace("bytearray length " + data.length);
        StopAllMusic();
        
        var mp3 : Sound = new Sound();
        (untyped mp3).extract(data, 10000);
        mp3.play(0, 999999);
    }
}


