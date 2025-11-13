/**
 * 基础粒子类，用于拖尾效果
 */
class Particle {
  PVector pos, vel;  // 位置和速度向量
  float alpha;       // 透明度
  float size;        // 粒子大小

  /**
   * 构造函数
   * @param start 初始位置
   */
  Particle(PVector start) {
    pos = start.copy();
    vel = PVector.random2D().mult(random(0.3, 0.7));
    alpha = 180;
    size = random(1.5, 3.0);
  }

  /**
   * 更新粒子状态
   */
  void update() {
    pos.add(vel);
    vel.mult(0.98);  // 速度衰减
    alpha -= 1.5;    // 透明度衰减
  }

  /**
   * 绘制粒子
   */
  void display() {
    noStroke();
    fill(80, 255, 200, alpha);
    ellipse(pos.x, pos.y, size, size*1.4);
  }

  /**
   * 判断粒子是否应被移除
   * @return 透明度<=0时返回true
   */
  boolean isDead() {
    return alpha <= 0;
  }
}
