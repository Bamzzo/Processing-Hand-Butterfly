/**
 * 主程序类
 * 集成手势追踪、蝴蝶动画、粒子系统和障碍物系统，实现基于手势控制的飞行游戏
 */
import java.awt.Rectangle;
import processing.sound.*;

HandTracker tracker;            // 手势追踪系统
Butterfly butterfly;            // 蝴蝶对象
ParticleSystem particleSys;     // 粒子系统

// 蝴蝶可见性状态
boolean butterflyVisible = false;

// 游戏状态枚举
enum GameState { PREPARE, PLAYING, GAME_OVER }
GameState gameState = GameState.PREPARE;  // 初始状态为准备状态

// 障碍物系统
ArrayList<Pipe> pipes = new ArrayList<Pipe>();      // 活动管道列表
ArrayList<Pipe> pipePool = new ArrayList<Pipe>();   // 管道对象池（重用）
int lastPipeTime = 0;             // 上次生成管道的时间戳(毫秒)
int pipeInterval = 6000;          // 管道生成间隔(毫秒)
float pipeSpeed = 2.0;            // 管道移动速度(像素/帧)

// 计分系统
int score = 0;                    // 当前游戏分数(秒)
int gameStartTime = 0;            // 游戏开始时间戳(毫秒)
PFont scoreFont;                  // 分数显示字体

// 音频资源
SoundFile collisionSound;         // 碰撞音效
SoundFile disappearSound;         // 蝴蝶消失音效
SoundFile restartSound;           // 游戏重启音效

// UI元素
Button restartButton;             // 重启按钮
boolean showRestartButton = false;// 是否显示重启按钮

// 手势冷却时间
int lastGestureTime = 0;                      // 上次手势时间戳
final int GESTURE_COOLDOWN = 200;             // 手势冷却时间(毫秒)

// 蝴蝶碰撞半径
final float BUTTERFLY_RADIUS = 20;            // 碰撞检测半径(像素)

// 背景透明度控制
float bgAlpha = 0.7;                         // 背景透明度(0.0-1.0)

// 碰撞安全检测标志
boolean collisionHandled = false;             // 是否已处理当前碰撞

/**
 * 设置窗口尺寸
 * 在程序启动时调用
 */
void settings() {
  size(640, 480);  // 设置窗口为640x480像素
}

/**
 * 初始化游戏资源
 * 在程序启动时调用一次
 */
void setup() {
  frameRate(60);  // 设置目标帧率为60FPS
  tracker = new HandTracker(this, width, height);  // 初始化手势追踪
  butterfly = new Butterfly();                     // 创建蝴蝶对象
  particleSys = new ParticleSystem();             // 创建粒子系统
  
  // 加载计分字体
  scoreFont = createFont("Arial", 24);
  
  // 安全加载音效文件
  try {
    collisionSound = new SoundFile(this, "pengzhuang.mp3");
  } catch (Exception e) {
    println("警告：碰撞音效加载失败");
  }
  
  try {
    disappearSound = new SoundFile(this, "xiaoshi.wav");
  } catch (Exception e) {
    println("警告：消失音效加载失败");
  }
  
  try {
    restartSound = new SoundFile(this, "restart.mp3");
  } catch (Exception e) {
    println("警告：重启音效加载失败");
  }
  
  // 初始化重启按钮（居中位置）
  restartButton = new Button(width/2 - 50, height/2 + 80, 100, 40, "Restart");
  
  // 预生成管道对象池（对象重用优化）
  for (int i = 0; i < 3; i++) {
    pipePool.add(new Pipe(width + 100, 0, 60, 100, color(0, 200, 0)));
  }
}

/**
 * 主游戏循环
 * 每帧调用一次，处理游戏逻辑和渲染
 */
void draw() {
  // 使用摄像头实时画面作为动态背景
  if (tracker != null && tracker.getView() != null) {
    tint(255, 255 * bgAlpha); // 应用背景透明度
    image(tracker.getView(), 0, 0, width, height);
    noTint();
  } else {
    background(135, 206, 235); // 备用背景（天空蓝）
  }
  
  tracker.update();  // 更新手势追踪状态
  
  // 游戏状态机处理
  switch(gameState) {
    case PREPARE:
      updatePrepareState();  // 准备状态逻辑
      break;
    case PLAYING:
      updatePlayingState();  // 游戏进行状态逻辑
      break;
    case GAME_OVER:
      updateGameOverState(); // 游戏结束状态逻辑
      break;
  }
  
  // 绘制手势识别调试信息
  if (tracker != null) {
    tracker.drawDebugOverlay();
  }
  
  // 键盘控制背景透明度
  if (keyPressed) {
    if (key == 'a') bgAlpha = constrain(bgAlpha - 0.05, 0.2, 1.0); // 降低透明度
    if (key == 'd') bgAlpha = constrain(bgAlpha + 0.05, 0.2, 1.0); // 增加透明度
  }
}

