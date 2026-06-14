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
    private static var soundDefs : Array<SoundEffectDef>;
    private static var activeSounds : Array<ActiveSoundEffectItem>;
    
    private static var muteSFX : Bool;
    private static var muteMusic : Bool;
    
    private static var soundAllowed : Bool;
    
    private static var isInitialised : Bool = false;  // to stop button clicks etc. on preloader  
    
    
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
        
        soundDefs = new Array<SoundEffectDef>();
        activeSounds = new Array<ActiveSoundEffectItem>();
        for (i in 0...32)
        {
            activeSounds.push(new ActiveSoundEffectItem());
        }
        
        var s : Sound = new SfxClick();
        var sc : SoundChannel = s.play(0, 0, new SoundTransform(0, 0));
        if (sc == null)
        {
            soundAllowed = false;
            muteSFX = true;
            muteMusic = true;
        }
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
            cast((false), MuteAll);
        }
        else
        {
            cast((false), UnMuteAll);
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
            cast((true), MuteAll);
        }
        else
        {
            cast((true), UnMuteAll);
        }
    }
    
    
    private static function GetSoundDefByName(name : String)
    {
        for (def in soundDefs)
        {
            if (def.name == name)
            {
                return def;
            }
        }
        return cast((name), AddSound);
    }
    
    
    private static function AddSound(_soundName : String) : SoundEffectDef
    {
        var classRef : Class<Dynamic>;
        
        try
        {
            classRef = Type.getClass(Type.resolveClass(_soundName));
        }
        catch (e : Dynamic)
        {
            classRef = null;
        }
        
        if (classRef == null)
        {
            return null;
        }
        else
        {
            var s : Sound = try cast(Type.createInstance(classRef, []), Sound) catch(e:Dynamic) null;
            var def : SoundEffectDef = new SoundEffectDef();
            def.name = _soundName;
            def.looped = false;
            def.flashSound = s;
            
            soundDefs.push(def);
            return def;
        }
        return null;
    }
    
    
    private static function GetFreeActiveSound() : ActiveSoundEffectItem
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
    
    private static function GetActiveMusic() : ActiveSoundEffectItem
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
    
    
    private static function GetActiveSoundByName(_name : String) : ActiveSoundEffectItem
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
        var activeAct : ActiveSoundEffectItem = cast((name), GetActiveSoundByName);
        if (activeAct == null)
        {
            return;
        }
        activeAct.SetVolume(volume);
    }
    
    public static function SetSoundPan(name : String, pan : Float)
    {
        var activeAct : ActiveSoundEffectItem = cast((name), GetActiveSoundByName);
        if (activeAct == null)
        {
            return;
        }
        activeAct.SetPan(pan);
    }
    
    
    private static function SetCurrentMusicToFadeOut()
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
        
        var def : SoundEffectDef = cast((name), GetSoundDefByName);
        if (def == null)
        {
            return;
        }
        
        var activeAct : ActiveSoundEffectItem = cast((name), GetActiveSoundByName);
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
            var sc : SoundChannel = def.flashSound.play(0, 9999999999, st);
            act.StartMusic(name, sc);
        }
    }
    
    public static function Loop(name : String, numLoops : Int, pan : Float = 0, volume : Float = 1, unique : Bool = true)
    {
        var def : SoundEffectDef = cast((name), GetSoundDefByName);
        
        if (unique)
        {
            var activeAct : ActiveSoundEffectItem = cast((name), GetActiveSoundByName);
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
        var def : SoundEffectDef = cast((name), GetSoundDefByName);
        
        if (unique)
        {
            var activeAct : ActiveSoundEffectItem = cast((name), GetActiveSoundByName);
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
            act.sc = new SoundChannel();
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
        var def : SoundEffectDef = cast((name), GetSoundDefByName);
        if (def == null)
        {
            return;
        }
        
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
        var activeAct : ActiveSoundEffectItem = cast((name), GetActiveSoundByName);
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
    
    
    private static var loadedMP3 : Sound;
    private static var loadedSoundChannel : SoundChannel;
    private static var playingLocalFileCallback : Function;
    public static var playingLocalFile : Bool;
    private static var fr : FileReference;
    
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
        fr.browse(new Array<Dynamic>(ff));
    }
    private static function cancelHandler(e : Event)
    {
        FlashConnect.trace("cancelled");
        if (playingLocalFileCallback != null)
        {
            playingLocalFileCallback();
        }
    }
    private static function selectHandler(e : Event)
    {
        var frl : MP3FileReferenceLoader = new MP3FileReferenceLoader();
        
        frl.addEventListener(MP3SoundEvent.COMPLETE, MP3Loaded);
        frl.getSound(fr);
    }
    private static function MP3Loaded(e : MP3SoundEvent)
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
    private static function onLoadError(e : Event)
    {
        FlashConnect.trace("load error");
        if (playingLocalFileCallback != null)
        {
            playingLocalFileCallback();
        }
    }
    private static function completeHandler(e : Event)
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
        mp3.extract(data, 10000);  // data.length * 44.1);  
        mp3.play(0, 999999);
    }
}

