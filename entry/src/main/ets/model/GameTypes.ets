export type RoomId = 'foyer' | 'stacks' | 'reading' | 'archive';
export type Era = 'now' | 'past';
export type Direction = 'up' | 'down' | 'left' | 'right';
export type EndingId = '' | 'delivered' | 'promise';
export type ObjectKind = 'desk' | 'shelf' | 'board' | 'clock' | 'lock' | 'letter';

export interface Point { x: number; y: number; }
export interface Rect { x: number; y: number; width: number; height: number; }
export interface MapObject extends Rect {
  id: string;
  name: string;
  kind: ObjectKind;
  solid: boolean;
  nowText: string;
  pastText: string;
  clueId: string;
  clueEra: Era;
}
export interface Door extends Rect {
  target: RoomId;
  spawn: Point;
  locked: boolean;
  label: string;
}
export interface SceneDefinition {
  id: RoomId;
  title: string;
  subtitle: string;
  index: string;
  spawn: Point;
  objects: MapObject[];
  doors: Door[];
}
export interface ClueDefinition {
  id: string;
  title: string;
  description: string;
  location: string;
  optional: boolean;
}
export interface GameProgress {
  room: RoomId;
  position: Point;
  facing: Direction;
  era: Era;
  clues: string[];
  visitedRooms: RoomId[];
  archiveUnlocked: boolean;
  letterFound: boolean;
  ending: EndingId;
  unlockedEndings: EndingId[];
  steps: number;
}
export interface InteractionResult {
  title: string;
  text: string;
  kind: 'text' | 'puzzle' | 'final';
  collected: boolean;
}
export interface MoveResult { progress: GameProgress; moved: boolean; changedRoom: boolean; blockedDoor: boolean; }
export interface SaveEnvelope { version: number; savedAt: number; progress: GameProgress; }
export interface LoadResult { progress: GameProgress | null; warning: string; }
export interface SaveResult { success: boolean; message: string; }

export function createProgress(endings: EndingId[] = []): GameProgress {
  return {
    room: 'foyer', position: { x: 160, y: 224 }, facing: 'up', era: 'now',
    clues: [], visitedRooms: ['foyer'], archiveUnlocked: false, letterFound: false,
    ending: '', unlockedEndings: endings.slice(), steps: 0
  };
}

export function cloneProgress(p: GameProgress): GameProgress {
  return {
    room: p.room, position: { x: p.position.x, y: p.position.y }, facing: p.facing, era: p.era,
    clues: p.clues.slice(), visitedRooms: p.visitedRooms.slice(), archiveUnlocked: p.archiveUnlocked,
    letterFound: p.letterFound, ending: p.ending, unlockedEndings: p.unlockedEndings.slice(), steps: p.steps
  };
}
