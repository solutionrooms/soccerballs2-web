  /*
MochiAds.com ActionScript 3 code, version 3.0

Flash movies should be published for Flash 9 or later.

Copyright (C) 2006-2008 Mochi Media, Inc. All rights reserved.
*/  

package mochi.as3;

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.system.Security;
import flash.display.MovieClip;
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.net.LocalConnection;

class MochiAd
{
    
    public static function getVersion() : String
    {
        return "3.0 as3";
    }
    
    public static function doOnEnterFrame(mc : MovieClip) : Void
    {
        var f : Function = function(ev : Dynamic) : Void
        {
            if (Lambda.has(mc, "onEnterFrame") && mc.onEnterFrame)
            {
                mc.onEnterFrame();
            }
            else
            {
                ev.target.removeEventListener(ev.type, arguments.callee);
            }
        }
        mc.addEventListener(Event.ENTER_FRAME, f);
    }
    
    public static function createEmptyMovieClip(parent : Dynamic, name : String, depth : Float) : MovieClip
    {
        var mc : MovieClip = new MovieClip();
        if (false && (depth != 0 && !Math.isNaN(depth)))
        {
            parent.addChildAt(mc, depth);
        }
        else
        {
            parent.addChild(mc);
        }
        Reflect.setField(parent, name, mc);
        Reflect.setField(mc, "_name", name);
        return mc;
    }
    
