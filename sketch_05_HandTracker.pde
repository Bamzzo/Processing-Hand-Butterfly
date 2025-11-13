import processing.video.*;
import gab.opencv.*;
import java.util.*;
import java.awt.*;

/**
 * 手势追踪类，负责摄像头输入处理和手势识别
 */
class HandTracker {

  // 外部可访问的检测状态
  boolean handDetected = false;  // 是否检测到手部
  boolean openPalm     = false;  // 检测到张开手掌
  boolean closedFist   = false;  // 检测到握拳
  PVector handPos      = new PVector();  // 手部中心位置
  PImage  maskView, camView;     // 掩膜视图和摄像头视图
  Rectangle lastBox, ROI_RECT;   // 手部边界框和检测区域

  // 手势识别阈值参数
  float AREA_OPEN_MAX = 0.46f;  // 张开手掌的最大面积比阈值
  float AREA_FIST_MIN = 0.50f;  // 握拳的最小面积比阈值
  float smoothRatio   = 0;      // 平滑处理后的面积比
  final float ALPHA   = 0.30f;  // 平滑系数

  // HSV肤色范围阈值
  final int H1_MIN =   0, H1_MAX =  40;  // 色调范围1
  final int H2_MIN = 200, H2_MAX = 255;  // 色调范围2
  final int S_MIN  =  20, S_MAX = 255;   // 饱和度范围
  final int V_MIN  =  60, V_MAX = 255;   // 明度范围

  // 手部检测过滤参数
  final float MIN_ASPECT = 0.45f, MAX_ASPECT = 1.60f;  // 宽高比范围
  final int   MIN_HAND_PIXELS = 1500;  // 最小手部像素面积
  final int   MAX_HAND_PIXELS = 20000; // 最大手部像素面积

  // 系统对象和尺寸
  final int frameW, frameH;  // 帧宽度和高度
  Capture cam; OpenCV opencv; PApplet parent;  // 摄像头和图像处理对象

  /**
   * 构造函数
   * @param p Processing父对象
   * @param w 摄像头宽度
   * @param h 摄像头高度
   */
  HandTracker(PApplet p, int w, int h) {
    parent = p; frameW = w; frameH = h;

    // 初始化摄像头
    cam = new Capture(p, w, h);  cam.start();
    camView = p.createImage(w, h, p.RGB);
    opencv  = new OpenCV(p, w, h);

    // 设置初始检测区域(ROI)
    ROI_RECT = new Rectangle(
      (int)(w * 0.20f), (int)(h * 0.10f),
      (int)(w * 0.60f), (int)(h * 0.80f)
    );
  }

  /**
   * 每帧更新手势检测状态
   */
  void update() {
    // 1. 获取摄像头帧
    if (cam.available()) cam.read();
    camView.copy(cam,0,0,cam.width,cam.height,0,0,cam.width,cam.height);
    camView.updatePixels();

    // 2. 创建肤色掩膜
    maskView = makeSkinMask(camView);

    // 3. 在ROI内查找轮廓
    opencv.loadImage(maskView);
    opencv.setROI(ROI_RECT.x, ROI_RECT.y, ROI_RECT.width, ROI_RECT.height);
    erodeN(opencv, 2);  dilateN(opencv, 4);  // 形态学操作
    ArrayList<Contour> cs = opencv.findContours();
    opencv.releaseROI();

    if (cs.isEmpty()) { reset(); return; }

    // 4. 查找最大轮廓
    Contour largest = null; float maxA = 0;
    for (Contour c : cs) if (c.area() > maxA) { largest = c; maxA = c.area(); }
    if (largest == null) { reset(); return; }

    // 4.1 计算全局坐标边界框
    Rectangle box = largest.getBoundingBox();
    box.translate(ROI_RECT.x, ROI_RECT.y);
    lastBox = box;

    // 宽高比过滤
    float aspect = box.width / (float) box.height;
    if (aspect < MIN_ASPECT || aspect > MAX_ASPECT) { reset(); return; }

    // 4.2 计算手部像素面积
    int pixArea = 0; maskView.loadPixels();
    for (int y = box.y; y < box.y + box.height; y++) {
      int row = y * frameW;
      for (int x = box.x; x < box.x + box.width; x++)
        if (maskView.pixels[row + x] == parent.color(255)) pixArea++;
    }
    // 面积过滤
    if (pixArea < MIN_HAND_PIXELS || pixArea > MAX_HAND_PIXELS) { reset(); return; }

    // 4.3 计算手部质心
    ArrayList<PVector> pts = largest.getPolygonApproximation().getPoints();
    float cx = 0, cy = 0;
    for (PVector pt : pts) { cx += pt.x; cy += pt.y; }
    cx = cx / pts.size() + ROI_RECT.x;
    cy = cy / pts.size() + ROI_RECT.y;
    handPos.set(cx, cy, 0);

    // 4.4 计算面积比并识别手势
    float ratio = pixArea / (float) (box.width * box.height);
    smoothRatio = ALPHA * ratio + (1 - ALPHA) * smoothRatio;  // 指数平滑

    handDetected = true;
    openPalm     = smoothRatio <= AREA_OPEN_MAX;
    closedFist   = smoothRatio >= AREA_FIST_MIN;

    // 调试信息输出
    if (parent.keyPressed && parent.key == 'c')
      parent.println("smoothRatio = " + parent.nf(smoothRatio, 1, 3));

    // 5. 键盘调整阈值
    if (parent.keyPressed) {
      if (parent.key == '[') AREA_OPEN_MAX = max(0.30f, AREA_OPEN_MAX - 0.02f);
      if (parent.key == ']') AREA_OPEN_MAX = min(0.60f, AREA_OPEN_MAX + 0.02f);
      if (parent.key == '-') AREA_FIST_MIN = max(0.40f, AREA_FIST_MIN - 0.02f);
      if (parent.key == '=') AREA_FIST_MIN = min(0.70f, AREA_FIST_MIN + 0.02f);
    }
  }