/**
 * 准备状态更新逻辑
 * 等待玩家张开手掌召唤蝴蝶
 */
void updatePrepareState() {
  // 获取当前手势状态
  boolean palmNow = tracker.openPalm;
  boolean fistNow = tracker.closedFist;
  
  // 手势冷却时间检查（避免连续触发）
  int currentTime = millis();
  if (currentTime - lastGestureTime < GESTURE_COOLDOWN) {
    return;
  }
  
  // 手掌张开且蝴蝶不可见时召唤蝴蝶
  if (!butterflyVisible && palmNow) {
    butterflyVisible = true;
    butterfly.pos.set(tracker.handPos);  // 蝴蝶初始位置为手部位置
    particleSys.reset(butterfly.pos);    // 重置粒子系统
    lastGestureTime = currentTime;       // 记录手势时间
  }
  
  // 蝴蝶可见且手掌张开时开始游戏
  if (butterflyVisible && palmNow) {
    gameState = GameState.PLAYING;     // 切换到游戏状态
    gameStartTime = millis();           // 记录游戏开始时间
    score = 0;                         // 重置分数
    pipeSpeed = 2.0;                   // 重置管道速度
    pipeInterval = 6000;               // 重置管道生成间隔
    collisionHandled = false;          // 重置碰撞处理标志
  }
  
  // 更新蝴蝶位置和显示
  if (butterflyVisible) {
    // 目标位置：手部位置或当前位置
    PVector target = tracker.handDetected ? tracker.handPos : butterfly.pos;
    butterfly.updateAndDraw(target);  // 更新并绘制蝴蝶
    particleSys.run();                // 更新粒子系统
  }
}

/**
 * 游戏进行状态更新逻辑
 * 处理游戏核心机制：手势控制、管道生成、碰撞检测
 */
void updatePlayingState() {
  // 更新分数（游戏持续时间秒数）
  score = (millis() - gameStartTime) / 1000;
  
  /**
   * 动态调整游戏难度
   * 每10秒增加管道速度和生成频率
   */
  if (score > 0 && score % 10 == 0) {
    pipeSpeed = 2.0 + score * 0.005;       // 线性增加速度
    pipeInterval = max(3000, 6000 - score * 10); // 减少生成间隔（最低3秒）
  }
  
  // 手势检测（带冷却时间控制）
  int currentTime = millis();
  if (currentTime - lastGestureTime >= GESTURE_COOLDOWN) {
    boolean palmNow = tracker.openPalm;
    boolean fistNow = tracker.closedFist;
    
    // 手掌张开：显示蝴蝶
    if (palmNow && !butterflyVisible) {
      butterflyVisible = true;
      butterfly.pos.set(tracker.handPos); // 设置蝴蝶位置为手部位置
      lastGestureTime = currentTime;      // 记录手势时间
    }
    
    // 握拳：隐藏蝴蝶
    if (fistNow && butterflyVisible) {
      butterflyVisible = false;
      try {
        if (disappearSound != null) disappearSound.play(); // 播放消失音效
      } catch (Exception e) {
        println("消失音效播放失败");
      }
      lastGestureTime = currentTime; // 记录手势时间
    }
  }
  
  // 更新蝴蝶位置（如果可见）
  if (butterflyVisible) {
    PVector target = tracker.handDetected ? tracker.handPos : butterfly.pos;
    butterfly.updateAndDraw(target);
    // 添加轨迹粒子（使用安全位置获取）
    particleSys.addTrail(butterfly.getSafePos()); 
  }
  
  // 按间隔生成新管道
  if (millis() - lastPipeTime > pipeInterval) {
    spawnPipe();         // 生成新管道
    lastPipeTime = millis(); // 记录生成时间
  }
  
  updatePipes(); // 更新所有管道位置和状态
  
  // 碰撞检测（多重安全检查）
  if (butterflyVisible && butterfly != null && butterfly.pos != null && !collisionHandled) {
    if (checkCollisions()) {
      handleCollision(); // 处理碰撞事件
    }
  }
  
  displayScore(); // 显示当前分数
  
  // 调试信息显示（游戏状态监控）
  fill(255, 0, 0);
  textSize(16);
  text("Game State: " + gameState, width - 200, 10);
  text("Butterfly Visible: " + butterflyVisible, width - 200, 30);
  text("Collision Handled: " + collisionHandled, width - 200, 50);
  text("Pipes Count: " + pipes.size(), width - 200, 70);
}

/**
 * 处理碰撞事件
 * 游戏结束逻辑和效果
 */
