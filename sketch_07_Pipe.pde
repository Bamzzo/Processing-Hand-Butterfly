/**
 * 管道障碍物类
 * 表示游戏中移动的障碍物
 */
class Pipe {
  float x, y;           // 位置
  float width, height;  // 尺寸
  color pipeColor;      // 基础颜色
  float speed;          // 移动速度
  int spawnTime;        // 生成时间戳
  
  /**
   * 构造函数
   * @param x 初始X坐标
   * @param y 初始Y坐标
   * @param w 宽度
   * @param h 高度
   * @param c 颜色
   */
  Pipe(float x, float y, float w, float h, color c) {
    this.x = x;
    this.y = y;
    this.width = w;
    this.height = h;
    this.pipeColor = c;
    this.spawnTime = millis();  // 记录生成时间
  }
  
  /**
   * 重置管道参数
   * @param x 新X坐标
   * @param y 新Y坐标
   * @param w 新宽度
   * @param h 新高度
   */
  void reset(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.width = w;
    this.height = h;
    this.spawnTime = millis();  // 更新生成时间
  }
  
  /**
   * 更新管道位置
   * @param speed 移动速度
   */
  void update(float speed) {
    this.speed = speed;
    x -= speed;  // 向左移动
  }
  
  /** 绘制管道（带装饰细节） */
  void display() {
    // 绘制管道主体
    fill(pipeColor);
    noStroke();
    rect(x, y, width, height);
    
    // 添加顶部和底部边缘
    fill(0, 150, 0);  // 深绿色
    rect(x, y, width, 10);                // 顶部边缘
    rect(x, y + height - 10, width, 10);  // 底部边缘
    
    // 添加内部装饰
    fill(0, 180, 0);  // 浅绿色
    rect(x + 5, y + 15, width - 10, height - 30);  // 内部矩形
  }
}
