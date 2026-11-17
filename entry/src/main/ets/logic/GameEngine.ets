import { GameProgress, InteractionResult, MapObject, EndingId } from '../model/GameTypes';
import { getScene, getClue, PUZZLE_CODE } from '../data/StoryData';
import { distanceToRect } from './WorldController';
import { INTERACT_DISTANCE } from '../data/StoryData';

export function investigate(progress: GameProgress, objectId: string): InteractionResult {
  const object: MapObject | undefined = getScene(progress.room).objects.find((item: MapObject) => item.id === objectId);
  if (!object || distanceToRect(progress.position, object) > INTERACT_DISTANCE) {
    return { title: '再靠近一点', text: '走到物件附近，才能仔细调查。', kind: 'text', collected: false };
  }
  const result: InteractionResult = {
    title: object.name, text: progress.era === 'now' ? object.nowText : object.pastText, kind: 'text', collected: false
  };
  if (object.clueId !== '' && object.clueEra === progress.era && !progress.clues.includes(object.clueId)) {
    progress.clues.push(object.clueId);
    result.collected = true;
    const clue = getClue(object.clueId);
    if (clue) { result.text += '\n\n已记入线索手册：' + clue.title; }
  }
  if (object.id === 'archiveLock') {
    if (progress.archiveUnlocked) { result.text = '密码锁已经打开，走到上方门口即可进入资料室。'; }
    else { result.kind = 'puzzle'; }
  }
  if (object.id === 'letters' && progress.era === 'now') {
    progress.letterFound = true;
    result.kind = 'final';
  }
  return result;
}

export function canSubmitPuzzle(progress: GameProgress): boolean {
  if (progress.room !== 'reading' || progress.ending !== '') { return false; }
  const lock = getScene('reading').objects.find((item: MapObject) => item.id === 'archiveLock');
  return lock !== undefined && distanceToRect(progress.position, lock) <= INTERACT_DISTANCE;
}

export function submitPuzzle(progress: GameProgress, input: string): string {
  if (!canSubmitPuzzle(progress)) { return '请先走到阅览区的资料室密码锁附近。'; }
  if (!/^\d{3}$/.test(input)) { return '请输入完整的三位数字密码。'; }
  if (input !== PUZZLE_CODE) { return '顺序似乎不对。对照借阅日期和书脊数字，再试一次。'; }
  progress.archiveUnlocked = true;
  return '';
}

export function canFulfilPromise(progress: GameProgress): boolean {
  return progress.letterFound && progress.clues.includes('donation') && progress.clues.includes('promise');
}

export function chooseEnding(progress: GameProgress, ending: EndingId): string {
  if (progress.room !== 'archive' || !progress.letterFound || progress.era !== 'now' || progress.ending !== '') {
    return '先在资料室的现在，读完那封未寄出的信。';
  }
  const letter = getScene('archive').objects.find((item: MapObject) => item.id === 'letters');
  if (!letter || distanceToRect(progress.position, letter) > INTERACT_DISTANCE) { return '请回到信件旁作出选择。'; }
  if (ending !== 'delivered' && ending !== 'promise') { return '请选择一个有效的结局。'; }
  if (ending === 'promise' && !canFulfilPromise(progress)) { return '还缺少赠书卡或后来者的留言。可以先返回馆内继续寻找。'; }
  progress.ending = ending;
  if (!progress.unlockedEndings.includes(ending)) { progress.unlockedEndings.push(ending); }
  return '';
}

export function objective(progress: GameProgress): string {
  if (progress.ending !== '') { return '故事已落下书签，仍有新的回声等你发现。'; }
  if (progress.letterFound) { return '决定信件的去向，或返回馆内补全赠书的约定。'; }
  if (progress.archiveUnlocked) { return '资料室已解锁，去读一读那封未寄出的信。'; }
  if (progress.clues.includes('spines') && progress.clues.includes('record')) { return '按借阅日期排列书脊数字，打开阅览区的密码锁。'; }
  if (progress.clues.includes('order')) { return '去书架区寻找数字，在阅览区的回声中寻找日期。'; }
  return '先走近前台的值班台，调查管理员留下的便笺。';
}
