import { GameProgress, SaveEnvelope, LoadResult, RoomId, EndingId, Direction } from '../model/GameTypes';
import { ROOM_IDS, getScene, getClue } from '../data/StoryData';
import { canStand } from '../logic/WorldController';

export function encodeSave(progress: GameProgress): string {
  const envelope: SaveEnvelope = { version: 1, savedAt: Date.now(), progress: progress };
  return JSON.stringify(envelope);
}

export function decodeSave(raw: string): LoadResult {
  if (raw === '') { return { progress: null, warning: '' }; }
  try {
    const saved: SaveEnvelope = JSON.parse(raw) as SaveEnvelope;
    if (saved === null || typeof saved !== 'object' || saved.version !== 1 ||
        !Number.isFinite(saved.savedAt) || saved.savedAt < 0) {
      return { progress: null, warning: '这份存档的格式或版本无法读取。原始存档保留，开始新游戏后才会覆盖。' };
    }
    const p: GameProgress = saved.progress;
    if (!p || typeof p !== 'object' || !ROOM_IDS.includes(p.room) ||
        (p.era !== 'now' && p.era !== 'past') ||
        !(['up', 'down', 'left', 'right'] as Direction[]).includes(p.facing) ||
        !Array.isArray(p.clues) || !p.clues.every((id: string) => typeof id === 'string' && getClue(id) !== undefined) ||
        !Array.isArray(p.visitedRooms) || !p.visitedRooms.every((id: RoomId) => ROOM_IDS.includes(id)) ||
        typeof p.archiveUnlocked !== 'boolean' || typeof p.letterFound !== 'boolean' ||
        !(['', 'delivered', 'promise'] as EndingId[]).includes(p.ending) ||
        !Array.isArray(p.unlockedEndings) ||
        !p.unlockedEndings.every((id: EndingId) => id === 'delivered' || id === 'promise') ||
        !Number.isInteger(p.steps) || p.steps < 0 || !p.position || typeof p.position !== 'object') {
      return { progress: null, warning: '存档内容不完整，无法继续。开始新游戏前不会覆盖它。' };
    }
    p.clues = p.clues.filter((id: string, index: number) => p.clues.indexOf(id) === index);
    p.visitedRooms = p.visitedRooms.filter((id: RoomId, index: number) => p.visitedRooms.indexOf(id) === index);
    p.unlockedEndings = p.unlockedEndings.filter((id: EndingId, index: number) => p.unlockedEndings.indexOf(id) === index);
    if (!p.visitedRooms.includes(p.room)) { p.visitedRooms.push(p.room); }
    if (p.room === 'archive' && !p.archiveUnlocked) {
      return { progress: null, warning: '存档中的门锁与房间状态不一致，请开始新游戏。' };
    }
    let warning: string = '';
    if (!canStand(getScene(p.room), p.position)) {
      const spawn = getScene(p.room).spawn;
      p.position = { x: spawn.x, y: spawn.y };
      warning = '角色位置异常，已恢复到本房间的安全位置。';
    }
    if (p.ending !== '' && !p.unlockedEndings.includes(p.ending)) { p.unlockedEndings.push(p.ending); }
    return { progress: p, warning: warning };
  } catch {
    return { progress: null, warning: '存档无法解析。原始存档保留，可以重新开始。' };
  }
}
