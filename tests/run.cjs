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
    results.push({id, category, name, input, expected, actual: actual || '���Ծ�ͨ��', status: 'PASS'});
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
  await test('M01','����','�յ��ƶ�', 'ǰ̨(160,224)�����ƶ�4', '(164,224)��ԭ����δ���ı�', () => {
    const p=types.createProgress(); const r=world.movePlayer(p,'right',4); assert.equal(r.progress.position.x,164); assert.equal(p.position.x,160); return r.progress.position;
  });
  await test('M02','�߽�','�ϰ���ǽ���赲', 'ǰ̨(160,102)���ϣ�(22,224)����', '���ܽ���������Խ���߽�', () => {
    assert.equal(world.movePlayer(at('foyer',160,102),'up').progress.position.y,102);
    assert.equal(world.movePlayer(at('foyer',22,224),'left').progress.position.x,22);
  });
  await test('M03','�쳣','�Ƿ����벻�ƶ�', 'NaN�����������󲽳����Ƿ�����', '�ƶ������ܾ�', () => {
    for(const step of [NaN,-1,0,100]) assert.equal(world.movePlayer(types.createProgress(),'up',step).moved,false);
    assert.equal(world.movePlayer(types.createProgress(),'diagonal',4).moved,false);
    assert.equal(world.canStand(data.getScene('foyer'),{x:NaN,y:100}),false);
  });
  await test('M04','����','�ſ��л��밲ȫ������', 'ǰ̨(282,224)����', '����������ҳ����������', () => {
    const r=world.movePlayer(at('foyer',282,224),'right'); assert.equal(r.progress.room,'stacks'); assert(world.canStand(data.getScene('stacks'),r.progress.position)); return r.progress.room;
  });
  await test('M05','�߽�','���������������', '������(280,40)���Ͽ����ſ�', 'δ�����������䣻������ɽ���', () => {
    const p=at('reading',280,40); assert.equal(world.movePlayer(p,'up',4).blockedDoor,true);
    p.archiveUnlocked=true; assert.equal(world.movePlayer(p,'up',4).progress.room,'archive');
  });
  await test('M06','�߽�','��ס���ź����Կɽ���', '��ɫλ�����ڱ߽�(280,22)������������', '������ˣ�ֱ�ӽ���������', () => {
    const p=at('reading',280,22); assert.equal(engine.submitPuzzle(p,'274'),''); assert.equal(world.movePlayer(p,'up').progress.room,'archive');
    assert.equal(world.movePlayer(p,'down').progress.room,'reading');
  });
  await test('I01','����','�����ռ������Ҳ��ظ�', '���ڣ�ǰ̨(160,112)����ֵ��̨����', 'ֻ���һ��order����', () => {
    const p=at('foyer',160,112); assert(engine.investigate(p,'counter').collected); assert.equal(engine.investigate(p,'counter').collected,false); assert.deepEqual(p.clues,['order']); return p.clues;
  });
  await test('I02','�߽�','���������ֵ', '��ֵ��̨�ײ�30��31���߼�����', '30�ɵ��飬31�ܾ�', () => {
    const p=at('foyer',160,126); assert(engine.investigate(p,'counter').collected);
    const q=at('foyer',160,127); assert.equal(engine.investigate(q,'counter').collected,false);
  });
  await test('I03','�쳣','��Ч�����Զ�������', '��������鲻���������Զ��������', '���޸�����', () => {
    const p=types.createProgress(); engine.investigate(p,'missing'); engine.investigate(p,'notice'); assert.equal(p.clues.length,0);
  });
  await test('I04','����','�������������ɷ�����', 'ǰ̨(90,60)���������ȥ���鹫����', '���������鿨����ȥ���donation', () => {
    const p=at('foyer',90,60); assert.equal(engine.investigate(p,'notice').collected,false); p.era='past'; assert(engine.investigate(p,'notice').collected); assert.deepEqual(p.clues,['donation']);
  });
  await test('P01','����','������ȷ����', '������(280,48)��274', 'archiveUnlocked=true', () => {
    const p=at('reading',280,48); assert.equal(engine.submitPuzzle(p,'274'),''); assert(p.archiveUnlocked);
  });
  await test('P02','�߽�','����������', '�մ���27��2740', '����������ʾ��λ����', () => {
    for(const code of ['', '27','2740']) { const p=at('reading',280,48); assert(engine.submitPuzzle(p,code).includes('��λ')); assert(!p.archiveUnlocked); }
  });
  await test('P03','�쳣','�����ַ���Զ���ύ', '000��a74�����ǰ̨�ύ274', '������', () => {
    for(const code of ['000','a74']) { const p=at('reading',280,48); assert.notEqual(engine.submitPuzzle(p,code),''); assert(!p.archiveUnlocked); }
    const p=types.createProgress(); assert.notEqual(engine.submitPuzzle(p,'274'),''); assert(!p.archiveUnlocked);
  });
  await test('E01','����','������ֱַ�ɴ�', '���������ԣ��ֱ�������������������ѡ��', 'delivered��promise�ֱ𱻼�¼', () => {
    for(const end of ['delivered','promise']) { const p=at('archive',160,164); p.archiveUnlocked=true; engine.investigate(p,'letters'); p.clues=['donation','promise']; assert.equal(engine.chooseEnding(p,end),''); assert.equal(p.ending,end); assert.deepEqual(p.unlockedEndings,[end]); }
  });
  await test('E02','�쳣','ȱ��������Զ���벻��������ؽ��', '�����ŵ������鿨�����뿪�ż���', '�ܾ��ƽ����', () => {
    const p=at('archive',160,164); p.archiveUnlocked=true; engine.investigate(p,'letters'); assert.notEqual(engine.chooseEnding(p,'promise'),''); assert.equal(p.ending,''); p.position={x:280,y:224}; assert.notEqual(engine.chooseEnding(p,'delivered'),'');
  });
  await test('S01','����','�������л�����', '����������ʱ��������ͽ�ּ�¼�Ľ���', '�ָ��ֶ�һ��', () => {
    const p=at('reading',280,48); p.clues=['order','spines']; p.era='past'; p.archiveUnlocked=true; p.unlockedEndings=['delivered']; assert.deepEqual(codec.decodeSave(codec.encodeSave(p)).progress,p);
  });
  await test('S02','�߽�','�״������޴浵', '���ַ���', 'progress=null���޴�����ʾ', () => { assert.deepEqual(codec.decodeSave(''),{progress:null,warning:''}); });
  await test('S03','�쳣','�𻵻����汾�浵', '��JSON��null�����顢�汾99���ֶ�ȱʧ���Ƿ�����', '�ܾ��ָ���������ʾ', () => {
    const p=types.createProgress(); p.clues=['made-up'];
    for(const raw of ['{bad','null','[]','{"version":99}','{"version":1,"savedAt":1,"progress":{}}',codec.encodeSave(p)]) { const r=codec.decodeSave(raw); assert.equal(r.progress,null); assert(r.warning.length>0); }
  });
  await test('S04','�쳣','�Ƿ�λ�û��˰�ȫ��', '������ǽ���������', '�ָ������������Ҹ���˵��', () => {
    for(const pos of [{x:-20,y:224},{x:160,y:80},{x:'bad',y:12}]) { const p=types.createProgress(); p.position=pos; const r=codec.decodeSave(codec.encodeSave(p)); assert(r.progress); assert(world.canStand(data.getScene('foyer'),r.progress.position)); assert(r.warning); }
  });
  await test('S05','�쳣','Mock��ȡ��flushʧ��', '�洢�����׳���ȡ��д�����', '����ʧ�ܣ����ٱ��ɹ�', async () => {
    const store=new MockStorage(), repo=new SaveRepository(store); store.failRead=true; assert((await repo.load()).warning); store.failWrite=true; assert.equal((await repo.save(types.createProgress())).success,false); store.failWrite=false; assert((await repo.save(types.createProgress())).success);
  });
  await test('S06','�߽�','˳�򱣴�����ո���', '�����������Σ��м��޸Ľ�ɫλ��', '������˳��д�룬����Ϊ������', async () => {
    const store=new MockStorage(), repo=new SaveRepository(store), p=types.createProgress(); const first=repo.save(p); p.position.x=180; const second=repo.save(p); await Promise.all([first,second]); assert.equal(JSON.parse(store.writes[0]).progress.position.x,160); assert.equal((await repo.load()).progress.position.x,180);
  });
  await test('S07','����','���¿�ʼ��������ռ�', '�ѽ���������ֺ󴴽��½���', '����Ϸ������գ�����ռ������Ҳ���������', () => {
    const endings=['delivered','promise']; const p=types.createProgress(endings); assert.equal(p.clues.length,0); assert.deepEqual(p.unlockedEndings,endings); p.unlockedEndings.pop(); assert.equal(endings.length,2);
  });
  await test('W01','�߽�','ÿ���������������ھ���ȫ', 'ȫ���������ŵ�Ŀ�������', 'û��λ���ϰ��е����', () => {
    for(const scene of data.SCENES) { assert(world.canStand(scene,scene.spawn)); for(const door of scene.doors) assert(world.canStand(data.getScene(door.target),door.spawn)); }
  });
  const summary={executedAt:new Date().toISOString(), runtime:process.version, scope:'ͬһ��ƽ̨�޹�ArkTSҵ��ģ���Node�������ԣ�����ͬ��ģ����ʵ��', total:results.length, passed:results.filter(r=>r.status==='PASS').length, failed:results.filter(r=>r.status==='FAIL').length, results};
  fs.mkdirSync(path.join(__dirname,'results'),{recursive:true});
  fs.writeFileSync(path.join(__dirname,'results/module-tests.json'),JSON.stringify(summary,null,2));
  console.log(`RESULT ${summary.passed}/${summary.total} passed`);
})().catch(e=>{ console.error(e); process.exitCode=1; });
