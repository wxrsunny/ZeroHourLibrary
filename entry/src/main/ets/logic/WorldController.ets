import { Point, Rect, MapObject, Door, SceneDefinition, Direction, GameProgress, MoveResult, cloneProgress } from '../model/GameTypes';
import { MAP_WIDTH, MAP_HEIGHT, PLAYER_RADIUS, INTERACT_DISTANCE, getScene } from '../data/StoryData';

export function distanceToRect(point: Point, rect: Rect): number {
  const dx: number = Math.max(rect.x - point.x, 0, point.x - rect.x - rect.width);
  const dy: number = Math.max(rect.y - point.y, 0, point.y - rect.y - rect.height);
  return Math.sqrt(dx * dx + dy * dy);
}

export function canStand(scene: SceneDefinition, point: Point): boolean {
  if (!Number.isFinite(point.x) || !Number.isFinite(point.y)) { return false; }
  if (point.x < 16 + PLAYER_RADIUS || point.x > MAP_WIDTH - 16 - PLAYER_RADIUS ||
      point.y < 16 + PLAYER_RADIUS || point.y > MAP_HEIGHT - 16 - PLAYER_RADIUS) { return false; }
  for (let i: number = 0; i < scene.objects.length; i++) {
    const object: MapObject = scene.objects[i];
    if (object.solid && distanceToRect(point, object) < PLAYER_RADIUS) { return false; }
  }
  return true;
}

export function nearbyObject(progress: GameProgress): MapObject | undefined {
  const scene: SceneDefinition = getScene(progress.room);
  let nearest: MapObject | undefined = undefined;
  let distance: number = INTERACT_DISTANCE;
  for (let i: number = 0; i < scene.objects.length; i++) {
    const candidate: MapObject = scene.objects[i];
    const current: number = distanceToRect(progress.position, candidate);
    if (current <= distance) { nearest = candidate; distance = current; }
  }
  return nearest;
}

function contains(point: Point, rect: Rect): boolean {
  return point.x >= rect.x && point.x <= rect.x + rect.width &&
    point.y >= rect.y && point.y <= rect.y + rect.height;
}

function facesDoor(door: Door, direction: Direction): boolean {
  if (door.x <= 16 && door.width <= 20) { return direction === 'left'; }
  if (door.x >= MAP_WIDTH - 36 && door.width <= 20) { return direction === 'right'; }
  return door.y < MAP_HEIGHT / 2 ? direction === 'up' : direction === 'down';
}

function enterDoor(next: GameProgress, door: Door, result: MoveResult): MoveResult {
  next.room = door.target;
  next.position = { x: door.spawn.x, y: door.spawn.y };
  if (!next.visitedRooms.includes(door.target)) { next.visitedRooms.push(door.target); }
  result.changedRoom = true;
  result.moved = true;
  next.steps += 1;
  return result;
}

export function movePlayer(progress: GameProgress, direction: Direction, step: number = 4): MoveResult {
  const next: GameProgress = cloneProgress(progress);
  const result: MoveResult = { progress: next, moved: false, changedRoom: false, blockedDoor: false };
  if (progress.ending !== '' || !Number.isFinite(step) || step <= 0 || step > 16 ||
      !['up', 'down', 'left', 'right'].includes(direction)) { return result; }
  next.facing = direction;
  const scene: SceneDefinition = getScene(next.room);
  if (!canStand(scene, next.position)) { next.position = { x: scene.spawn.x, y: scene.spawn.y }; }
  // A player can unlock a door while already against the outer wall. Check the
  // current position too, before rejecting an outward step at the map boundary.
  for (let i: number = 0; i < scene.doors.length; i++) {
    const door: Door = scene.doors[i];
    if (contains(next.position, door) && facesDoor(door, direction) && (!door.locked || next.archiveUnlocked)) {
      return enterDoor(next, door, result);
    }
  }
  // Split movement into short steps so a fast update cannot tunnel through a thin obstacle.
  const dx: number = direction === 'right' ? 1 : direction === 'left' ? -1 : 0;
  const dy: number = direction === 'down' ? 1 : direction === 'up' ? -1 : 0;
  let remaining: number = step;
  while (remaining > 0) {
    const delta: number = Math.min(remaining, 2);
    const candidate: Point = { x: next.position.x + dx * delta, y: next.position.y + dy * delta };
    if (!canStand(scene, candidate)) { break; }
    next.position = candidate;
    result.moved = true;
    remaining -= delta;
    for (let i: number = 0; i < scene.doors.length; i++) {
      const door: Door = scene.doors[i];
      if (!contains(candidate, door) || !facesDoor(door, direction)) { continue; }
      if (door.locked && !next.archiveUnlocked) { result.blockedDoor = true; continue; }
      return enterDoor(next, door, result);
    }
  }
  if (result.moved) { next.steps += 1; }
  return result;
}