void handleCollision() {
  gameState = GameState.GAME_OVER; // 切换到游戏结束状态
  
  // 播放碰撞音效（安全调用）
  try {
    if (collisionSound != null) collisionSound.play();
  } catch (Exception e) {
    println("碰撞音效播放失败");
  }
  
  // 在碰撞位置创建粒子爆炸效果
  if (particleSys != null && butterfly != null) {
    try {
      particleSys.explode(butterfly.getSafePos());
    } catch (Exception e) {
      println("粒子效果创建失败: " + e.getMessage());
    }
  }
  
  // 重置蝴蝶位置到屏幕中心
  if (butterfly != null) {
    try {
      butterfly.pos.set(width/2, height/2);
    } catch (Exception e) {
      println("蝴蝶位置重置失败");
    }
  }
  
  showRestartButton = true;  // 显示重启按钮
  collisionHandled = true;   // 标记碰撞已处理
  
  // 安全移除所有管道（回收到对象池）
  try {
    for (Pipe pipe : pipes) {
      if (pipe != null) pipePool.add(pipe);
    }
    pipes.clear();
  } catch (Exception e) {
    println("管道清除失败: " + e.getMessage());
  }
}

/**
 * 游戏结束状态更新逻辑
 * 显示结算信息和重启选项
 */
void updateGameOverState() {
  butterflyVisible = false; // 禁用游戏结束时的蝴蝶显示
  
  // 显示游戏结束文本
  textFont(scoreFont);
  textAlign(CENTER);
  fill(0);
  textSize(32);
  text("Game Over!", width/2, height/2 - 60); // 主标题
  textSize(24);
  text("Score: " + score, width/2, height/2 - 20); // 分数显示
  
  // 显示和管理重启按钮状态
  if (restartButton != null) {
    restartButton.display();
    if (showRestartButton) {
      // 鼠标悬停高亮效果
      if (restartButton.isMouseOver()) {
        restartButton.highlight();
      } else {
        restartButton.unhighlight();
      }
    } else {
      showRestartButton = true; // 确保按钮可见
    }
  }
  
  // 更新粒子系统（安全调用）
  if (particleSys != null) {
    try {
      particleSys.run();
    } catch (Exception e) {
      println("粒子系统更新失败: " + e.getMessage());
    }
  }
}

/**
 * 碰撞检测算法
 * 使用圆形-矩形碰撞检测（距离平方优化）
 * @return 是否发生碰撞
 */
boolean checkCollisions() {
  // 安全检查：蝴蝶和管道列表的有效性
  if (butterfly == null || butterfly.pos == null || pipes == null || pipes.isEmpty()) {
    return false;
  }
  
  // 遍历所有活动管道
  for (int i = 0; i < pipes.size(); i++) {
    Pipe pipe = pipes.get(i);
    if (pipe == null) continue; // 跳过无效管道
    
    // 管道参数有效性检查
    if (Float.isNaN(pipe.x) || Float.isNaN(pipe.y) || 
        pipe.width <= 0 || pipe.height <= 0) {
      continue;
    }
    
    // 计算管道上距离蝴蝶最近的点
    float testX = butterfly.pos.x;
    float testY = butterfly.pos.y;
    
    // X轴边界约束
    if (butterfly.pos.x < pipe.x)         testX = pipe.x;
    else if (butterfly.pos.x > pipe.x + pipe.width) testX = pipe.x + pipe.width;
    
    // Y轴边界约束
    if (butterfly.pos.y < pipe.y)         testY = pipe.y;
    else if (butterfly.pos.y > pipe.y + pipe.height) testY = pipe.y + pipe.height;
    
    // 计算距离平方（避免开方运算）
    float distX = butterfly.pos.x - testX;
    float distY = butterfly.pos.y - testY;
    float distanceSq = distX * distX + distY * distY;
    
    // 碰撞判定：距离平方小于半径平方
    if (distanceSq < BUTTERFLY_RADIUS * BUTTERFLY_RADIUS) {
      return true; // 发生碰撞
    }
  }
  return false; // 未发生碰撞
}

/**
 * 从对象池生成新管道
 * 实现管道对象的复用优化
 */
void spawnPipe() {
  Pipe pipe = null;
  
  // 优先从对象池获取可用管道
  if (pipePool.size() > 0) {
    pipe = pipePool.remove(0);
  } else {
    // 对象池为空时创建新管道
    pipe = new Pipe(width + 100, 0, 60, 100, color(0, 200, 0));
  }
  
  // 随机决定管道位置（上方或下方）
  int gap = 200; // 上下管道间距
  int pipeHeight = (int)random(100, height - gap - 100); // 随机高度
  
  if (random(1) > 0.5) {
    // 上方管道（从顶部向下延伸）
    pipe.reset(width, 0, pipe.width, pipeHeight);
  } else {
    // 下方管道（从底部向上延伸）
    pipe.reset(width, height - pipeHeight, pipe.width, pipeHeight);
  }
  
  pipes.add(pipe); // 添加到活动管道列表
  
  // 活动管道数量控制（最大5个）
  if (pipes.size() > 5) {
    Pipe oldest = pipes.remove(0); // 移除最早的管道
    pipePool.add(oldest);          // 回收到对象池
  }
}

