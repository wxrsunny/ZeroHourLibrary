/* Execute the same platform-free .ets modules used by the app. No copy of the game logic. */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const studio = process.env.DEVECO_STUDIO_HOME || 'D:/Harmony/DevEco Studio';
const compiler = process.env.ARKTS_TYPESCRIPT_PATH || path.join(studio, 'sdk/default/openharmony/ets/build-tools/ets-loader/node_modules/typescript');
const ts = require(compiler);
require.extensions['.ets'] = function(module, filename) {
  const output = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS }, fileName: filename.replace(/\.ets$/, '.ts')
  });
  module._compile(output.outputText, filename);
};
const root = path.join(__dirname, '../entry/src/main/ets');
const types = require(path.join(root, 'model/GameTypes.ets'));
const data = require(path.join(root, 'data/StoryData.ets'));
const world = require(path.join(root, 'logic/WorldController.ets'));
const engine = require(path.join(root, 'logic/GameEngine.ets'));
const codec = require(path.join(root, 'storage/SaveCodec.ets'));
const {SaveRepository} = require(path.join(root, 'storage/SaveRepository.ets'));
const results = [];
async function test(id, category, name, input, expected, fn) {
  try {
    const actual = await fn();
    results.push({id, category, name, input, expected, actual: actual || '断言均通过', status: 'PASS'});
    console.log(`PASS ${id} [${category}] ${name}`);
  } catch (error) {
    results.push({id, category, name, input, expected, actual: error.stack, status: 'FAIL'});
    console.error(`FAIL ${id}: ${error.message}`);
    process.exitCode = 1;
  }
}
function at(room, x, y) { const p = types.createProgress(); p.room = room; p.position = {x, y}; p.visitedRooms = room === 'foyer' ? ['foyer'] : ['foyer', room]; return p; }
class MockStorage {
  constructor() { this.value = ''; this.failRead = false; this.failWrite = false; this.writes = []; }
  async read() { if (this.failRead) throw Error('mock read failure'); return this.value; }
  async write(value) { if (this.failWrite) throw Error('mock flush failure'); this.writes.push(value); this.value = value; }
}
(async () => {
  await test('M01','正常','空地移动', '前台(160,224)向右移动4', '(164,224)，原进度未被改变', () => {
    const p=types.createProgress(); const r=world.movePlayer(p,'right',4); assert.equal(r.progress.position.x,164); assert.equal(p.position.x,160); return r.progress.position;
  });
  await test('M02','边界','障碍与墙壁阻挡', '前台(160,102)向上；(22,224)向左', '不能进入书桌或越出边界', () => {
    assert.equal(world.movePlayer(at('foyer',160,102),'up').progress.position.y,102);
    assert.equal(world.movePlayer(at('foyer',22,224),'left').progress.position.x,22);
  });
  await test('M03','异常','非法输入不移动', 'NaN、负数、过大步长、非法方向', '移动均被拒绝', () => {
    for(const step of [NaN,-1,0,100]) assert.equal(world.movePlayer(types.createProgress(),'up',step).moved,false);
    assert.equal(world.movePlayer(types.createProgress(),'diagonal',4).moved,false);
    assert.equal(world.canStand(data.getScene('foyer'),{x:NaN,y:100}),false);
  });
  await test('M04','正常','门口切换与安全出生点', '前台(282,224)向右', '进入书架区且出生点可行走', () => {
    const r=world.movePlayer(at('foyer',282,224),'right'); assert.equal(r.progress.room,'stacks'); assert(world.canStand(data.getScene('stacks'),r.progress.position)); return r.progress.room;
  });
  await test('M05','边界','资料室锁定与解锁', '阅览区(280,40)向上跨入门口', '未解锁不换房间；解锁后可进入', () => {
    const p=at('reading',280,40); assert.equal(world.movePlayer(p,'up',4).blockedDoor,true);
    p.archiveUnlocked=true; assert.equal(world.movePlayer(p,'up',4).progress.room,'archive');
  });
  await test('I01','正常','调查收集线索且不重复', '现在，前台(160,112)调查值班台两次', '只获得一条order线索', () => {
    const p=at('foyer',160,112); assert(engine.investigate(p,'counter').collected); assert.equal(engine.investigate(p,'counter').collected,false); assert.deepEqual(p.clues,['order']); return p.clues;
  });
  await test('I02','边界','调查距离阈值', '距值班台底部30与31个逻辑像素', '30可调查，31拒绝', () => {
    const p=at('foyer',160,126); assert(engine.investigate(p,'counter').collected);
    const q=at('foyer',160,127); assert.equal(engine.investigate(q,'counter').collected,false);
  });
  await test('I03','异常','无效物件与远距离调查', '出生点调查不存在物件或远处公告栏', '不修改线索', () => {
    const p=types.createProgress(); engine.investigate(p,'missing'); engine.investigate(p,'notice'); assert.equal(p.clues.length,0);
  });
  await test('I04','正常','回声决定线索可发现性', '前台(90,60)，现在与过去调查公告栏', '现在无赠书卡；过去获得donation', () => {
    const p=at('foyer',90,60); assert.equal(engine.investigate(p,'notice').collected,false); p.era='past'; assert(engine.investigate(p,'notice').collected); assert.deepEqual(p.clues,['donation']);
  });
  await test('P01','正常','密码正确解锁', '阅览区(280,48)，274', 'archiveUnlocked=true', () => {
    const p=at('reading',280,48); assert.equal(engine.submitPuzzle(p,'274'),''); assert(p.archiveUnlocked);
  });
  await test('P02','边界','不完整密码', '空串、27、2740', '不解锁，提示三位数字', () => {
    for(const code of ['', '27','2740']) { const p=at('reading',280,48); assert(engine.submitPuzzle(p,code).includes('三位')); assert(!p.archiveUnlocked); }
  });
  await test('P03','异常','错误、字符与远程提交', '000、a74，或从前台提交274', '不解锁', () => {
    for(const code of ['000','a74']) { const p=at('reading',280,48); assert.notEqual(engine.submitPuzzle(p,code),''); assert(!p.archiveUnlocked); }
    const p=types.createProgress(); assert.notEqual(engine.submitPuzzle(p,'274'),''); assert(!p.archiveUnlocked);
  });
  await test('E01','正常','两个结局分别可达', '资料室信旁，分别作出两种满足条件的选择', 'delivered与promise分别被记录', () => {
    for(const end of ['delivered','promise']) { const p=at('archive',160,164); p.archiveUnlocked=true; engine.investigate(p,'letters'); p.clues=['donation','promise']; assert.equal(engine.chooseEnding(p,end),''); assert.equal(p.ending,end); assert.deepEqual(p.unlockedEndings,[end]); }
  });
  await test('E02','异常','缺少线索或远距离不能完成隐藏结局', '读过信但无赠书卡，或离开信件旁', '拒绝推进结局', () => {
    const p=at('archive',160,164); p.archiveUnlocked=true; engine.investigate(p,'letters'); assert.notEqual(engine.chooseEnding(p,'promise'),''); assert.equal(p.ending,''); p.position={x:280,y:224}; assert.notEqual(engine.chooseEnding(p,'delivered'),'');
  });
  await test('S01','正常','进度序列化往返', '包含线索、时代、房间和结局记录的进度', '恢复字段一致', () => {
    const p=at('reading',280,48); p.clues=['order','spines']; p.era='past'; p.archiveUnlocked=true; p.unlockedEndings=['delivered']; assert.deepEqual(codec.decodeSave(codec.encodeSave(p)).progress,p);
  });
  await test('S02','边界','首次启动无存档', '空字符串', 'progress=null，无错误提示', () => { assert.deepEqual(codec.decodeSave(''),{progress:null,warning:''}); });
  await test('S03','异常','损坏或错误版本存档', '坏JSON、null、数组、版本99、字段缺失、非法线索', '拒绝恢复并给出提示', () => {
    const p=types.createProgress(); p.clues=['made-up'];
    for(const raw of ['{bad','null','[]','{"version":99}','{"version":1,"savedAt":1,"progress":{}}',codec.encodeSave(p)]) { const r=codec.decodeSave(raw); assert.equal(r.progress,null); assert(r.warning.length>0); }
  });
  await test('S04','异常','非法位置回退安全点', '坐标在墙外或书桌内', '恢复可行走坐标且给出说明', () => {
    for(const pos of [{x:-20,y:224},{x:160,y:80},{x:'bad',y:12}]) { const p=types.createProgress(); p.position=pos; const r=codec.decodeSave(codec.encodeSave(p)); assert(r.progress); assert(world.canStand(data.getScene('foyer'),r.progress.position)); assert(r.warning); }
  });
  await test('S05','异常','Mock读取与flush失败', '存储替身抛出读取、写入错误', '报告失败，不假报成功', async () => {
    const store=new MockStorage(), repo=new SaveRepository(store); store.failRead=true; assert((await repo.load()).warning); store.failWrite=true; assert.equal((await repo.save(types.createProgress())).success,false); store.failWrite=false; assert((await repo.save(types.createProgress())).success);
  });
  await test('S06','边界','顺序保存与快照隔离', '连续保存两次，中间修改角色位置', '按调用顺序写入，最终为最后进度', async () => {
    const store=new MockStorage(), repo=new SaveRepository(store), p=types.createProgress(); const first=repo.save(p); p.position.x=180; const second=repo.save(p); await Promise.all([first,second]); assert.equal(JSON.parse(store.writes[0]).progress.position.x,160); assert.equal((await repo.load()).progress.position.x,180);
  });
  await test('S07','正常','重新开始保留结局收集', '已解锁两个结局后创建新进度', '新游戏线索清空，结局收集保留且不共享数组', () => {
    const endings=['delivered','promise']; const p=types.createProgress(endings); assert.equal(p.clues.length,0); assert.deepEqual(p.unlockedEndings,endings); p.unlockedEndings.pop(); assert.equal(endings.length,2);
  });
  await test('W01','边界','每个场景出生点和入口均安全', '全部场景与门的目标出生点', '没有位于障碍中的入口', () => {
    for(const scene of data.SCENES) { assert(world.canStand(scene,scene.spawn)); for(const door of scene.doors) assert(world.canStand(data.getScene(door.target),door.spawn)); }
  });
  const summary={executedAt:new Date().toISOString(), runtime:process.version, scope:'同一份平台无关ArkTS业务模块的Node宿主测试；不等同于模拟器实测', total:results.length, passed:results.filter(r=>r.status==='PASS').length, failed:results.filter(r=>r.status==='FAIL').length, results};
  fs.mkdirSync(path.join(__dirname,'results'),{recursive:true});
  fs.writeFileSync(path.join(__dirname,'results/module-tests.json'),JSON.stringify(summary,null,2));
  console.log(`RESULT ${summary.passed}/${summary.total} passed`);
})().catch(e=>{ console.error(e); process.exitCode=1; });
