/**
 * 蝴蝶类，整合翅膀和身体绘制
 */
class Butterfly {
  PVector pos;           // 当前位置
  PVector target;        // 目标位置
  float wingPhase;       // 翅膀拍打相位
  float wingSpeed;       // 翅膀拍打速度
  float colorPhase;      // 颜色变化相位
  Wing[] wings;          // 四个翅膀实例

  /**
   * 构造函数，初始化蝴蝶在屏幕中央
   */
  Butterfly() {
    pos = new PVector(width/2, height/2);
    target = pos.copy();
    colorPhase = 0;
    
    // 初始化四个翅膀(左上/右上/左下/右下)
    color initialColor = color(100, 255, 255);
    wings = new Wing[4];
    wings[0] = new Wing(initialColor, false, false, 1.0); // 左上
    wings[1] = new Wing(initialColor, true, false, 1.0);  // 右上
    wings[2] = new Wing(initialColor, false, true, 0.9);  // 左下
    wings[3] = new Wing(initialColor, true, true, 0.9);   // 右下
  }

  /**
   * 设置目标位置
   * @param t 目标位置向量
   */
  void setTarget(PVector t) {
    target = t.copy();
  }

  /**
   * 获取当前位置副本
   * @return 位置向量副本
   */
  PVector getPos() {
    return pos.copy();
  }

  /**
   * 更新蝴蝶状态
   */
  void update() {
    // 平滑移动到目标位置
    PVector delta = PVector.sub(target, pos);
    float speed = delta.mag();
    delta.mult(0.08);
    pos.add(delta);
    
    // 根据移动速度调整翅膀拍打频率
    wingSpeed = map(speed, 0, 40, 0.015, 0.18);
    wingPhase += wingSpeed;
    colorPhase += 0.01;
    
    // 更新所有翅膀颜色和状态
    color c = currentColor();
    for (Wing w : wings) {
      w.setColor(c);
      w.update(1.0 / frameRate);
    }
  }

  /**
   * 绘制完整蝴蝶
   */
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    
    // 计算翅膀拍打角度
    float upperRot = sin(wingPhase) * PI / 18;      // 上层翅膀角度
    float lowerRot = sin(wingPhase + PI / 3) * PI / 16; // 下层翅膀角度
    
    // 翅膀位置偏移量
    PVector[] wingOffsets = {
      new PVector(-25, -8), new PVector(25, -8),  // 上层翅膀
      new PVector(-22, 12), new PVector(22, 12)   // 下层翅膀
    };
    
    // 基础展开角度(弧度)
    float baseUpperAngle = radians(-25);
    float baseLowerAngle = radians(20);
    
    // 绘制四个翅膀
    wings[0].display(wingOffsets[0].x, wingOffsets[0].y, baseUpperAngle - upperRot);
    wings[1].display(wingOffsets[1].x, wingOffsets[1].y, -baseUpperAngle + upperRot);
    wings[2].display(wingOffsets[2].x, wingOffsets[2].y, baseLowerAngle - lowerRot);
    wings[3].display(wingOffsets[3].x, wingOffsets[3].y, -baseLowerAngle + lowerRot);
    
    drawBody();
    popMatrix();
  }

  /**
   * 计算当前颜色(循环渐变)
   * @return 当前颜色值
   */
  color currentColor() {
    final color C1 = color(0, 230, 190);    // 孔雀绿
    final color C2 = color(30, 200, 255);   // 湖蓝
    final color C3 = color(160, 160, 160, 140); // 半透明灰
    
    float t = (colorPhase % 3.0); // 3秒循环周期
    if (t < 1.0) return lerpColor(C1, C2, t);
    else if (t < 2.0) return lerpColor(C2, C3, t - 1.0);
    else return lerpColor(C3, C1, t - 2.0);
  }

  /**
   * 绘制蝴蝶身体部分
   */
  void drawBody() {
    // 绘制分段躯干
    noStroke();
    for (int i = 0; i < 6; i++) {
      fill(140, 255, 220, 60 + i * 10);
      ellipse(0, 8 + i * 6, 11 - i * 0.5, 15);
    }
    
    // 绘制头部
    fill(180, 255, 230, 250);
    ellipse(0, -12, 14, 14);
    
    // 绘制触角
    stroke(100, 220, 180, 200);
    strokeWeight(1.5);
    line(-4, -15, -8, -22);
    line(4, -15, 8, -22);
  }

  /**
   * 更新并绘制完整蝴蝶
   * @param targetPos 目标位置
   */
  void updateAndDraw(PVector targetPos) {
    setTarget(targetPos);
    update();
    display();
  }

  /**
   * 安全获取当前位置(防null)
   * @return 当前位置或屏幕中心
   */
  PVector getSafePos() {
    return pos != null ? pos.copy() : new PVector(width/2, height/2);
  }
}
