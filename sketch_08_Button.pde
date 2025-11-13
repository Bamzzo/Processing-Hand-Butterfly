/**
 * UI按钮类
 * 用于游戏中的交互按钮
 */
class Button {
  float x, y, w, h;    // 位置和尺寸
  String label;         // 按钮文本
  color baseColor = color(0, 200, 0);       // 基础颜色
  color highlightColor = color(0, 255, 0);  // 高亮颜色
  color currentColor;   // 当前颜色
  PFont buttonFont;     // 按钮字体
  
  /**
   * 构造函数
   * @param x X坐标
   * @param y Y坐标
   * @param w 宽度
   * @param h 高度
   * @param label 显示文本
   */
  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.currentColor = baseColor;
    this.buttonFont = createFont("Arial", 16);  // 创建字体
  }
  
  /** 绘制按钮 */
  void display() {
    // 绘制按钮背景（圆角矩形）
    fill(currentColor);
    stroke(0, 150, 0);
    strokeWeight(2);
    rect(x, y, w, h, 5);  // 圆角半径5
    
    // 绘制按钮文本（居中）
    fill(255);
    textFont(buttonFont);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }
  
  /** 鼠标悬停高亮效果 */
  void highlight() {
    currentColor = highlightColor;
  }
  
  /** 取消高亮 */
  void unhighlight() {
    currentColor = baseColor;
  }
  
  /** 
   * 检测鼠标是否在按钮上
   * @return 是否悬停
   */
  boolean isMouseOver() {
    return mouseX > x && mouseX < x + w && 
           mouseY > y && mouseY < y + h;
  }
}
