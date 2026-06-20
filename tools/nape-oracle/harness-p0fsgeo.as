package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Polygon; import nape.shape.Circle; import nape.geom.Vec2;
  import zpp_nape.space.ZPP_Space; import zpp_nape.dynamics.ZPP_ColArbiter;
  import zpp_nape.util.ZNPNode_ZPP_ColArbiter;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[P0FSG] DONE"); } catch (e:Error) { trace("[P0FSG] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray=new ByteArray();ba.writeDouble(n);ba.position=0;
      return ba.readUnsignedInt().toString(16)+":"+ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0,1000));
      var avg:Material = new Material(0.2,0.1,0.1,0.5,0.1); var fb:Material=new Material(1.0,0.1,0.1,0.5,0.1);
      var floor:Body=new Body(BodyType.STATIC,new Vec2(472,439));
      floor.shapes.add(new Polygon([new Vec2(-300,-20),new Vec2(300,-20),new Vec2(300,20),new Vec2(-300,20)],avg)); floor.space=space;
      var cys:Array=[399,360,321,284,247];
      for(var k:int=0;k<5;k++){var c:Body=new Body(BodyType.DYNAMIC,new Vec2(472,cys[k]));
        c.shapes.add(new Polygon([new Vec2(-24,-20),new Vec2(24,-20),new Vec2(24,20),new Vec2(-24,20)],avg));c.align();c.space=space;}
      var post:Body=new Body(BodyType.DYNAMIC,new Vec2(472,222));
      post.shapes.add(new Polygon([new Vec2(-6,-28),new Vec2(6,-28),new Vec2(6,28),new Vec2(-6,28)],avg));
      post.align();post.rotation=89*Math.PI/180;post.space=space;
      var bA:Body=new Body(BodyType.DYNAMIC,new Vec2(473,180));bA.shapes.add(new Circle(35,new Vec2(0,0),fb));bA.align();bA.space=space;
      var bB:Body=new Body(BodyType.DYNAMIC,new Vec2(479,108));bB.shapes.add(new Circle(35,new Vec2(0,0),fb));bB.align();bB.space=space;
      var zsp:ZPP_Space=space.zpp_inner;
      space.step(1.0/60.0,10,10); // step 1
      var n:ZNPNode_ZPP_ColArbiter=zsp.c_arbiters_false.head;
      while(n!=null){ var a:ZPP_ColArbiter=n.elt;
        var tag:String="["+Math.round(a.b1.posy)+","+Math.round(a.b2.posy)+"]";
        trace("[P0FSG] "+tag+" n "+bits(a.nx)+" "+bits(a.ny));
        trace("[P0FSG] "+tag+" oc1 "+bits(a.oc1.px)+" "+bits(a.oc1.py)+" "+bits(a.oc1.dist));
        if(a.hc2) trace("[P0FSG] "+tag+" oc2 "+bits(a.oc2.px)+" "+bits(a.oc2.py)+" "+bits(a.oc2.dist));
        n=n.next; }
    }
  }
}