/**
 * 更新所有活动管道
 * 包括位置更新、渲染和回收
 */
void updatePipes() {
  // 倒序遍历（安全移除元素）
  for (int i = pipes.size() - 1; i >= 0; i--) {
    Pipe pipe = pipes.get(i);
    if (pipe != null) {
      try {
        pipe.update(pipeSpeed); // 更新位置
        pipe.display();         // 渲染管道
        
        // 管道超出屏幕或存在时间过长时回收
        if (pipe.x + pipe.width < 0 || millis() - pipe.spawnTime > 30000) {
          pipes.remove(i);      // 从活动列表移除
          pipePool.add(pipe);   // 回收到对象池
        }
      } catch (Exception e) {
        println("管道更新失败: " + e.getMessage());
        pipes.remove(i); // 移除问题管道
      }
    }
  }
}

/**
 * 在屏幕左上角显示当前分数
 */
void displayScore() {
  textFont(scoreFont);
  textAlign(LEFT);
  fill(0); // 黑色文本
  textSize(24);
  text("Score: " + score, 20, 30); // 位置(20,30)
}

/**
 * 鼠标点击事件处理
 * 用于游戏结束状态的重启按钮交互
 */
void mousePressed() {
  // 游戏结束状态且重启按钮可见时检测点击
  if (gameState == GameState.GAME_OVER && showRestartButton && restartButton != null) {
    if (restartButton.isMouseOver()) {
      restartGame(); // 执行游戏重置
      // 播放重启音效
      try {
        if (restartSound != null) restartSound.play();
      } catch (Exception e) {
        println("重启音效播放失败");
      }
    }
  }
}

/**
 * 重置游戏状态
 * 恢复到初始准备状态
 */
void restartGame() {
  // 重置游戏状态变量
  gameState = GameState.PREPARE;
  score = 0;
  butterflyVisible = false;
  showRestartButton = false;
  collisionHandled = false;
  
  // 回收所有管道到对象池
  try {
    for (Pipe pipe : pipes) {
      if (pipe != null) pipePool.add(pipe);
    }
    pipes.clear();
  } catch (Exception e) {
    println("管道清除失败: " + e.getMessage());
  }
  
  // 重置粒子系统
  if (particleSys != null) {
    try {
      particleSys.reset(new PVector(width/2, height/2));
    } catch (Exception e) {
      println("粒子系统重置失败: " + e.getMessage());
    }
  }
  
  // 重置控制参数
  lastGestureTime = millis(); // 手势时间戳
  pipeSpeed = 2.0;           // 管道速度
  pipeInterval = 6000;       // 管道生成间隔
}

/**
 * 键盘事件处理
 * 用于调试和参数调整
 */
void keyPressed() {
  // 切换显示手势掩膜视图
  if (key == 'f' && tracker != null && tracker.getMask() != null) {
    image(tracker.getMask(), 0, 0);
  }
  
  // 背景透明度控制
  if (key == 'a') bgAlpha = constrain(bgAlpha - 0.05, 0.2, 1.0); // 降低透明度
  if (key == 'd') bgAlpha = constrain(bgAlpha + 0.05, 0.2, 1.0); // 增加透明度
  
  // 手势阈值动态调整
  if (tracker != null) {
    // 手掌张开阈值调整
    if (key == '[') tracker.AREA_OPEN_MAX = max(0.30f, tracker.AREA_OPEN_MAX - 0.02f);
    if (key == ']') tracker.AREA_OPEN_MAX = min(0.60f, tracker.AREA_OPEN_MAX + 0.02f);
    
    // 握拳阈值调整
    if (key == '-') tracker.AREA_FIST_MIN = max(0.40f, tracker.AREA_FIST_MIN - 0.02f);
    if (key == '=') tracker.AREA_FIST_MIN = min(0.70f, tracker.AREA_FIST_MIN + 0.02f);
  }
  
  // 调试命令
  if (key == 'r') restartGame(); // 强制重启游戏
  if (key == 'p') { // 打印当前游戏状态
    println("当前游戏状态: " + gameState);
    println("蝴蝶可见: " + butterflyVisible);
    println("碰撞处理: " + collisionHandled);
    println("管道数量: " + pipes.size());
  }
}
