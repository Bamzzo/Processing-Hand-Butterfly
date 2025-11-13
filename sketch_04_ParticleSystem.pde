class ParticleSystem {
  // 存储拖尾粒子
  ArrayList<Particle> trail = new ArrayList<Particle>();
  // 存储爆炸粒子
  ArrayList<GlowParticle> burst = new ArrayList<GlowParticle>();

  /**
   * 在指定位置添加拖尾粒子
   * @param pos 粒子生成位置坐标
   */
  void addTrail(PVector pos) {
    for (int i = 0; i < 2; i++)
      trail.add(new Particle(pos));
  }

  /**
   * 在指定位置创建爆炸效果
   * @param origin 爆炸中心位置坐标
   */
  void burst(PVector origin) {
    for (int i = 0; i < 80; i++)
      burst.add(new GlowParticle(origin));
  }

  /**
   * 更新并绘制所有粒子
   */
  void run() {
    // 更新拖尾粒子
    for (int i = trail.size()-1; i >= 0; i--) {
      Particle p = trail.get(i);
      p.update(); p.display();
      if (p.isDead()) trail.remove(i);
    }
    // 更新爆炸粒子
    for (int i = burst.size()-1; i >= 0; i--) {
      GlowParticle g = burst.get(i);
      g.update(); g.display();
      if (g.isDead()) burst.remove(i);
    }
  }
  
  // 别名方法，与run()功能相同
  void updateAndDraw() { run(); }
  
  /**
   * 重置粒子系统状态
   * @param start 重置起始位置（当前未使用）
   */
  void reset(PVector start) { 
    trail.clear(); 
    burst.clear();
  }
  
  /**
   * 在指定位置触发爆炸效果
   * @param origin 爆炸中心位置坐标
   */
  void explode(PVector origin) {
    // 位置有效性检查
    if (origin == null) {
      println("警告：粒子爆炸位置无效");
      return;
    }
    
    try {
      // 生成爆炸粒子
      for (int i = 0; i < 80; i++) {
        burst.add(new GlowParticle(origin));
      }
    } catch (Exception e) {
      println("粒子爆炸创建失败: " + e.getMessage());
    }
  }
}