  // 获取摄像头视图
  PImage    getView() { return camView; }
  // 获取掩膜视图
  PImage    getMask() { return maskView; }
  // 获取手部边界框
  Rectangle getBox () { return lastBox; }
  // 获取检测区域
  Rectangle getROI () { return ROI_RECT; }

  // 重置检测状态
  void reset() { handDetected = openPalm = closedFist = false; lastBox = null; }

  /**
   * 创建HSV肤色掩膜
   * @param src 源图像
   * @return 二值化掩膜图像
   */
  PImage makeSkinMask(PImage src) {
    PImage m = parent.createImage(src.width, src.height, parent.ALPHA);
    src.loadPixels(); m.loadPixels();
    parent.colorMode(parent.HSB, 255);
    for (int i = 0; i < src.pixels.length; i++) {
      int c = src.pixels[i];
      float h = parent.hue(c), s = parent.saturation(c), v = parent.brightness(c);
      // 肤色判断逻辑
      boolean skin =
        (((h >= H1_MIN && h <= H1_MAX) || (h >= H2_MIN && h <= H2_MAX)) &&
          s >= S_MIN && s <= S_MAX &&
          v >= V_MIN && v <= V_MAX);
      m.pixels[i] = skin ? parent.color(255) : parent.color(0);
    }
    m.updatePixels();
    parent.colorMode(parent.RGB, 255);
    return m;
  }

  // N次膨胀操作
  private void dilateN(OpenCV cv, int n) { for (int i = 0; i < n; i++) cv.dilate(); }
  // N次腐蚀操作
  private void erodeN (OpenCV cv, int n) { for (int i = 0; i < n; i++) cv.erode();  }
  
  /**
   * 绘制调试覆盖层（ROI区域和手部边界框）
   */
  public void drawDebugOverlay() {
    if (parent == null) return;
    
    // 绘制ROI区域（绿色框）
    parent.stroke(0, 255, 0);
    parent.strokeWeight(2);
    parent.noFill();
    parent.rect(ROI_RECT.x, ROI_RECT.y, ROI_RECT.width, ROI_RECT.height);
    
    // 检测到手部时绘制边界框（红色框）
    if (handDetected && lastBox != null) {
      parent.stroke(255, 0, 0);
      parent.strokeWeight(2);
      parent.noFill();
      parent.rect(lastBox.x, lastBox.y, lastBox.width, lastBox.height);
      
      // 显示手势状态文本
      parent.fill(255);
      parent.textSize(16);
      String gesture = "";
      if (openPalm) gesture = "Open Palm";
      else if (closedFist) gesture = "Closed Fist";
      else gesture = "Unknown";
      
      parent.text("Gesture: " + gesture, lastBox.x, lastBox.y - 10);
    }
    
    // 显示当前阈值信息
    parent.fill(255);
    parent.textSize(14);
    parent.textAlign(parent.LEFT, parent.TOP);
    parent.text("Open Threshold: " + parent.nf(AREA_OPEN_MAX, 1, 2), 10, 10);
    parent.text("Fist Threshold: " + parent.nf(AREA_FIST_MIN, 1, 2), 10, 30);
  }
}
