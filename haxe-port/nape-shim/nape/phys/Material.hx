package nape.phys;

/**
 * nape.phys.Material shim — plain value holder. The game builds these via
 * `new Material()` then sets density/dynamicFriction/rollingFriction/
 * staticFriction/elasticity (PhysObjMaterial.MakeNapeMaterial). The shim's
 * shapes read these back at finalize to feed the replica's addCircle/addPolygon
 * (which divides density by 1000 internally, matching nape).
 */
class Material {
	public var elasticity:Float;
	public var dynamicFriction:Float;
	public var staticFriction:Float;
	public var density:Float;
	public var rollingFriction:Float;

	public function new(elasticity:Float = 0.0, dynamicFriction:Float = 1.0, staticFriction:Float = 2.0, density:Float = 1, rollingFriction:Float = 0.001) {
		this.elasticity = elasticity;
		this.dynamicFriction = dynamicFriction;
		this.staticFriction = staticFriction;
		this.density = density;
		this.rollingFriction = rollingFriction;
	}

	public function copy():Material
		return new Material(elasticity, dynamicFriction, staticFriction, density, rollingFriction);
}
