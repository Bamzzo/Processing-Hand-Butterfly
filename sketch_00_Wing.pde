/**
 * 蝴蝶翅膀类，负责翅膀的绘制和动画效果
 */
class Wing {
  PShape wingShape;       // 翅膀形状对象
  color wingColor;        // 当前翅膀颜色
  boolean isRight;        // 是否为右侧翅膀
  boolean isLower;        // 是否为下层翅膀
  float scale;            // 翅膀大小缩放系数
  float phase;            // 翅膀拍打动画相位
  
  // 上层翅膀轮廓点(基于真实蝴蝶结构)
  PVector[] upperContour = {
    new PVector(0, 0),    // 身体连接点
    new PVector(-25, -20),
    new PVector(-45, -45),
    new PVector(-60, -85),
    new PVector(-50, -115),
    new PVector(-30, -135),
    new PVector(0, -145),
    new PVector(25, -130), // 翅膀尖端
    new PVector(40, -100),
    new PVector(35, -70),
    new PVector(20, -45)
  };
  
  // 下层翅膀轮廓点
  PVector[] lowerContour = {
    new PVector(0, 0),    // 身体连接点
    new PVector(-20, 15),
    new PVector(-35, 40),
    new PVector(-45, 75),
    new PVector(-35, 100),
    new PVector(-15, 120),
    new PVector(10, 125), // 翅膀底部
    new PVector(30, 110),
    new PVector(35, 85),
    new PVector(30, 60),
    new PVector(20, 40)
  };

  /**
   * 构造函数
   * @param c 初始颜色
   * @param right 是否为右侧翅膀
   * @param lower 是否为下层翅膀
   * @param s 缩放系数
   */
  Wing(color c, boolean right, boolean lower, float s) {
    wingColor = c;
    isRight = right;
    isLower = lower;
    scale = s;
    phase = random(TWO_PI);
    createWing();
  }

  /**
   * 设置翅膀颜色
   * @param newColor 新颜色值
   */
  void setColor(color newColor) {
    this.wingColor = newColor;
    createWing(); // 需要重建形状以应用新颜色
  }

  /**
   * 创建翅膀形状对象
   */
  void createWing() {
    wingShape = createShape(GROUP);
    PShape mainShape = createShape();
    
    mainShape.beginShape();
    mainShape.fill(wingColor);
    mainShape.noStroke();
    
    // 选择对应轮廓点集
    PVector[] points = isLower ? lowerContour : upperContour;
    for (PVector p : points) {
      PVector v = p.copy();
      if (isRight) v.x = -v.x;  // 水平镜像处理
      mainShape.vertex(v.x * scale, v.y * scale);
    }
    
    mainShape.endShape(CLOSE);
    wingShape.addChild(mainShape);
  }

  /**
   * 更新翅膀动画状态
   * @param dt 时间增量(秒)
   */
  void update(float dt) {
    phase += dt;
  }

  /**
   * 绘制翅膀
   * @param x 绘制位置x坐标
   * @param y 绘制位置y坐标
   * @param rotation 旋转角度(弧度)
   */
  void display(float x, float y, float rotation) {
    pushMatrix();
    translate(x, y);
    rotate(rotation);
    
    // 添加拍打动画效果
    float flutter = sin(phase * 5) * 0.015;
    scale(1.0 + flutter);
    
    shape(wingShape);
    popMatrix();
  }
}