    public static function showPreGameAd(options : Dynamic) : Void
    /*
                This function will stop the clip, load the MochiAd in a
                centered position on the clip, and then resume the clip
                after a timeout or when this movie is loaded, whichever
                comes first.

                options:
                    An object with keys and values to pass to the server.
                    These options will be passed to MochiAd.load, but the
                    following options are unique to showPreGameAd.

                    clip is a MovieClip reference to place the ad in.
                    clip must be dynamic.

                    color is the color of the preloader bar
                    as a number (default: 0xFF8A00)

                    background is the inside color of the preloader
                    bar as a number (default: 0xFFFFC9)

                    no_bg disables the background entirely when set to true
                    (default: false)

                    outline is the outline color of the preloader
                    bar as a number (default: 0xD58B3C)
                    
                    no_progress_bar disables the ad's preload/progress bar when set to true
                    (default: false)

                    fadeout_time is the number of milliseconds to
                    fade out the ad upon completion (default: 250).

                    ad_started is the function to call when the ad
                    has started (may not get called if network down)
                    (default: function ():void { this.clip.stop() }).

                    ad_finished is the function to call when the ad
                    has finished or could not load
                    (default: function ():void { this.clip.play() }).

                    ad_failed is called if an ad can not be displayed,
                    this is usually due to the user having ad blocking
                    software installed or issues with retrieving the ad
                    over the network. If it is called, then it is called 
                    before ad_finished.
                    (default: function ():void { }).

                    ad_loaded is called just before an ad is displayed
                    with the width and height of the ad. If it is called,
                    it is called after ad_started.
                    (default: function(width:Number, height:Number):void { }).
                    
                    ad_skipped is called if the ad was skipped, this is 
                    usually due to frequency capping, or developer initiated
                    domain filtering.  If it is called, then it is called 
                    before ad_finished.
                    (default: function():void { }).
                    
                    ad_progress is called with the progress of the ad.  The
                    progress is the percent (represented from 0 to 100) of the 
                    ad show time or loading time for the host swf, whichever is more.
                    (default: function(percent:Number):void { }).                   
            */
    {
        
        var DEFAULTS : Dynamic = {
            ad_timeout : 3000,
            fadeout_time : 250,
            regpt : "o",
            method : "showPreloaderAd",
            color : 0xFF8A00,
            background : 0xFFFFC9,
            outline : 0xD58B3C,
            no_progress_bar : false,
            ad_started : function() : Void
            {
                if (Std.is(this.clip, MovieClip))
                {
                    this.clip.stop();
                }
                else
                {
                    throw new Error("MochiAd.showPreGameAd requires a clip that is a MovieClip or is an instance of a class that extends MovieClip.  If your clip is a Sprite, then you must provide custom ad_started and ad_finished handlers.");
                }
            },
            ad_finished : function() : Void
            {
                if (Std.is(this.clip, MovieClip))
                {
                    this.clip.play();
                }
                else
                {
                    throw new Error("MochiAd.showPreGameAd requires a clip that is a MovieClip or is an instance of a class that extends MovieClip.  If your clip is a Sprite, then you must provide custom ad_started and ad_finished handlers.");
                }
            },
            ad_loaded : function(width : Float, height : Float) : Void
            {
            },
            ad_failed : function() : Void
            {
                trace("[MochiAd] Couldn't load an ad, make sure your game's local security sandbox is configured for Access Network Only and that you are not using ad blocking software");
            },
            ad_skipped : function() : Void
            {
            },
            ad_progress : function(percent : Float) : Void
            {
            }
        };
        
        options = MochiAd._parseOptions(options, DEFAULTS);
        
        if ("c862232051e0a94e1c3609b3916ddb17".substr(0) == "dfeada81ac97cde83665f81c12da7def")
        {
            options.ad_started();
            var fn : Function = function() : Void
            {
                options.ad_finished();
            }
            as3hx.Compat.setTimeout(fn, 100);
            return;
        }
        
        var clip : Dynamic = options.clip;
        var ad_msec : Float = 11000;
        var ad_timeout : Float = options.ad_timeout;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.ad_timeout;
        var fadeout_time : Float = options.fadeout_time;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.fadeout_time  /* Load targeting under clip._mochiad */  ;
        
        
        
        
        if (!MochiAd.load(options))
        {
            options.ad_failed();
            options.ad_finished();
            return;
        }
        
        options.ad_started();
        
        var mc : MovieClip = clip._mochiad;
        Reflect.setField(mc, "onUnload", function() : Void
        {
            MochiAd._cleanup(mc);
            var fn : Function = function() : Void
            {
                options.ad_finished();
            }
            as3hx.Compat.setTimeout(fn, 100);
        }  /* Center the clip */  );
        
        
        
        var wh : Array<Dynamic> = MochiAd._getRes(options, clip);
        
        var w : Float = wh[0];
        var h : Float = wh[1];
        mc.x = w * 0.5;
        mc.y = h * 0.5;
        
        var chk : MovieClip = createEmptyMovieClip(mc, "_mochiad_wait", 3);
        chk.x = w * -0.5;
        chk.y = h * -0.5;
        
        var bar : MovieClip = createEmptyMovieClip(chk, "_mochiad_bar", 4);
        if (options.no_progress_bar)
        {
            bar.visible = false;
            This is an intentional compilation error. See the README for handling the delete keyword
            delete options.no_progress_bar;
        }
        else
        {
            bar.x = 10;
            bar.y = h - 20;
        }
        
        var bar_color : Float = options.color;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.color;
        var bar_background : Float = options.background;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.background;
        var bar_outline : Float = options.outline;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.outline;
        
        var backing_mc : MovieClip = createEmptyMovieClip(bar, "_outline", 1);
        var backing : Dynamic = backing_mc.graphics;
        
        backing.beginFill(bar_background);
        backing.moveTo(0, 0);
        backing.lineTo(w - 20, 0);
        backing.lineTo(w - 20, 10);
        backing.lineTo(0, 10);
        backing.lineTo(0, 0);
        backing.endFill();
        
        var inside_mc : MovieClip = createEmptyMovieClip(bar, "_inside", 2);
        var inside : Dynamic = inside_mc.graphics;
        inside.beginFill(bar_color);
        inside.moveTo(0, 0);
        inside.lineTo(w - 20, 0);
        inside.lineTo(w - 20, 10);
        inside.lineTo(0, 10);
        inside.lineTo(0, 0);
        inside.endFill();
        inside_mc.scaleX = 0;
        
        var outline_mc : MovieClip = createEmptyMovieClip(bar, "_outline", 3);
        var outline : Dynamic = outline_mc.graphics;
        outline.lineStyle(0, bar_outline, 100);
        outline.moveTo(0, 0);
        outline.lineTo(w - 20, 0);
        outline.lineTo(w - 20, 10);
        outline.lineTo(0, 10);
        outline.lineTo(0, 0);
        
        chk.ad_msec = ad_msec;
        chk.ad_timeout = ad_timeout;
        chk.started = Math.round(haxe.Timer.stamp() * 1000);
        chk.showing = false;
        chk.last_pcnt = 0.0;
        chk.fadeout_time = fadeout_time;
        
        chk.fadeFunction = function() : Void
                {
                    var p : Float = 100 * (1 -
                    ((Math.round(haxe.Timer.stamp() * 1000) - this.fadeout_start) / this.fadeout_time));
                    
                    if (p > 0)
                    {
                        this.parent.alpha = p * 0.01;
                    }
                    else
                    {
                        MochiAd.unload(clip);
                        ;
                    }
                };
        
        var complete : Bool = false;
        var unloaded : Bool = false;
        
        var f : Function = function(ev : Event) : Void
        {
            ev.target.removeEventListener(ev.type, arguments.callee);
            complete = true;
            
            if (unloaded)
            {
                MochiAd.unload(clip);
            }
        }
        clip.loaderInfo.addEventListener(Event.COMPLETE, f);
        
        if (Std.is(clip.root, MovieClip))
        {
            var r : MovieClip = try cast(clip.root, MovieClip) catch(e:Dynamic) null;
            if (r.framesLoaded >= r.totalFrames)
            {
                complete = true;
            }
        }
        
        mc.unloadAd = function() : Void
                {
                    unloaded = true;
                    if (complete)
                    {
                        MochiAd.unload(clip);
                    }
                };
        
        mc.adLoaded = options.ad_loaded;
        mc.adSkipped = options.ad_skipped;
        mc.adjustProgress = function(msec : Float) : Void
                {
                    var _chk : Dynamic = mc._mochiad_wait;
                    _chk.server_control = true;
                    _chk.showing = true;
                    _chk.started = Math.round(haxe.Timer.stamp() * 1000);
                    _chk.ad_msec = msec;
                };
        mc.rpc = function(callbackID : Float, arg : Dynamic) : Void
                {
                    MochiAd.rpc(clip, callbackID, arg);
                };
        mc.rpcTestFn = function(s : String) : Dynamic
                {
                    trace("[MOCHIAD rpcTestFn] " + s);
                    return s;
                };
        
        /* Container will call so we know Container LC */
        mc.regContLC = function(lc_name : String) : Void
                {
                    mc._containerLCName = lc_name;
                };
        
        /* Container will call so we can start sending host loading progress */
        var sendHostProgress : Bool = false;
        mc.sendHostLoadProgress = function(lc_name : String) : Void
                {
                    sendHostProgress = true;
                };
        
        Reflect.setField(chk, "onEnterFrame", function() : Void
        {
            if (!this.parent || !this.parent.parent)
            {
                ;
                return;
            }
            var _clip : Dynamic = this.parent.parent.root;
            var ad_clip : Dynamic = this.parent._mochiad_ctr;
            var elapsed : Float = Math.round(haxe.Timer.stamp() * 1000) - this.started;
            var finished : Bool = false;
            var clip_total : Float = _clip.loaderInfo.bytesTotal;
            var clip_loaded : Float = _clip.loaderInfo.bytesLoaded;
            if (complete)
            {
                clip_loaded = Math.max(1, clip_loaded);
                clip_total = clip_loaded;
            }
            var clip_pcnt : Float = (100.0 * clip_loaded) / clip_total;
            var ad_pcnt : Float = (100.0 * elapsed) / chk.ad_msec;
            var _inside : Dynamic = this._mochiad_bar._inside;
            var pcnt : Float = Math.min(100.0, Math.min(clip_pcnt || 0.0, ad_pcnt));
            pcnt = Math.max(this.last_pcnt, pcnt);
            this.last_pcnt = pcnt;
            _inside.scaleX = pcnt * 0.01;
            
            options.ad_progress(pcnt);
            
            /* Send to our targetting SWF percent of host loaded.  
               This is so we can notify the AD SWF when we're loaded.
            */
            if (sendHostProgress)
            {
                clip._mochiad.lc.send(clip._mochiad._containerLCName, "notify", {
                            id : "hostLoadPcnt",
                            pcnt : clip_pcnt
                        });
                if (clip_pcnt == 100)
                {
                    sendHostProgress = false;
                }
            }
            
            if (!chk.showing)
            {
                var total : Float = this.parent._mochiad_ctr.contentLoaderInfo.bytesTotal;
                if (total > 0)
                {
                    chk.showing = true;
                    chk.started = Math.round(haxe.Timer.stamp() * 1000);
                    MochiAd.adShowing(clip);
                }
                else if (elapsed > chk.ad_timeout && clip_pcnt == 100)
                {
                    options.ad_failed();
                    finished = true;
                }
            }
            
            if (elapsed > chk.ad_msec)
            {
                finished = true;
            }
            
            if (complete && finished)
            {
                if (this.server_control)
                {
                    This is an intentional compilation error. See the README for handling the delete keyword
                    delete this.onEnterFrame;
                }
                else
                {
                    this.fadeout_start = Math.round(haxe.Timer.stamp() * 1000);
                    this.onEnterFrame = chk.fadeFunction;
                }
            }
        });
        doOnEnterFrame(chk);
    }
    
    
    public static function showClickAwayAd(options : Dynamic) : Void
    /*
                This function will load a MochiAd in the upper left position on the clip.
                This ad will remain there until unload() is called.

                options:
                    An object with keys and values to pass to the server.
                    These options will be passed to MochiAd.load, but the
                    following options are unique to showClickAwayAd.

                    clip is a MovieClip reference to place the ad in.

                    ad_started is the function to call when the ad
                    has started (may not get called if network down)
                    (default: function ():void { this.clip.stop() }).

                    ad_finished is the function to call when the ad
                    has finished or could not load
                    (default: function ():void { this.clip.play() }).

                    ad_failed is called if an ad can not be displayed,
                    this is usually due to the user having ad blocking
                    software installed or issues with retrieving the ad
                    over the network. If it is called, then it is called 
                    before ad_finished.
                    (default: function ():void { }).

                    ad_loaded is called just before an ad is displayed
                    with the width and height of the ad. If it is called,
                    it is called after ad_started.
                    (default: function(width:Number, height:Number):void { }).
                    
                    ad_skipped is called if the ad was skipped, this is 
                    usually due to frequency capping, or developer initiated
                    domain filtering.  If it is called, then it is called 
                    before ad_finished.
                    (default: function():void { })
            */
    {
        
        var DEFAULTS : Dynamic = {
            ad_timeout : 2000,
            regpt : "o",
            method : "showClickAwayAd",
            res : "300x250",
            no_bg : true,
            ad_started : function() : Void
            {
            },
            ad_finished : function() : Void
            {
            },
            ad_loaded : function(width : Float, height : Float) : Void
            {
            },
            ad_failed : function() : Void
            {
                trace("[MochiAd] Couldn't load an ad, make sure your game's local security sandbox is configured for Access Network Only and that you are not using ad blocking software");
            },
            ad_skipped : function() : Void
            {
            }
        };
        options = MochiAd._parseOptions(options, DEFAULTS);
        
        var clip : Dynamic = options.clip;
        var ad_timeout : Float = options.ad_timeout;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.ad_timeout  /* Load targeting under clip._mochiad */  ;
        
        
        
        if (!MochiAd.load(options))
        {
            options.ad_failed();
            options.ad_finished();
            return;
        }
        
        options.ad_started();
        
        var mc : MovieClip = clip._mochiad;
        Reflect.setField(mc, "onUnload", function() : Void
        {
            MochiAd._cleanup(mc);
            options.ad_finished();
        }  /* Peg the 300x250 ad to the upper left of the MC */  );
        
        
        
        var wh : Array<Dynamic> = MochiAd._getRes(options, clip);
        
        var w : Float = wh[0];
        var h : Float = wh[1];
        mc.x = w * 0.5;
        mc.y = h * 0.5;
        
        var chk : MovieClip = createEmptyMovieClip(mc, "_mochiad_wait", 3);
        chk.ad_timeout = ad_timeout;
        chk.started = Math.round(haxe.Timer.stamp() * 1000);
        chk.showing = false;
        
        mc.unloadAd = function() : Void
                {
                    MochiAd.unload(clip);
                };
        
        mc.adLoaded = options.ad_loaded;
        mc.adSkipped = options.ad_skipped;
        mc.rpc = function(callbackID : Float, arg : Dynamic) : Void
                {
                    MochiAd.rpc(clip, callbackID, arg);
                };
        
        /* Container will call so we register LC name */
        var sendHostProgress : Bool = false;
        mc.regContLC = function(lc_name : String) : Void
                {
                    mc._containerLCName = lc_name;
                };
        
        Reflect.setField(chk, "onEnterFrame", function() : Void
        {
            if (!this.parent)
            {
                This is an intentional compilation error. See the README for handling the delete keyword
                delete this.onEnterFrame;
                return;
            }
            var ad_clip : Dynamic = this.parent._mochiad_ctr;
            var elapsed : Float = Math.round(haxe.Timer.stamp() * 1000) - this.started;
            var finished : Bool = false;
            
            if (!chk.showing)
            {
                var total : Float = this.parent._mochiad_ctr.contentLoaderInfo.bytesTotal;
                if (total > 0)
                {
                    chk.showing = true;
                    finished = true;
                    chk.started = Math.round(haxe.Timer.stamp() * 1000);
                }
                else if (elapsed > chk.ad_timeout)
                {
                    options.ad_failed();
                    finished = true;
                }
            }
            
            /* Poll to see if we're not being displayed anymore */
            if (this.root == null)
            {
                finished = true;
            }
            
            /* Ad is showing, remove this function */
            if (finished)
            {
                This is an intentional compilation error. See the README for handling the delete keyword
                delete this.onEnterFrame;
            }
        });
        doOnEnterFrame(chk);
    }
    
    
    public static function showInterLevelAd(options : Dynamic) : Void
    /*
                This function will stop the clip, load the MochiAd in a
                centered position on the clip, and then resume the clip
                after a timeout.

                options:
                    An object with keys and values to pass to the server.
                    These options will be passed to MochiAd.load, but the
                    following options are unique to showInterLevelAd.

                    clip is a MovieClip reference to place the ad in.

                    fadeout_time is the number of milliseconds to
                    fade out the ad upon completion (default: 250).

                    ad_started is the function to call when the ad
                    has started (may not get called if network down)
                    (default: function ():void { this.clip.stop() }).

                    ad_finished is the function to call when the ad
                    has finished or could not load
                    (default: function ():void { this.clip.play() }).

                    ad_failed is called if an ad can not be displayed,
                    this is usually due to the user having ad blocking
                    software installed or issues with retrieving the ad
                    over the network. If it is called, then it is called 
                    before ad_finished.
                    (default: function ():void { }).

                    ad_loaded is called just before an ad is displayed
                    with the width and height of the ad. If it is called,
                    it is called after ad_started.
                    (default: function(width:Number, height:Number):void { }).
                    
                    ad_skipped is called if the ad was skipped, this is 
                    usually due to frequency capping, or developer initiated
                    domain filtering.  If it is called, then it is called 
                    before ad_finished.
                    (default: function():void { })
            */
    {
        
        var DEFAULTS : Dynamic = {
            ad_timeout : 2000,
            fadeout_time : 250,
            regpt : "o",
            method : "showTimedAd",
            ad_started : function() : Void
            {
                if (Std.is(this.clip, MovieClip))
                {
                    this.clip.stop();
                }
                else
                {
                    throw new Error("MochiAd.showInterLevelAd requires a clip that is a MovieClip or is an instance of a class that extends MovieClip.  If your clip is a Sprite, then you must provide custom ad_started and ad_finished handlers.");
                }
            },
            ad_finished : function() : Void
            {
                if (Std.is(this.clip, MovieClip))
                {
                    this.clip.play();
                }
                else
                {
                    throw new Error("MochiAd.showInterLevelAd requires a clip that is a MovieClip or is an instance of a class that extends MovieClip.  If your clip is a Sprite, then you must provide custom ad_started and ad_finished handlers.");
                }
            },
            ad_loaded : function(width : Float, height : Float) : Void
            {
            },
            ad_failed : function() : Void
            {
                trace("[MochiAd] Couldn't load an ad, make sure your game's local security sandbox is configured for Access Network Only and that you are not using ad blocking software");
            },
            ad_skipped : function() : Void
            {
            }
        };
        options = MochiAd._parseOptions(options, DEFAULTS);
        
        var clip : Dynamic = options.clip;
        var ad_msec : Float = 11000;
        var ad_timeout : Float = options.ad_timeout;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.ad_timeout;
        var fadeout_time : Float = options.fadeout_time;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.fadeout_time  /* Load targeting under clip._mochiad */  ;
        
        
        
        if (!MochiAd.load(options))
        {
            options.ad_failed();
            options.ad_finished();
            return;
        }
        
        options.ad_started();
        
        var mc : MovieClip = clip._mochiad;
        Reflect.setField(mc, "onUnload", function() : Void
        {
            MochiAd._cleanup(mc);
            options.ad_finished();
        }  /* Center the clip */  );
        
        
        
        
        var wh : Array<Dynamic> = MochiAd._getRes(options, clip);
        var w : Float = wh[0];
        var h : Float = wh[1];
        mc.x = w * 0.5;
        mc.y = h * 0.5;
        
        var chk : MovieClip = createEmptyMovieClip(mc, "_mochiad_wait", 3);
        chk.ad_msec = ad_msec;
        chk.ad_timeout = ad_timeout;
        chk.started = Math.round(haxe.Timer.stamp() * 1000);
        chk.showing = false;
        chk.fadeout_time = fadeout_time;
        chk.fadeFunction = function() : Void
                {
                    if (!this.parent)
                    {
                        This is an intentional compilation error. See the README for handling the delete keyword
                        delete this.onEnterFrame;
                        This is an intentional compilation error. See the README for handling the delete keyword
                        delete this.fadeFunction;
                        return;
                    }
                    var p : Float = 100 * (1 -
                    ((Math.round(haxe.Timer.stamp() * 1000) - this.fadeout_start) / this.fadeout_time));
                    if (p > 0)
                    {
                        this.parent.alpha = p * 0.01;
                    }
                    else
                    {
                        MochiAd.unload(clip);
                        ;
                    }
                };
        
        mc.unloadAd = function() : Void
                {
                    MochiAd.unload(clip);
                };
        
        mc.adLoaded = options.ad_loaded;
        mc.adSkipped = options.ad_skipped;
        mc.adjustProgress = function(msec : Float) : Void
                {
                    var _chk : Dynamic = mc._mochiad_wait;
                    _chk.server_control = true;
                    _chk.showing = true;
                    _chk.started = Math.round(haxe.Timer.stamp() * 1000);
                    _chk.ad_msec = msec - 250;
                };
        mc.rpc = function(callbackID : Float, arg : Dynamic) : Void
                {
                    MochiAd.rpc(clip, callbackID, arg);
                };
        
        Reflect.setField(chk, "onEnterFrame", function() : Void
        {
            if (!this.parent)
            {
                This is an intentional compilation error. See the README for handling the delete keyword
                delete this.onEnterFrame;
                This is an intentional compilation error. See the README for handling the delete keyword
                delete this.fadeFunction;
                return;
            }
            var ad_clip : Dynamic = this.parent._mochiad_ctr;
            var elapsed : Float = Math.round(haxe.Timer.stamp() * 1000) - this.started;
            var finished : Bool = false;
            
            if (!chk.showing)
            {
                var total : Float = this.parent._mochiad_ctr.contentLoaderInfo.bytesTotal;
                if (total > 0)
                {
                    chk.showing = true;
                    chk.started = Math.round(haxe.Timer.stamp() * 1000);
                    MochiAd.adShowing(clip);
                }
                else if (elapsed > chk.ad_timeout)
                {
                    options.ad_failed();
                    finished = true;
                }
            }
            
            if (elapsed > chk.ad_msec)
            {
                finished = true;
            }
            if (finished)
            {
                if (this.server_control)
                {
                    This is an intentional compilation error. See the README for handling the delete keyword
                    delete this.onEnterFrame;
                }
                else
                {
                    this.fadeout_start = Math.round(haxe.Timer.stamp() * 1000);
                    this.onEnterFrame = this.fadeFunction;
                }
            }
        });
        doOnEnterFrame(chk);
    }
    
