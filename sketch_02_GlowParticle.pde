/**
 * 发光粒子类，用于爆炸特效
 */
class GlowParticle {
  PVector pos, vel;  // 位置和速度向量
  float life;        // 生命周期
  float size;        // 粒子大小
  color c;           // 粒子颜色

  /**
   * 构造函数
   * @param origin 发射原点
   */
  GlowParticle(PVector origin) {
    pos = origin.copy();
    vel = PVector.random2D().mult(random(1.5, 4));
    life = 255;
    size = random(4, 10);
    c = color(120, 255, 180);
  }

  /**
   * 更新粒子状态
   */
  void update() {
    pos.add(vel);
    vel.mult(0.96);  // 速度衰减
    life -= 2.0;     // 生命周期衰减
  }

  /**
   * 绘制发光粒子(使用ADD混合模式)
   */
  void display() {
    pushStyle();
    blendMode(ADD);
    noStroke();
    fill(c, life);
    ellipse(pos.x, pos.y, size, size);
    popStyle();
  }

  /**
   * 判断粒子是否应被移除
   * @return 生命周期<=0时返回true
   */
  boolean isDead() {
    return life <= 0;
  }
}
