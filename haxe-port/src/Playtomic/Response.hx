package playtomic;

class Response extends Dynamic
{
    public var ErrorMessage(get, never) : String;
private static var ERRORS : Dynamic = {};  // General Errors    // GeoIP Errors    // Leaderboard Errors    // GameVars Errors    // LevelSharing Errors    // Playtomic+Parse.com Errors  public var Success : Bool = false;public var ErrorCode : Int = 0;  /**		 * Creates a response		 * @param	status		The status returned from the server		 * @param	errorcode	The errorcode returned from the server		 */  public function new(status : Int, errorcode : Int)
    {
        super();Success = status == 1;ErrorCode = errorcode;
    }  /**		 * Returns the error message for a number		 */  private function get_ErrorMessage() : String
    {
        return Reflect.field(ERRORS, Std.string(ErrorCode));
    }public function toString() : String
    {
        return "Playtomic.Response:" + "\nSuccess: " + Success + "\nErrorCode: " + ErrorCode + "\nErrorMessage: " + ErrorMessage;
    }
    private static var Response_static_initializer = {
        Reflect.setField(ERRORS, Std.string(0), "Nothing went wrong!");
        Reflect.setField(ERRORS, Std.string(1), "General error, this typically means the player is unable to connect to the Playtomic servers");
        Reflect.setField(ERRORS, Std.string(2), "Invalid game credentials. Make sure you use your SWFID and GUID from the `API` section in the dashboard.");
        Reflect.setField(ERRORS, Std.string(3), "Request timed out.");
        Reflect.setField(ERRORS, Std.string(4), "Invalid request.");
        Reflect.setField(ERRORS, Std.string(100), "GeoIP API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.");
        Reflect.setField(ERRORS, Std.string(200), "Leaderboard API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.");
        Reflect.setField(ERRORS, Std.string(201), "The source URL or name weren't provided when saving a score. Make sure the player specifies a name and the game is initialized before anything else using the code in the `Set your game up` section.");
        Reflect.setField(ERRORS, Std.string(202), "Invalid auth key. You should not see this normally, players might if they tamper with your game.");
        Reflect.setField(ERRORS, Std.string(203), "No Facebook user id on a score specified as a Facebook submission.");
        Reflect.setField(ERRORS, Std.string(204), "Table name wasn't specified for creating a private leaderboard.");
        Reflect.setField(ERRORS, Std.string(205), "Permalink structure wasn't specified: http://website.com/game/whatever?leaderboard=");
        Reflect.setField(ERRORS, Std.string(206), "Leaderboard id wasn't provided loading a private leaderboard.");
        Reflect.setField(ERRORS, Std.string(207), "Invalid leaderboard id was provided for a private leaderboard.");
        Reflect.setField(ERRORS, Std.string(208), "Player is banned from submitting scores in your game.");
        Reflect.setField(ERRORS, Std.string(209), "Score was not the player's best score.  You can notify the player, or circumvent this by pecifying 'allowduplicates' to be true in your save options.");
        Reflect.setField(ERRORS, Std.string(300), "GameVars API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.");
        Reflect.setField(ERRORS, Std.string(400), "Level sharing API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.");
        Reflect.setField(ERRORS, Std.string(401), "Invalid rating value (must be 1 - 10).");
        Reflect.setField(ERRORS, Std.string(402), "Player has already rated that level.");
        Reflect.setField(ERRORS, Std.string(403), "The level name wasn't provided when saving a level.");
        Reflect.setField(ERRORS, Std.string(404), "Invalid image auth. You should not see this normally, players might if they tamper with your game.");
        Reflect.setField(ERRORS, Std.string(405), "Invalid image auth (again). You should not see this normally, players might if they tamper with your game.");
        Reflect.setField(ERRORS, Std.string(406), "The level already exists. This is determined via a hash of the game id, level name, player ip address and name, and source url."  // Data API Errors  );
        Reflect.setField(ERRORS, Std.string(500), "Data API has been disabled. This may occur if the Data API is not enabled for your game, or your game is faulty or overwhelming the Playtomic servers.");
        Reflect.setField(ERRORS, Std.string(600), "You have not configured your Parse.com database.  Sign up at Parse and then enter your API credentials in your Playtomic dashboard.");
        Reflect.setField(ERRORS, Std.string(601), "No response was returned from Parse.  If you experience this a lot let us know exactly what you're doing so we can sort out a fix for it.");
        Reflect.setField(ERRORS, Std.string(6021), "Parse's servers had an error.");
        Reflect.setField(ERRORS, Std.string(602101), "Object not found.  Make sure you include the classname and objectid and that they are correct.");
        Reflect.setField(ERRORS, Std.string(602102), "Invalid query.  If you think you're doing it right let us know what you're doing and we'll look into it.");
        Reflect.setField(ERRORS, Std.string(602103), "Invalid classname.");
        Reflect.setField(ERRORS, Std.string(602104), "Missing objectid.");
        Reflect.setField(ERRORS, Std.string(602105), "Invalid key name.");
        Reflect.setField(ERRORS, Std.string(602106), "Invalid pointer.");
        Reflect.setField(ERRORS, Std.string(602107), "Invalid JSON.");
        Reflect.setField(ERRORS, Std.string(602108), "Command unavailable.");
        true;
    }

}