    public static function showPreloaderAd(options : Dynamic) : Void
    /* Compatibility stub for MochiAd 1.5 terminology */
    {
        
        trace("[MochiAd] DEPRECATED: showPreloaderAd was renamed to showPreGameAd in 2.0");
        MochiAd.showPreGameAd(options);
    }
    
    public static function showTimedAd(options : Dynamic) : Void
    /* Compatibility stub for MochiAd 1.5 terminology */
    {
        
        trace("[MochiAd] DEPRECATED: showTimedAd was renamed to showInterLevelAd in 2.0");
        MochiAd.showInterLevelAd(options);
    }
    
    public static function _allowDomains(server : String) : String
    {
        var hostname : String = server.split("/")[2].split(":")[0];
        
        if (flash.system.Security.sandboxType == "application")
        {
            return hostname;
        }
        
        flash.system.Security.allowDomain("*");
        flash.system.Security.allowDomain(hostname);
        flash.system.Security.allowInsecureDomain("*");
        flash.system.Security.allowInsecureDomain(hostname);
        return hostname;
    }
    
    public static function load(options : Dynamic) : MovieClip
    /*
                Load a MochiAd into the given MovieClip
            
                options:
                    An object with keys and values to pass to the server.

                    clip is a MovieClip reference to place the ad in.

                    id should be the unique identifier for this MochiAd.

                    server is the base URL to the MochiAd server.

                    res is the resolution of the container clip or movie
                    as a string, e.g. "500x500"
            */
    {
        
        var DEFAULTS : Dynamic = {
            server : "http://x.mochiads.com/srv/1/",
            method : "load",
            depth : 10333,
            id : "_UNKNOWN_"
        };
        options = MochiAd._parseOptions(options, DEFAULTS);
        options.swfv = 9;
        options.mav = MochiAd.getVersion();
        
        var clip : Dynamic = options.clip;
        
        if (!MochiAd._isNetworkAvailable())
        {
            return null;
        }
        
        try
        {
            if (clip._mochiad_loaded)
            {
                return null;
            }
        }
        catch (e : Error)
        {
            throw new Error("MochiAd requires a clip that is an instance of a dynamic class.  If your class extends Sprite or MovieClip, you must make it dynamic.");
        }
        
        var depth : Float = options.depth;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.depth;
        var mc : MovieClip = createEmptyMovieClip(clip, "_mochiad", depth);
        
        var wh : Array<Dynamic> = MochiAd._getRes(options, clip);
        options.res = wh[0] + "x" + wh[1];
        
        options.server += options.id;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete options.id;
        
        clip._mochiad_loaded = true;
        
        if (clip.loaderInfo.loaderURL.indexOf("http") == 0)
        {
            options.as3_swf = clip.loaderInfo.loaderURL;
        }
        else
        {
            trace("[MochiAd] NOTE: Security Sandbox Violation errors below are normal");
        }
        
        var lv : URLVariables = new URLVariables();
        for (k in Reflect.fields(options))
        {
            var v : Dynamic = Reflect.field(options, k);
            if (!(Std.is(v, Function)))
            {
                Reflect.setField(lv, k, v);
            }
        }
        
        var server : String = lv.server;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete lv.server;
        var hostname : String = _allowDomains(server);
        
        /* Set up LocalConnection recieve between here and targetting swf */
        var lc : LocalConnection = new LocalConnection();
        /* Make callbacks operate on targetting swf container */
        lc.client = mc;
        var name : String = [
                "", Math.floor((Date.now()).getTime()), Math.floor(Math.random() * 999999)
        ].join("_");
        lc.allowDomain("*", "localhost");
        lc.allowInsecureDomain("*", "localhost");
        lc.connect(name);
        mc.lc = lc;
        mc.lcName = name;
        /* register our LocalConnection name with targetting swf */
        lv.lc = name;
        
        lv.st = Math.round(haxe.Timer.stamp() * 1000);
        var loader : Loader = new Loader();
        
        var g : Function = function(ev : Dynamic) : Void
        {
            ev.target.removeEventListener(ev.type, arguments.callee);
            MochiAd.unload(clip);
        }
        loader.contentLoaderInfo.addEventListener(Event.UNLOAD, g);
        
        var req : URLRequest = new URLRequest(server + ".swf?cacheBust=" + Date.now().getTime());
        req.contentType = "application/x-www-form-urlencoded";
        req.method = URLRequestMethod.POST;
        req.data = lv;
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(io : IOErrorEvent) : Void
                {
                    trace("[MochiAds] Blocked URL");
                });
        loader.load(req);
        mc.addChild(loader);
        /* load targetting swf */
        mc._mochiad_ctr = loader;
        
