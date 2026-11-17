import { SceneDefinition, ClueDefinition, RoomId, EndingId } from '../model/GameTypes';

export const MAP_WIDTH: number = 320;
export const MAP_HEIGHT: number = 272;
export const PLAYER_RADIUS: number = 6;
export const INTERACT_DISTANCE: number = 30;
export const PUZZLE_CODE: string = '274';
export const ROOM_IDS: RoomId[] = ['foyer', 'stacks', 'reading', 'archive'];

export const CLUES: ClueDefinition[] = [
  { id: 'order', title: '值班人的便笺', location: '前台 · 现在', optional: false,
    description: '资料室的三位密码，按三本书的借阅日期从早到晚排列。数字就在对应的书脊上。旧记录也许还留在阅览区的回声里。' },
  { id: 'spines', title: '三本旧书的书脊', location: '书架区 · 现在', optional: false,
    description: '《雨的来处》书脊上是 7；《星光慢行》是 4；《风经过的地方》是 2。书名和数字都已记下。' },
  { id: 'record', title: '过去的借阅记录', location: '阅览区 · 回声', optional: false,
    description: '3 月 12 日：《风经过的地方》；3 月 15 日：《雨的来处》；3 月 20 日：《星光慢行》。记录页角写着：按借阅日期，从早到晚。' },
  { id: 'donation', title: '没有署名的赠书卡', location: '前台 · 回声', optional: true,
    description: '一张被压在公告下的赠书卡：林同学捐赠三本书，希望毕业后有人继续读到它们。接收栏空着，赠书记录没有完成。' },
  { id: 'promise', title: '留给后来者的留言', location: '阅览区 · 现在', optional: true,
    description: '“如果还有人记得这些书，请帮我补全那张赠书卡。感谢信想留在纪念书架上，给每一个愿意读它的人。”署名：林。' }
];

