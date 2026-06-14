/*** MochiServices* Class that provides API access to MochiAds Scores Service* @author Mochi Media* @version 3.0*/package mochi.as3;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;
import mochi.as3.*;

class MochiScores
{public static function onClose(args : Dynamic = null) : Void
    {
        if (args != null)
        {
            if (args.error != null)
            {
                if (args.error == true)
                {
                    if (onErrorHandler != null)
                    {
                        if (args.errorCode == null)
                        {
                            args.errorCode = "IOError";
                        }onErrorHandler(args.errorCode);MochiServices.doClose();return;
                    }
                }
            }
        }onCloseHandler();MochiServices.doClose();
    }public static var onCloseHandler : Dynamic;public static var onErrorHandler : Dynamic;private static var boardID : String;  /**         * Method: setBoardID         * Sets the name of the mode to use for categorizing submitted and displayed scores.  The board ID is assigned in the online interface.         * @param   boardID: The unique string name of the mode         */  public static function setBoardID(boardID : String) : Void
    {
        MochiScores.boardID = boardID;MochiServices.send("scores_setBoardID", {
                    boardID : boardID
                });
    }  /**         * Method: showLeaderBoard         * Displays the leaderboard GUI showing the current top scores.  The callback event is triggered when the leaderboard is closed.         * @param   options object containing variables representing the changeable parameters <see: GUI Options>         */  public static function showLeaderboard(options : Dynamic = null) : Void
    {
        if (options != null)
        {
            if (options.clip != null)
            {
                if (Std.is(options.clip, Sprite))
                {
                    MochiServices.setContainer(options.clip);
                }This is an intentional compilation error. See the README for handling the delete keyword
                delete options.clip;
            }
            else
            {
                MochiServices.setContainer();
            }MochiServices.stayOnTop();if (options.name != null)
            {
                if (Std.is(options.name, TextField))
                {
                    if (options.name.text.length > 0)
                    {
                        options.name = options.name.text;
                    }
                }
            }if (options.score != null)
            {
                if (Std.is(options.score, TextField))
                {
                    if (options.score.text.length > 0)
                    {
                        options.score = options.score.text;
                    }
                }
                else if (Std.is(options.score, MochiDigits))
                {
                    options.score = options.score.value;
                }var n : Float = as3hx.Compat.parseFloat(options.score);  // check if score is a numeric value  if (Math.isNaN(n))
                {
                    trace("ERROR: Submitted score '" + options.score + "' will be rejected, score is 'Not a Number'");
                }
                else if (n == Math.NEGATIVE_INFINITY || n == Math.POSITIVE_INFINITY)
                {
                    trace("ERROR: Submitted score '" + options.score + "' will be rejected, score is an infinite");
                }
                else
                {
                    if (Math.floor(n) != n)
                    {
                        trace("WARNING: Submitted score '" + options.score + "' will be truncated");
                    }options.score = n;
                }
            }if (options.onDisplay != null)
            {
                options.onDisplay();
            }
            else if (MochiServices.clip != null)
            {
                if (Std.is(MochiServices.clip, MovieClip))
                {
                    MochiServices.clip.stop();
                }
                else
                {
                    trace("Warning: Container is not a MovieClip, cannot call default onDisplay.");
                }
            }
        }
        else
        {
            options = { };if (Std.is(MochiServices.clip, MovieClip))
            {
                MochiServices.clip.stop();
            }
            else
            {
                trace("Warning: Container is not a MovieClip, cannot call default onDisplay.");
            }
        }if (options.onClose != null)
        {
            onCloseHandler = options.onClose;
        }
        else
        {
            onCloseHandler = function() : Void
                    {
                        if (Std.is(MochiServices.clip, MovieClip))
                        {
                            MochiServices.clip.play();
                        }
                        else
                        {
                            trace("Warning: Container is not a MovieClip, cannot call default onClose.");
                        }
                    };
        }if (options.onError != null)
        {
            onErrorHandler = options.onError;
        }
        else
        {
            onErrorHandler = null;
        }if (options.boardID == null)
        {
            if (MochiScores.boardID != null)
            {
                options.boardID = MochiScores.boardID;
            }
        }trace("[MochiScores] NOTE: Security Sandbox Violation errors below are normal");MochiServices.send("scores_showLeaderboard", {
                    options : options
                }, null, onClose);
    }  /**         * Method: closeLeaderboard         * Closes the leaderboard immediately         */  public static function closeLeaderboard() : Void
    {
        MochiServices.send("scores_closeLeaderboard");
    }  /**         * Method: getPlayerInfo         * Retrieves all persistent player data that has been saved in a SharedObject. Will send to the callback an object containing key->value pairs contained in the player cookie.         */  public static function getPlayerInfo(callbackObj : Dynamic, callbackMethod : Dynamic = null) : Void
    {
        MochiServices.send("scores_getPlayerInfo", null, callbackObj, callbackMethod);
    }  /**         * Method: submit         * Submits a score to the server using the current id and mode.         * @param   name - the string name of the user as entered or defined by MochiBridge.         * @param   score - the number representing a score.  Can be an integer or float.  If the score is time, send it in seconds - can be float         * @param   callbackObj - the object or class instance containing the callback method         * @param   callbackMethod - the string name of the method to call when the score has been sent         */  public static function submit(score : Float, name : String, callbackObj : Dynamic = null, callbackMethod : Dynamic = null) : Void
    {
        score = score;  // check if score is a numeric value  if (Math.isNaN(score))
        {
            trace("ERROR: Submitted score '" + Std.string(score) + "' will be rejected, score is 'Not a Number'");
        }
        else if (score == Math.NEGATIVE_INFINITY || score == Math.POSITIVE_INFINITY)
        {
            trace("ERROR: Submitted score '" + Std.string(score) + "' will be rejected, score is an infinite");
        }
        else
        {
            if (Math.floor(score) != score)
            {
                trace("WARNING: Submitted score '" + Std.string(score) + "' will be truncated");
            }score = score;
        }MochiServices.send("scores_submit", {
                    score : score,
                    name : name
                }, callbackObj, callbackMethod);
    }  /**         * Method: requestList         * Requests a listing from the server using the current game id and mode. Returns an array of at most 50 score objects. Will send to the callback an array of objects [{name, score, timestamp}, ...]         * @param   callbackObj the object or class instance containing the callback method         * @param   callbackMethod the string name of the method to call when the score has been sent. default: "onLoad"         */  public static function requestList(callbackObj : Dynamic, callbackMethod : Dynamic = null) : Void
    {
        MochiServices.send("scores_requestList", null, callbackObj, callbackMethod);
    }  /**         * Method: scoresArrayToObjects         * Converts the cols/rows array format retrieved from the server into an array of objects - one object for each row containing key-value pairs.         * @param   scores the scores object received from the server         * @return         */  public static function scoresArrayToObjects(scores : Dynamic) : Dynamic
    {
        var so : Dynamic = { };var i : Float;var j : Float;var o : Dynamic;var row_obj : Dynamic;for (item in Reflect.fields(scores))
        {
            if (as3hx.Compat.typeof((Reflect.field(scores, item))) == "object")
            {
                if (Reflect.field(scores, item).cols != null && Reflect.field(scores, item).rows != null)
                {
                    Reflect.setField(so, item, []);o = Reflect.field(scores, item);for (j in 0...o.rows.length)
                    {
                        row_obj = { };for (i in 0...o.cols.length)
                        {
                            Reflect.setField(row_obj, Std.string(o.cols[i]), o.rows[j][i]);
                        }Reflect.field(so, item).push(row_obj);
                    }
                }
                else
                {
                    Reflect.setField(so, item, { });for (param in Reflect.fields(Reflect.field(scores, item)))
                    {
                        Reflect.setField(Reflect.field(so, item), param, Reflect.field(Reflect.field(scores, item), param));
                    }
                }
            }
            else
            {
                Reflect.setField(so, item, Reflect.field(scores, item));
            }
        }return so;
    }

    public function new()
    {
    }
}