        return mc;
    }
    
    public static function unload(clip : Dynamic) : Bool
    /*
                Unload a MochiAd from the given MovieClip
            
                    clip:
                        a MovieClip reference (e.g. this.stage)
            */
    {
        
        if (clip.clip && clip.clip._mochiad)
        {
            clip = clip.clip;
        }
        
        if (clip.origFrameRate != null)
        {
            clip.stage.frameRate = clip.origFrameRate;
        }
        
        if (!clip._mochiad)
        {
            return false;
        }
        if (clip._mochiad._containerLCName != null)
        {
            clip._mochiad.lc.send(clip._mochiad._containerLCName, "notify", {
                        id : "unload"
                    });
        }
        
        if (clip._mochiad.onUnload)
        {
            clip._mochiad.onUnload();
        }
        This is an intentional compilation error. See the README for handling the delete keyword
        delete clip._mochiad_loaded;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete clip._mochiad;
        return true;
    }
    
    public static function _cleanup(mc : Dynamic) : Void
    {
        if (Lambda.has(mc, "lc"))
        {
            var lc : LocalConnection = mc.lc;
            var f : Function = function() : Void
            {
                try
                {
                    lc.client = null;
                    lc.close();
                }
                catch (e : Error)
                {
                }
            }
            as3hx.Compat.setTimeout(f, 0);
        }
        var idx : Float = cast((mc), DisplayObjectContainer).numChildren;
        while (idx > 0)
        {
            idx -= 1;
            cast((mc), DisplayObjectContainer).removeChildAt(idx);
        }
        for (k in Reflect.fields(mc))
        {
            Reflect.deleteField(mc, k);
        }
    }
    
    public static function _isNetworkAvailable() : Bool
    {
        return Security.sandboxType != "localWithFile";
    }
    
    public static function _getRes(options : Dynamic, clip : Dynamic) : Array<Dynamic>
    {
        var b : Dynamic = clip.getBounds(clip.root);
        var w : Float = 0;
        var h : Float = 0;
        if (as3hx.Compat.typeof((options.res)) != "undefined")
        {
            var xy : Array<Dynamic> = options.res.split("x");
            w = as3hx.Compat.parseFloat(xy[0]);
            h = as3hx.Compat.parseFloat(xy[1]);
        }
        else
        {
            w = b.xMax - b.xMin;
            h = b.yMax - b.yMin;
        }
        if (w == 0 || h == 0)
        {
            w = clip.stage.stageWidth;
            h = clip.stage.stageHeight;
        }
        
        
        return [w, h];
    }
    
    public static function _parseOptions(options : Dynamic, defaults : Dynamic) : Dynamic
    {
        var optcopy : Dynamic = { };
        var k : String;
        for (k in Reflect.fields(defaults))
        {
            Reflect.setField(optcopy, k, Reflect.field(defaults, k));
        }
        if (options != null)
        {
            for (k in Reflect.fields(options))
            {
                Reflect.setField(optcopy, k, Reflect.field(options, k));
            }
        }
        if (optcopy.clip == null)
        {
            throw new Error("MochiAd is missing the 'clip' parameter.  This should be a MovieClip, Sprite or an instance of a class that extends MovieClip or Sprite.");
        }
        options = optcopy.clip.loaderInfo.parameters.mochiad_options;
        if (options != null)
        {
            var pairs : Array<Dynamic> = options.split("&");
            for (i in 0...pairs.length)
            {
                var kv : Array<Dynamic> = pairs[i].split("=");
                Reflect.setField(optcopy, Std.string(unescape(kv[0])), unescape(kv[1]));
            }
        }
        if (optcopy.id == "test")
        {
            trace("[MochiAd] WARNING: Using the MochiAds test identifier, make sure to use the code from your dashboard, not this example!");
        }
        return optcopy;
    }
    
    public static function rpc(clip : Dynamic, callbackID : Float, arg : Dynamic) : Void
    {
        var _sw0_ = (arg.id);        

        switch (_sw0_)
        {
            case "setValue":
                MochiAd.setValue(clip, arg.objectName, arg.value);
            case "getValue":
                var val : Dynamic = MochiAd.getValue(clip, arg.objectName);
                clip._mochiad.lc.send(clip._mochiad._containerLCName, "rpcResult", callbackID, val);
            case "runMethod":
                var ret : Dynamic = MochiAd.runMethod(clip, arg.method, arg.args);
                clip._mochiad.lc.send(clip._mochiad._containerLCName, "rpcResult", callbackID, ret);
            default:
                trace("[mochiads rpc] unknown rpc id: " + arg.id);
        }
    }
    
    public static function setValue(base : Dynamic, objectName : String, value : Dynamic) : Void
    {
        var nameArray : Array<Dynamic> = objectName.split(".");
        
        for (i in 0...nameArray.length - 1)
        {
            if (Reflect.field(base, Std.string(nameArray[i])) == null || Reflect.field(base, Std.string(nameArray[i])) == null)
            {
                return;
            }
            base = Reflect.field(base, Std.string(nameArray[i]));
        }
        
        Reflect.setField(base, Std.string(nameArray[i]), value);
    }
    
    public static function getValue(base : Dynamic, objectName : String) : Dynamic
    {
        var nameArray : Array<Dynamic> = objectName.split(".");
        
        for (i in 0...nameArray.length - 1)
        {
            if (Reflect.field(base, Std.string(nameArray[i])) == null || Reflect.field(base, Std.string(nameArray[i])) == null)
            {
                return null;
            }
            base = Reflect.field(base, Std.string(nameArray[i]));
        }
        
        return Reflect.field(base, Std.string(nameArray[i]));
    }
    
    public static function runMethod(base : Dynamic, methodName : String, argsArray : Array<Dynamic>) : Dynamic
    {
        var nameArray : Array<Dynamic> = methodName.split(".");
        
        for (i in 0...nameArray.length - 1)
        {
            if (Reflect.field(base, Std.string(nameArray[i])) == null || Reflect.field(base, Std.string(nameArray[i])) == null)
            {
                return null;
            }
            base = Reflect.field(base, Std.string(nameArray[i]));
        }
        
        if (as3hx.Compat.typeof((Reflect.field(base, Std.string(nameArray[i])))) == "function")
        {
            return Reflect.field(base, Std.string(nameArray[i])).apply(base, argsArray);
        }
        else
        {
            return null;
        }
    }
    
    public static function adShowing(mc : Dynamic) : Void
    {
        mc.origFrameRate = mc.stage.frameRate;
        mc.stage.frameRate = 30;
    }

    public function new()
    {
    }
}

