part of emulator;

enum SwipeDirection { UP, DOWN, LEFT, RIGHT }

class TapEvent {
  final num x;
  final num y;

  TapEvent(this.x, this.y);
}

class EmulatorScreen {
  static const int _SWIPE_MINOR_AXIS_THRESHOLD = 40,
      _SWIPE_MAJOR_AXIS_THRESHOLD = 80,
      _TAP_THRESHOLD = 5;
  static final CanvasElement _CANV_1x1 = new CanvasElement(width: 1, height: 1);
  static final CanvasRenderingContext2D _CTXT_1x1 = _CANV_1x1.getContext('2d');
  final int width;
  final int height;
  final CanvasElement _canvas;
  final CanvasRenderingContext2D _context;
  final Map<String, ImageElement> _images = {};
  final StreamController<TapEvent> _onTapController =
      new StreamController<TapEvent>.broadcast();
  final StreamController<SwipeDirection> _onSwipeController =
      new StreamController<SwipeDirection>.broadcast();
  Point<num> _origCoord;
  Point<num> _finalCoord;
  String _font = '20px Arial';
  String _bgColour = 'white';
  String _fgColour = 'black';
  String _textColour = 'black';
  String _strokeColour = 'black';
  num _strokeWidth = 1;

  String get font => _font;
  set font(String font) {
    if (font == null) throw new ArgumentError.notNull('font');
    _font = font;
  }

  String get bgColour => _bgColour;
  set bgColour(String bgColour) {
    if (bgColour == null) throw new ArgumentError.notNull('bgColour');
    _bgColour = bgColour;
  }

  String get fgColour => _fgColour;
  set fgColour(String fgColour) {
    if (fgColour == null) throw new ArgumentError.notNull('fgColour');
    _fgColour = fgColour;
  }

  String get textColour => _textColour;
  set textColour(String textColour) {
    if (textColour == null) throw new ArgumentError.notNull('textColour');
    _textColour = textColour;
  }

  String get strokeColour => _strokeColour;
  set strokeColour(String strokeColour) {
    if (strokeColour == null) throw new ArgumentError.notNull('strokeColour');
    _strokeColour = strokeColour;
  }

  num get strokeWidth => _strokeWidth;
  set strokeWidth(num strokeWidth) {
    if (strokeWidth == null) throw new ArgumentError.notNull('strokeWidth');
    _strokeWidth = strokeWidth;
  }

  Stream<TapEvent> get onTap => _onTapController.stream;
  Stream<SwipeDirection> get onSwipe => _onSwipeController.stream;

  factory EmulatorScreen(Element parentElem, int width, int height) {
    final canvasElem = new CanvasElement(width: width, height: height);
    parentElem.append(canvasElem);
    return new EmulatorScreen._internal(canvasElem);
  }

  EmulatorScreen._internal(CanvasElement canvas)
      : _canvas = canvas,
        _context = canvas.getContext('2d'),
        width = canvas.width,
        height = canvas.height {
    _canvas.onMouseDown.listen((me) => _origCoord = me.offset);
    _canvas.onMouseMove.listen((me) => _finalCoord = me.offset);
    _canvas.onMouseUp.listen(_mouseUp);
  }

  void _mouseUp(MouseEvent me) {
    num deltaX = _finalCoord.x - _origCoord.x;
    num deltaY = _finalCoord.y - _origCoord.y;
    SwipeDirection dir;

    if (deltaY.abs() < _SWIPE_MINOR_AXIS_THRESHOLD &&
        deltaX.abs() > _SWIPE_MAJOR_AXIS_THRESHOLD) {
      dir = deltaX.isNegative ? SwipeDirection.LEFT : SwipeDirection.RIGHT;
    } else if (deltaX.abs() < _SWIPE_MINOR_AXIS_THRESHOLD &&
        deltaY.abs() > _SWIPE_MAJOR_AXIS_THRESHOLD) {
      dir = deltaY.isNegative ? SwipeDirection.UP : SwipeDirection.DOWN;
    }

    if (dir != null) {
      _onSwipeController.add(dir);
    } else if (deltaX.abs() < _TAP_THRESHOLD && deltaY.abs() < _TAP_THRESHOLD) {
      _onTapController.add(new TapEvent(_finalCoord.x, _finalCoord.y));
    }
  }

  void begin() {
    _context.beginPath();

    // Clear drawing area
    _context.clearRect(0, 0, width, height);
    drawRect(0, 0, width, height, colour: _bgColour);
  }

  void drawRect(num x, num y, num w, num h, {String colour}) {
    _context.fillStyle = colour == null ? _fgColour : colour;
    _context.fillRect(x, y, w, h);
  }

  void innerStrokeRect(num x, num y, num w, num h,
      {String colour, num strokeWidth}) {
    _context.lineWidth = strokeWidth == null ? _strokeWidth : strokeWidth;
    _context.strokeStyle = colour == null ? _strokeColour : colour;
    _context.strokeRect(x + _context.lineWidth / 2, y + _context.lineWidth / 2,
        w - _context.lineWidth, h - _context.lineWidth);
  }

  void drawRectWithInnerStroke(num x, num y, num w, num h,
      {String fillColour, String strokeColour, num strokeWidth}) {
    drawRect(x, y, w, h, colour: fillColour);
    innerStrokeRect(x, y, w, h, colour: strokeColour, strokeWidth: strokeWidth);
  }

  void drawText(String text, num x, num y,
      {String font, String colour, String align}) {
    _context.font = font == null ? _font : font;
    _context.textAlign = align == null ? 'left' : align;
    _context.fillStyle = colour == null ? _textColour : colour;
    _context.fillText(text, x, y);
  }

  void drawImage(String imageName, num x, num y, [num w, num h]) {
    if (!_images.containsKey(imageName)) {
      _images[imageName] = new ImageElement();
      _images[imageName].src = 'assets/img/$imageName.png';
    }
    _context.drawImageScaled(_images[imageName], x, y, w, h);
  }

  num textWidth(String text, {String font}) {
    _context.font = font == null ? _font : font;
    return _context.measureText(text).width;
  }

  void end() {
    _context.closePath();
  }

  static final RegExp _RGBA_BLACK = new RegExp(r'^rgba?\(0+(,0+){2}');
  static final RegExp _HSLA_BLACK =
      new RegExp(r'^hsla?\(\d+(\.\d+)?,\d+(\.\d+)%,0+(\.0+)%');

  static String getColourWithAlpha(String colour, num alpha) {
    if (colour == null) throw new ArgumentError.notNull('colour');
    _CTXT_1x1.clearRect(0, 0, 1, 1);
    _CTXT_1x1.fillStyle = colour;
    _CTXT_1x1.globalAlpha = 1.0;
    _CTXT_1x1.strokeStyle = null;
    _CTXT_1x1.fillRect(0, 0, 1, 1);
    List<int> d = _CTXT_1x1.getImageData(0, 0, 1, 1).data;
    int r = d[0], g = d[1], b = d[2];

    if (r + g + b == 0 &&
        !(colour.toLowerCase() == 'black' ||
            colour == '#000' ||
            colour == '#000000' ||
            _RGBA_BLACK.firstMatch(colour.replaceAll(r' ', '')) != null ||
            _HSLA_BLACK.firstMatch(colour.replaceAll(r' ', '')) != null)) {
      return null;
    }

    return 'rgba($r, $g, $b, $alpha)';
  }
}