export const SCENES: SceneDefinition[] = [
  {
    id: 'foyer', title: '借阅前台', subtitle: '最后一晚，灯还亮着。', index: '01', spawn: { x: 160, y: 224 },
    objects: [
      { id: 'counter', name: '值班台', kind: 'desk', x: 112, y: 64, width: 96, height: 32, solid: true,
        nowText: '台面上放着管理员留下的便笺。明天旧馆就要改造了，资料室里还有一封没有送出的信。',
        pastText: '有人正在登记新到的图书。你听见翻页声，却看不清登记人的脸。', clueId: 'order', clueEra: 'now' },
      { id: 'notice', name: '旧公告栏', kind: 'board', x: 36, y: 40, width: 40, height: 40, solid: true,
        nowText: '公告已经褪色。空白的角落似乎曾经贴过什么，试着听一听这里的回声。',
        pastText: '过去的公告下面，露出一张没填完的赠书卡。原来，有人的心意一直没有被登记。', clueId: 'donation', clueEra: 'past' },
      { id: 'clock', name: '停摆的钟', kind: 'clock', x: 264, y: 40, width: 24, height: 24, solid: true,
        nowText: '钟停在 23:59。按住方向键走动，靠近物件后调查；点击「回声」，观察同一地点的过去。右侧的门通往书架区。',
        pastText: '钟摆又动了起来。回声改变的是这里留下的信息，房间的道路依然相通。', clueId: '', clueEra: 'now' },
      { id: 'returns', name: '还书架', kind: 'shelf', x: 32, y: 128, width: 48, height: 64, solid: true,
        nowText: '几本旧书安静地等着归位。你带来的那一本，也曾经放在这里。',
        pastText: '有位读者把书放回架上，在封面上轻轻拍了两下。', clueId: '', clueEra: 'now' }
    ],
    doors: [{ x: 284, y: 208, width: 20, height: 32, target: 'stacks', spawn: { x: 46, y: 224 }, locked: false, label: '书架区' }]
  },
  {
    id: 'stacks', title: '旧书架区', subtitle: '书名会记住风经过的方向。', index: '02', spawn: { x: 46, y: 224 },
    objects: [
      { id: 'literature', name: '文学书架', kind: 'shelf', x: 64, y: 40, width: 64, height: 96, solid: true,
        nowText: '一排卷边的诗集。书架之间留着可以通行的小路，仔细绕过去看看。',
        pastText: '借书的人站在这里，犹豫着该带走哪一本。', clueId: '', clueEra: 'now' },
      { id: 'numberedBooks', name: '三本旧书', kind: 'shelf', x: 176, y: 40, width: 64, height: 96, solid: true,
        nowText: '你找到三本带数字的旧书：雨是 7，星是 4，风是 2。它们的顺序需要另一条线索。',
        pastText: '三本书都被借走了，只剩下各自的空位。它们的数字还留在现在的书脊上。', clueId: 'spines', clueEra: 'now' },
      { id: 'bookCart', name: '整理中的书车', kind: 'desk', x: 112, y: 184, width: 96, height: 32, solid: true,
        nowText: '书车上的纸条写着：阅览区在东侧，借阅前台在西侧。没有找到的线索，随时可以回来再找。',
        pastText: '车轮在地板上留下一道浅浅的痕迹。', clueId: '', clueEra: 'now' }
    ],
    doors: [
      { x: 16, y: 208, width: 20, height: 32, target: 'foyer', spawn: { x: 274, y: 224 }, locked: false, label: '前台' },
      { x: 284, y: 208, width: 20, height: 32, target: 'reading', spawn: { x: 46, y: 224 }, locked: false, label: '阅览区' }
    ]
  },
  {
    id: 'reading', title: '靠窗阅览区', subtitle: '有些字，只在过去清晰。', index: '03', spawn: { x: 46, y: 224 },
    objects: [
      { id: 'ledger', name: '借阅登记簿', kind: 'desk', x: 40, y: 48, width: 40, height: 48, solid: true,
        nowText: '登记簿被水洇过，日期已经无法辨认。也许在过去的回声中，墨迹仍然清晰。',
        pastText: '日期显现出来：3 月 12 日借出《风经过的地方》，3 月 15 日是《雨的来处》，3 月 20 日是《星光慢行》。', clueId: 'record', clueEra: 'past' },
      { id: 'readerNote', name: '窗边的留言', kind: 'desk', x: 120, y: 80, width: 80, height: 48, solid: true,
        nowText: '桌垫下压着一张留言：“请补全赠书卡，把感谢信留给后来者。”这是一个可以选择完成的约定。',
        pastText: '年轻的读者伏在桌前写信。笔尖停了很久，最后只落下一个“林”字。', clueId: 'promise', clueEra: 'now' },
      { id: 'magazines', name: '期刊架', kind: 'shelf', x: 40, y: 176, width: 80, height: 32, solid: true,
        nowText: '旧刊按年份排好。这里并不催促你，重要的事情值得慢慢找。',
        pastText: '午后的光落在刚到的新刊上。', clueId: '', clueEra: 'now' },
      { id: 'archiveLock', name: '资料室密码锁', kind: 'lock', x: 260, y: 16, width: 40, height: 16, solid: false,
        nowText: '三位密码锁仍在工作。用书脊数字和借阅日期推导出正确顺序，就能打开资料室。',
        pastText: '锁上的标签写着：“按借阅日期，从早到晚。”现在与过去的线索，可以互相补全。', clueId: '', clueEra: 'now' }
    ],
    doors: [
      { x: 16, y: 208, width: 20, height: 32, target: 'stacks', spawn: { x: 274, y: 224 }, locked: false, label: '书架区' },
      { x: 260, y: 16, width: 40, height: 22, target: 'archive', spawn: { x: 280, y: 224 }, locked: true, label: '资料室' }
    ]
  },
  {
    id: 'archive', title: '旧资料室', subtitle: '那封信，终于等到了读者。', index: '04', spawn: { x: 280, y: 224 },
    objects: [
      { id: 'letters', name: '未寄出的信', kind: 'letter', x: 120, y: 96, width: 80, height: 48, solid: true,
        nowText: '信里是林同学写给图书馆的感谢：“在我不知去向的日子里，是这些书给了我一个可以停留的地方。”你可以把信交给管理员；若找到赠书卡与留言，也可以补全那个约定。',
        pastText: '一封信被小心地放进抽屉。过去无法替你作出决定，请回到现在，读完它。', clueId: '', clueEra: 'now' },
      { id: 'archiveCabinet', name: '档案柜', kind: 'shelf', x: 40, y: 48, width: 64, height: 48, solid: true,
        nowText: '柜里存着许多平凡的名字。图书馆留下的不只是书，也有人与人之间的联系。',
        pastText: '柜门慢慢合上，一段故事被留在了这里。', clueId: '', clueEra: 'now' },
      { id: 'memorial', name: '纪念书架', kind: 'shelf', x: 240, y: 48, width: 48, height: 96, solid: true,
        nowText: '书架留着一个空位，足够放下一封信和一张补全的赠书卡。',
        pastText: '有人说，希望这些书能陪伴更多后来的人。', clueId: '', clueEra: 'now' }
    ],
    doors: [{ x: 260, y: 240, width: 40, height: 16, target: 'reading', spawn: { x: 280, y: 50 }, locked: false, label: '阅览区' }]
  }
];

export function getScene(id: RoomId): SceneDefinition {
  for (let i: number = 0; i < SCENES.length; i++) {
    if (SCENES[i].id === id) { return SCENES[i]; }
  }
  return SCENES[0];
}

export function getClue(id: string): ClueDefinition | undefined {
  return CLUES.find((clue: ClueDefinition) => clue.id === id);
}

export function endingTitle(id: EndingId): string {
  if (id === 'promise') { return '迟到的约定'; }
  if (id === 'delivered') { return '信已送达'; }
  return '尚未抵达的结局';
}

export function endingText(id: EndingId): string {
  if (id === 'promise') {
    return '你补全了那张遗失的赠书卡，把感谢信放回纪念书架。明天，新来的读者也会知道这些书的来处。\n\n有些约定来得很晚，但仍然来得及。';
  }
  return '你把信交给了管理员。他读完后郑重地收好，答应将它妥善保存。\n\n这封未寄出的信，终于找到了愿意倾听的人。也许馆内还留着另一段等待补全的往事。';
}
