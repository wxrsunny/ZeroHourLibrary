import { GameProgress, MapObject, Door, createProgress } from '../model/GameTypes';
import { getScene, MAP_WIDTH, MAP_HEIGHT } from '../data/StoryData';

@Component
export struct LibraryMap {
  @Prop @Watch('draw') progress: GameProgress = createProgress();
  @Prop @Watch('draw') highlightId: string = '';
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(false));
  private ready: boolean = false;

  draw(): void {
    if (!this.ready || this.canvas.width <= 0) { return; }
    const c: CanvasRenderingContext2D = this.canvas;
    const past: boolean = this.progress.era === 'past';
    c.resetTransform(); c.clearRect(0, 0, c.width, c.height);
    const scale: number = c.width / MAP_WIDTH;
    c.scale(scale, scale);
    c.fillStyle = past ? '#283F48' : '#304B45'; c.fillRect(0, 0, MAP_WIDTH, MAP_HEIGHT);
    c.fillStyle = past ? '#87958E' : '#D9BA83'; c.fillRect(16, 16, 288, 240);
    for (let row: number = 1; row < 16; row++) {
      for (let col: number = 1; col < 19; col++) {
        c.fillStyle = past ? ((row + col) % 2 === 0 ? '#85958F' : '#8E9C93') : ((row + col) % 2 === 0 ? '#E2C591' : '#DCC08A');
        c.fillRect(col * 16, row * 16, 16, 16);
        c.fillStyle = past ? '#7E9089' : '#CEAD79'; c.fillRect(col * 16, row * 16 + 15, 16, 1);
      }
    }
    c.fillStyle = past ? '#56706F' : '#A98253'; c.fillRect(16, 16, 288, 4); c.fillRect(16, 252, 288, 4);
    c.fillStyle = past ? '#607F7F' : '#A16E54'; c.fillRect(108, 164, 112, 68);
    c.fillStyle = past ? '#7F9F98' : '#C39873'; c.fillRect(112, 168, 104, 60);
    c.strokeStyle = past ? '#A9BDB0' : '#EDD6AC'; c.lineWidth = 1; c.strokeRect(116, 172, 96, 52);
    c.fillStyle = past ? '#BDD1C1' : '#FAE8B9'; c.fillRect(228, 4, 48, 8);
    c.fillStyle = past ? '#D2DBCB' : '#FFF4CA'; c.fillRect(232, 5, 17, 5); c.fillRect(253, 5, 17, 5);
    const scene = getScene(this.progress.room);
    for (let i: number = 0; i < scene.doors.length; i++) { this.paintDoor(scene.doors[i], past); }
    for (let i: number = 0; i < scene.objects.length; i++) { this.paintObject(scene.objects[i], past); }
    this.paintPlayer(past);
    if (past) {
      c.fillStyle = '#DBE6C0';
      for (let i: number = 0; i < 16; i++) { c.fillRect(26 + (i * 47) % 266, 30 + (i * 67) % 204, 2, 2); }
    }
    c.resetTransform();
  }

  private paintDoor(door: Door, past: boolean): void {
    const c = this.canvas;
    c.fillStyle = door.locked && !this.progress.archiveUnlocked ? '#80694E' : (past ? '#A9B9AB' : '#F3DBA5');
    c.fillRect(door.x, door.y, door.width, door.height);
    c.fillStyle = '#314E48'; c.font = '9px sans-serif'; c.textAlign = 'center';
    if (door.width <= 20) { c.fillText(door.x < 160 ? '‹' : '›', door.x + door.width / 2, door.y + 16); }
    else { c.fillText(door.locked && !this.progress.archiveUnlocked ? '锁' : (door.y < 100 ? '↑' : '↓'), door.x + door.width / 2, door.y + 12); }
  }

  private paintObject(object: MapObject, past: boolean): void {
    const c = this.canvas;
    const x: number = object.x; const y: number = object.y;
    const w: number = object.width; const h: number = object.height;
    c.fillStyle = past ? '#4F696680' : '#6C513D55'; c.fillRect(x + 3, y + 5, w, h);
    c.fillStyle = past ? '#526D6C' : '#826244'; c.fillRect(x, y, w, h);
    c.fillStyle = past ? '#7A9690' : '#B88C5B'; c.fillRect(x + 3, y + 3, w - 6, h - 8);
    if (object.kind === 'shelf') {
      const colors: string[] = past ? ['#A9B9A0', '#74938E', '#D0CCB1', '#879B99'] : ['#B96F4B', '#577C69', '#E4C47E', '#7E9490'];
      for (let row: number = 0; row < Math.max(1, Math.floor(h / 24)); row++) {
        for (let col: number = 0; col < Math.floor((w - 8) / 9); col++) {
          c.fillStyle = colors[(row + col) % colors.length]; c.fillRect(x + 5 + col * 9, y + 5 + row * 24, 6, 14 + col % 3);
          c.fillStyle = past ? '#D1D8BF' : '#F7DEA0'; c.fillRect(x + 6 + col * 9, y + 8 + row * 24, 4, 1);
        }
        c.fillStyle = past ? '#435D5C' : '#6A4C35'; c.fillRect(x + 3, y + 22 + row * 24, w - 6, 3);
      }
    } else if (object.kind === 'clock') {
      c.fillStyle = '#F7E7BE'; c.fillRect(x + 4, y + 4, 16, 16);
      c.fillStyle = '#304B45'; c.fillRect(x + 11, y + 7, 2, 7); c.fillRect(x + 11, y + 12, 6, 2);
    } else if (object.kind === 'lock') {
      c.fillStyle = '#E9DAB4';
      for (let i: number = 0; i < 3; i++) { c.fillRect(x + 8 + i * 9, y + 4, 6, 8); }
    } else {
      const paperX: number = x + Math.floor(w / 3);
      c.fillStyle = past ? '#E2E4CA' : '#FFF0C9'; c.fillRect(paperX, y + 8, Math.min(26, w - 12), Math.min(20, h - 12));
      c.fillStyle = past ? '#879F90' : '#AE8C65'; c.fillRect(paperX + 3, y + 12, Math.min(18, w - 18), 2);
      c.fillRect(paperX + 3, y + 17, Math.min(13, w - 18), 2);
      if (object.kind === 'letter') { c.fillStyle = '#AF654B'; c.fillRect(paperX + 10, y + 17, 5, 5); }
    }
    if (object.id === this.highlightId) {
      c.strokeStyle = past ? '#E6EEC9' : '#FFF6D5'; c.lineWidth = 2; c.strokeRect(x - 3, y - 3, w + 6, h + 6);
      c.fillStyle = '#304B45'; c.fillRect(x + w / 2 - 8, y - 18, 16, 13);
      c.fillStyle = '#FFF2CB'; c.font = 'bold 10px sans-serif'; c.textAlign = 'center'; c.fillText('?', x + w / 2, y - 8);
    }
  }

  private paintPlayer(past: boolean): void {
    const c = this.canvas;
    const x: number = Math.round(this.progress.position.x) - 7;
    const y: number = Math.round(this.progress.position.y) - 12;
    const stride: number = this.progress.steps % 2 === 0 ? 1 : -1;
    c.fillStyle = '#33443855'; c.fillRect(x - 2, y + 18, 19, 5);
    c.fillStyle = '#4A3C34'; c.fillRect(x + 3, y, 9, 5); c.fillRect(x + 1, y + 3, 13, 5);
    c.fillStyle = '#F2CAA1'; c.fillRect(x + 3, y + 6, 9, 6);
    c.fillStyle = past ? '#D6D1B0' : '#E6B363'; c.fillRect(x + 1, y + 12, 13, 7);
    c.fillStyle = '#2D534D'; c.fillRect(x + 4, y + 12, 7, 8);
    c.fillStyle = '#33453E'; c.fillRect(x + 2, y + 19, 4, 4 + stride); c.fillRect(x + 9, y + 19, 4, 4 - stride);
    c.fillStyle = '#4A3C34';
    if (this.progress.facing !== 'up') { c.fillRect(x + 5, y + 8, 1, 2); c.fillRect(x + 10, y + 8, 1, 2); }
  }

  build() {
    Canvas(this.canvas).width('100%').aspectRatio(MAP_WIDTH / MAP_HEIGHT)
      .onReady(() => { this.ready = true; this.draw(); }).onAreaChange(() => { this.draw(); })
      .accessibilityText('图书馆俯视地图，使用下方方向键控制角色，靠近物件后调查')
  }
}
