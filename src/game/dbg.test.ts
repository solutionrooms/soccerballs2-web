import { it } from 'vitest';
import { PhysicsWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from './gameobj';
import { LevelState } from './game-state';
import { loadLevel } from './level-loader';
import objectsJson from '../data/objects.json';
import type { GameAudio } from '../audio/audio';
import type { Atlas } from '../render/atlas';

it('debug level 29 tower', () => {
  const physics = new PhysicsWorld((objectsJson as never as {materials: never}).materials);
  const audio = { playSfx: () => {}, playMusic: () => {} } as unknown as GameAudio;
  const atlas = { frameCount: () => 8, draw: () => {} } as unknown as Atlas;
  const g: GameContext = { physics, atlas, level: new LevelState(), audio, objects: new GameObjects(),
    mouseX:0, mouseY:0, cameraX:0, cameraY:0, bounds:{left:-3000,top:-3000,right:3000,bottom:3000} };
  loadLevel(g, 28);
  const post = g.objects.list.find(o=>o.id==='uid_718240')!;
  const anchor = g.objects.list.find(o=>o.id==='uid_275277')!;
  const crate = g.objects.list.find(o=>o.type==='crateMetalSmall')!;
  console.log('post body type:', post.body?.getType(), 'anchor body type:', anchor.body?.getType(), 'anchor fixtures:', (()=>{let n=0;for(let f=anchor.body?.getFixtureList();f;f=f.getNext())n++;return n;})());
  console.log('post joints:', (()=>{let n=0;for(let je=post.body?.getJointList();je;je=je.next)n++;return n;})());
  const step = () => {
    for (const go of g.objects.list) if (go.body && go.physicsStationary) { PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir); PhysicsWorld.setVelPx(go.body,0,0); go.body.setAngularVelocity(0);}
    g.physics.step();
    for (const go of g.objects.list) if (go.body && !go.physicsStationary && go.body.isDynamic()) { const p=PhysicsWorld.getPosPx(go.body); go.xpos=p.x; go.ypos=p.y; go.dir=p.rot; }
    for (const c of g.physics.takeContacts()) { const a=c.a.owner as GameObj, b=c.b.owner as GameObj;
      if (a?.onHitFn && !a.dead) a.onHitFn(a,b,g,c.sensor); if (b?.onHitFn && !b.dead) b.onHitFn(b,a,g,c.sensor); }
    for (const go of g.objects.list) if (!go.dead && go.updateFn) go.updateFn(go,g);
    g.objects.flushAdds(); g.objects.removeDead(g.physics);
  };
  for (let i=0;i<300;i++){ step(); if(i%60===0) console.log('f'+i,'post',post.xpos|0,post.ypos|0,'rot',post.dir|0,'crate',crate.xpos|0,crate.ypos|0);}
});
