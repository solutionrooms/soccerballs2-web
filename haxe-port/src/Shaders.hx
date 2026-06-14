import flash.display.Shader;

/**
	 * ...
	 * @author LongAnimals
	 */
class Shaders
{
    
    @:meta(Embed(source="../bin/test.pbj",mimeType="application/octet-stream"))

    private static var MyShaderClass : Class<Dynamic>;
    
    
    public static var shader : Shader = new Shader(Type.createInstance(MyShaderClass, []));
    
    public function new()
    {
    }
}

