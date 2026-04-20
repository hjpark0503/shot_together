import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';

// Web-only imports
import 'camera_illustration.dart' if (dart.library.io) 'camera_illustration_stub.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
import 'share_stub.dart'
    if (dart.library.html) 'share_web.dart';

List<CameraDescription> cameras = [];

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) registerCameraIllustration();
  try {
    cameras = await availableCameras();
  } catch (_) {}
  final sharedPhotos = kIsWeb ? await parseSharedPhotos() : null;
  runApp(ShotTogetherApp(sharedPhotos: sharedPhotos));
}

class ShotTogetherApp extends StatelessWidget {
  final List<Uint8List>? sharedPhotos;
  const ShotTogetherApp({super.key, this.sharedPhotos});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shot Together',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'serif',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC2839),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: sharedPhotos != null
          ? ResultPage(photos: sharedPhotos!, isSharedView: true)
          : const HomePage(),
    );
  }
}

// ── 색상 팔레트 (빈티지 카메라 테마) ──────────────────
const _bgColor      = Color(0xFF18130F);
const _surfaceColor = Color(0xFF241E18);
const _redAccent    = Color(0xFFDC2839);
const _creamText    = Color(0xFFF0E8D0);
const _mutedText    = Color(0xFF9A8C7A);
const _borderColor  = Color(0xFF3A3028);

// ─────────────────────────────────────────────────────
// 1) 홈 화면
// ─────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final List<Uint8List>? sharedPhotos;
  const HomePage({super.key, this.sharedPhotos});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _count = 1;

  int get _maxCount => 8 - (widget.sharedPhotos?.length ?? 0);

  @override
  void initState() {
    super.initState();
    _count = _count.clamp(1, _maxCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCameraIllustration(),
                    const SizedBox(height: 32),
                    _buildTitle(),
                    if (widget.sharedPhotos != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _redAccent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, color: _redAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '공유된 사진 ${widget.sharedPhotos!.length}장 포함됨',
                              style: const TextStyle(color: _creamText, fontSize: 13, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    _buildDivider(),
                    const SizedBox(height: 32),
                    _buildCountSelector(),
                    const SizedBox(height: 40),
                    _buildStartButton(),
                    const SizedBox(height: 16),
                    Text(
                      '촬영 전 3초 카운트다운이 시작됩니다',
                      style: TextStyle(color: _mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraIllustration() {
    if (!kIsWeb) {
      return const Icon(Icons.camera_alt_rounded,
          color: _redAccent, size: 80);
    }
    return SizedBox(
      width: 134,
      height: 90,
      child: HtmlElementView(viewType: 'css-camera'),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'SHOT TOGETHER',
          style: TextStyle(
            color: _creamText,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'P H O T O   B O O T H',
          style: TextStyle(
            color: _mutedText,
            fontSize: 12,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(child: Divider(color: _borderColor, thickness: 1)),
      ],
    );
  }

  Widget _buildCountSelector() {
    return Column(
      children: [
        Text(
          '사진 매수 선택',
          style: TextStyle(
            color: _mutedText,
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepBtn(Icons.remove, _count > 1
                ? () => setState(() => _count--)
                : null),
            const SizedBox(width: 36),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Column(
                key: ValueKey(_count),
                children: [
                  Text(
                    '$_count',
                    style: const TextStyle(
                      color: _creamText,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 36),
            _stepBtn(Icons.add, _count < _maxCount
                ? () => setState(() => _count++)
                : null),
          ],
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? _redAccent : _surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? _redAccent : _borderColor,
            width: 1.5,
          ),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : _mutedText, size: 24),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShootingPage(
              totalCount: _count,
              preloadedPhotos: widget.sharedPhotos ?? const [],
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 22),
            const SizedBox(width: 8),
            Text(
              widget.sharedPhotos != null ? 'SHOOT  $_count  MORE' : 'SHOOT  $_count  PHOTOS',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 2) 촬영 화면
// ─────────────────────────────────────────────────────
class ShootingPage extends StatefulWidget {
  final int totalCount;
  final List<Uint8List> preloadedPhotos;
  const ShootingPage({super.key, required this.totalCount, this.preloadedPhotos = const []});

  @override
  State<ShootingPage> createState() => _ShootingPageState();
}

class _ShootingPageState extends State<ShootingPage> {
  CameraController? _ctrl;
  bool _ready = false;
  String? _error;

  final List<Uint8List> _newPhotos = [];
  bool _shooting = false;
  int _countdown = 0;
  bool _flash = false;
  bool _done = false;

  List<Uint8List> get _allPhotos => [...widget.preloadedPhotos, ..._newPhotos];

  @override
  void initState() {
    super.initState();
    _initCam();
  }

  Future<void> _initCam() async {
    if (cameras.isEmpty) {
      setState(() => _error = '카메라를 찾을 수 없습니다.');
      return;
    }
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _ctrl = CameraController(cam, ResolutionPreset.high, enableAudio: false);
    try {
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      setState(
          () => _error = '카메라 권한이 필요합니다.\n브라우저에서 허용을 눌러주세요.');
    }
  }

  Future<void> _retakeSingle(int index) async {
    if (!_ready || _shooting) return;
    final newIndex = index - widget.preloadedPhotos.length;
    if (newIndex < 0 || newIndex >= _newPhotos.length) return;
    setState(() { _shooting = true; _done = false; });

    for (int c = 3; c >= 1; c--) {
      if (!mounted) return;
      setState(() => _countdown = c);
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() => _countdown = 0);

    setState(() => _flash = true);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _flash = false);

    try {
      final file = await _ctrl!.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _newPhotos[newIndex] = bytes);
    } catch (_) {}

    if (mounted) setState(() { _shooting = false; _done = true; });
  }

  void _openPhotoDetail(int index) {
    final isPreloaded = index < widget.preloadedPhotos.length;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PhotoDetailDialog(
        photo: _allPhotos[index],
        index: index,
        onRetake: isPreloaded ? null : () {
          Navigator.pop(context);
          _retakeSingle(index);
        },
      ),
    );
  }

  Future<void> _shoot() async {
    if (!_ready || _shooting) return;
    setState(() { _shooting = true; _newPhotos.clear(); _done = false; });

    for (int i = 0; i < widget.totalCount; i++) {
      for (int c = 3; c >= 1; c--) {
        if (!mounted) return;
        setState(() => _countdown = c);
        await Future.delayed(const Duration(seconds: 1));
      }
      setState(() => _countdown = 0);

      // 셔터
      setState(() => _flash = true);
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => _flash = false);

      try {
        final file = await _ctrl!.takePicture();
        final bytes = await file.readAsBytes();
        if (mounted) setState(() => _newPhotos.add(bytes));
      } catch (_) {}

      if (i < widget.totalCount - 1) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
    if (mounted) setState(() { _shooting = false; _done = true; });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 720;
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: wide ? _wideLayout() : _narrowLayout(),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderColor),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: _creamText, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'SHOT TOGETHER',
            style: TextStyle(
              color: _creamText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          // 필름 카운터
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: _redAccent, size: 8),
                const SizedBox(width: 6),
                Text(
                  '${_allPhotos.length.toString().padLeft(2, '0')} / ${(widget.preloadedPhotos.length + widget.totalCount).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: _creamText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 가로: 카메라(좌) + 필름스트립(우)
  Widget _wideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _cameraArea()),
              const SizedBox(width: 20),
              SizedBox(width: 180, child: _filmStrip(horizontal: false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _narrowLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const stripH = 140.0;
        const gap = 16.0;
        const pad = 16.0;
        final camH = (constraints.maxHeight - stripH - gap - pad * 2).clamp(180.0, double.infinity);
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(pad),
                child: Column(
                  children: [
                    SizedBox(height: camH, child: _cameraArea()),
                    const SizedBox(height: gap),
                    SizedBox(height: stripH, child: _filmStrip(horizontal: true)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cameraArea() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 카메라 뷰
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              border: Border.all(color: _borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _cameraPreview(),
          ),
        ),
        // 플래시 오버레이
        if (_flash)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        // 카운트다운
        if (_countdown > 0)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 30)],
                ),
              ),
            ),
          ),
        // 완료 배지
        if (_done)
          Positioned(
            top: 16, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: _redAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'ALL SHOTS TAKEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cameraPreview() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, color: _mutedText, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _mutedText, fontSize: 14)),
          ],
        ),
      );
    }
    if (!_ready) {
      return const Center(
          child: CircularProgressIndicator(color: _redAccent, strokeWidth: 2));
    }
    return CameraPreview(_ctrl!);
  }

  // 필름 스트립 위젯
  Widget _filmStrip({required bool horizontal}) {
    final slots = widget.preloadedPhotos.length + widget.totalCount;

    return ScrollConfiguration(
      behavior: const _NoScrollbarBehavior(),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0806),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _borderColor),
        ),
        child: horizontal ? _filmHorizontal(slots) : _filmVertical(slots),
      ),
    );
  }

  Widget _filmVertical(int slots) {
    return Row(
      children: [
        _sprocketCol(vertical: true),
        Expanded(child: _photoSlots(slots, horizontal: false)),
        _sprocketCol(vertical: true),
      ],
    );
  }

  Widget _filmHorizontal(int slots) {
    return Column(
      children: [
        _sprocketRow(),
        Expanded(child: _photoSlots(slots, horizontal: true)),
        _sprocketRow(),
      ],
    );
  }

  Widget _sprocketCol({required bool vertical}) {
    return SizedBox(
      width: 16,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemExtent: 24,
        itemCount: 30,
        itemBuilder: (_, __) => Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2420),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sprocketRow() {
    return SizedBox(
      height: 16,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemExtent: 24,
        itemCount: 30,
        itemBuilder: (_, __) => Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2420),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoSlots(int slots, {required bool horizontal}) {
    return ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.all(8),
      itemCount: slots,
      separatorBuilder: (_, __) => const SizedBox(width: 8, height: 8),
      itemBuilder: (_, i) {
        final all = _allPhotos;
        final hasPhoto = i < all.length;
        final tappable = _done && hasPhoto;
        return GestureDetector(
          onTap: tappable ? () => _openPhotoDetail(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: horizontal ? 90 : double.infinity,
            height: horizontal ? double.infinity : 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1410),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: hasPhoto ? _redAccent : _borderColor,
                width: hasPhoto ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhoto)
                    Image.memory(all[i], fit: BoxFit.cover)
                  else
                    Center(
                      child: Text(
                        (i + 1).toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: _borderColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  if (tappable)
                    Positioned(
                      right: 4, bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(Icons.zoom_in,
                            color: Colors.white70, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: _done
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _outlineBtn(
                  icon: Icons.replay_rounded,
                  label: 'RETAKE',
                  onTap: _shoot,
                ),
                const SizedBox(width: 16),
                _solidBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'GET A PHOTO',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultPage(photos: List.from(_allPhotos)),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: GestureDetector(
                onTap: (_ready && !_shooting) ? _shoot : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_ready && !_shooting) ? _redAccent : _surfaceColor,
                    border: Border.all(
                      color: (_ready && !_shooting)
                          ? _redAccent
                          : _borderColor,
                      width: 2,
                    ),
                    boxShadow: (_ready && !_shooting)
                        ? [
                            BoxShadow(
                              color: _redAccent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: _shooting
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 30),
                ),
              ),
            ),
    );
  }

  Widget _outlineBtn(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: _mutedText, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: _mutedText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _solidBtn(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _redAccent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 3) 사진 상세 다이얼로그
// ─────────────────────────────────────────────────────
class _PhotoDetailDialog extends StatelessWidget {
  final Uint8List photo;
  final int index;
  final VoidCallback? onRetake;

  const _PhotoDetailDialog({
    required this.photo,
    required this.index,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final maxImgHeight = MediaQuery.of(context).size.height * 0.55;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 바
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Text(
                      'PHOTO  ${(index + 1).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: _creamText,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _borderColor),
                      ),
                      child: const Icon(Icons.close, color: _creamText, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 사진
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxImgHeight),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _borderColor, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.memory(photo, fit: BoxFit.contain),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // 버튼 바
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _borderColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: _mutedText, size: 16),
                          const SizedBox(width: 8),
                          Text('CLOSE',
                              style: TextStyle(
                                color: _mutedText,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                if (onRetake != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onRetake,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.replay_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('RETAKE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                ],  // end if (onRetake != null)
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 4) 공유 성공 다이얼로그
// ─────────────────────────────────────────────────────
class _ShareSuccessDialog extends StatelessWidget {
  final String url;
  const _ShareSuccessDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: _redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              const Text(
                'URL이 생성되었습니다.',
                style: TextStyle(color: _creamText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              const Text(
                'URL을 공유해보세요!',
                style: TextStyle(color: _mutedText, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text('CLOSE',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 5) 결과 화면
// ─────────────────────────────────────────────────────
// 테마 정의: asset 경로, footer 텍스트 색, 사진 프레임 스타일
enum StripTheme { film, star, mist, bloom, choco, deco }

class _ThemeMeta {
  final String label;
  final String? asset;
  final Color footerColor;
  const _ThemeMeta({required this.label, this.asset, required this.footerColor});
}

const _themeMeta = {
  StripTheme.film:  _ThemeMeta(label: 'FILM',  asset: null,             footerColor: Color(0xFF9A8C7A)),
  StripTheme.star:  _ThemeMeta(label: 'STAR',  asset: 'assets/5.jpg',   footerColor: Color(0xFF6B8A3A)),
  StripTheme.mist:  _ThemeMeta(label: 'MIST',  asset: 'assets/9.jpg',   footerColor: Color(0xFF6A90A0)),
  StripTheme.bloom: _ThemeMeta(label: 'BLOOM', asset: 'assets/10.png',  footerColor: Color(0xFF9A88BB)),
  StripTheme.choco: _ThemeMeta(label: 'CHOCO', asset: 'assets/4.jpg',        footerColor: Color(0xFFD4B89A)),
  StripTheme.deco:  _ThemeMeta(label: 'PLAID', asset: 'assets/6.jpg',          footerColor: Color(0xFF6A90B8)),
};

class ResultPage extends StatefulWidget {
  final List<Uint8List> photos;
  final bool isSharedView;
  const ResultPage({super.key, required this.photos, this.isSharedView = false});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _vertical = true;
  bool _twoRows = false;
  bool _downloading = false;
  bool _sharing = false;
  StripTheme _selectedTheme = StripTheme.film;
  final _stripKey = GlobalKey();

  String get _dateStr {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2,'0')}.${now.day.toString().padLeft(2,'0')}';
  }

  _ThemeMeta get _meta => _themeMeta[_selectedTheme]!;

  Decoration _stripDecoration() {
    final asset = _meta.asset;
    if (asset == null) return const BoxDecoration(color: Color(0xFF080604));
    return BoxDecoration(
      image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
    );
  }

  Widget _photoFrame(Uint8List photo, double w, double h) {
    return switch (_selectedTheme) {
      StripTheme.film => ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.memory(photo, width: w, height: h, fit: BoxFit.cover),
        ),
      StripTheme.star => SizedBox(
          width: w, height: h,
          child: Image.memory(photo, fit: BoxFit.cover),
        ),
      StripTheme.mist => SizedBox(
          width: w, height: h,
          child: Image.memory(photo, fit: BoxFit.cover),
        ),
      StripTheme.bloom => SizedBox(
          width: w, height: h,
          child: Image.memory(photo, fit: BoxFit.cover),
        ),
      StripTheme.choco => SizedBox(
          width: w, height: h,
          child: Image.memory(photo, fit: BoxFit.cover),
        ),
      StripTheme.deco => SizedBox(
          width: w, height: h,
          child: Image.memory(photo, fit: BoxFit.cover),
        ),
    };
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final boundary =
          _stripKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      if (kIsWeb) _webDownload(bytes);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _webDownload(Uint8List bytes) {
    if (!kIsWeb) return;
    triggerWebDownload(bytes, 'shot_together_$_dateStr.png');
  }

  Future<void> _share() async {
    if (widget.photos.length >= 8) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _borderColor),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: _surfaceColor, shape: BoxShape.circle),
                    child: const Icon(Icons.block_rounded, color: _mutedText, size: 22),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '공유할 수 없습니다.',
                    style: TextStyle(color: _creamText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '8장은 최대 장수입니다.\n공유 시 추가 촬영이 불가능합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _mutedText, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _borderColor, width: 1.5),
                        ),
                        child: const Center(
                          child: Text('CLOSE', style: TextStyle(color: _mutedText, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _sharing = true);
    try {
      final url = await buildShareUrl(widget.photos);
      if (url == null) throw Exception('URL 생성 실패');
      await copyToClipboard(url);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _ShareSuccessDialog(url: url),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share 오류: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildControls(),
            Expanded(child: _buildStripArea()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          if (!widget.isSharedView) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderColor),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: _creamText, size: 16),
              ),
            ),
            const SizedBox(width: 16),
          ],
          const Text(
            'GET A PHOTO',
            style: TextStyle(
              color: _creamText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              '${widget.photos.length.toString().padLeft(2,'0')}  SHOTS',
              style: const TextStyle(
                color: _mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final canTwoRows = widget.photos.length >= 4;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // ── 레이아웃 토글 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _toggleBtn(icon: Icons.table_rows_outlined, selected: _vertical,  onTap: () => setState(() => _vertical = true)),
              const SizedBox(width: 6),
              _toggleBtn(icon: Icons.view_column_outlined, selected: !_vertical, onTap: () => setState(() => _vertical = false)),
              if (canTwoRows) ...[
                const SizedBox(width: 6),
                _toggleBtn(icon: Icons.grid_view_rounded,  selected: _twoRows,  onTap: () => setState(() => _twoRows = !_twoRows)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // ── 테마 선택 ──
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: StripTheme.values.map((t) {
                final meta = _themeMeta[t]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _themeCard(t, meta),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeCard(StripTheme theme, _ThemeMeta meta) {
    final selected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _redAccent : _borderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _redAccent.withValues(alpha: 0.25), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 8 : 9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경
              meta.asset != null
                  ? Image.asset(meta.asset!, fit: BoxFit.cover)
                  : _filmThumbBg(),
              // 하단 그라디언트 + 라벨
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Text(
                    meta.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              // 선택 표시
              if (selected)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: _redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filmThumbBg() {
    return Container(
      color: const Color(0xFF0A0806),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 필름 구멍 패턴
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (_) => Container(
              width: 8, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2420),
                borderRadius: BorderRadius.circular(1),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1614),
              borderRadius: BorderRadius.circular(1),
            ),
            child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF3A3028), size: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (_) => Container(
              width: 8, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2420),
                borderRadius: BorderRadius.circular(1),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn({required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? _redAccent : _surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? _redAccent : _borderColor, width: 1.5),
        ),
        child: Icon(icon, color: selected ? Colors.white : _mutedText, size: 16),
      ),
    );
  }

  Widget _buildStripArea() {
    final strip = RepaintBoundary(
      key: _stripKey,
      child: _vertical ? _buildVerticalStrip() : _buildHorizontalStrip(),
    );

    if (!_vertical) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScrollConfiguration(
            behavior: const _NoScrollbarBehavior(),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: strip,
              ),
            ),
          ),
        ],
      );
    }

    return ScrollConfiguration(
      behavior: const _NoScrollbarBehavior(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: strip),
      ),
    );
  }

  // ── 세로 나열 스트립 ──
  Widget _buildVerticalStrip() {
    const photoW = 300.0;
    const photoH = 225.0;
    const padH = 24.0;
    const padV = 20.0;
    final isFilm = _selectedTheme == StripTheme.film;
    const gap = 4.0;
    const totalW = photoW + padH * 2;

    if (_twoRows) {
      final colW = (photoW - gap) / 2;
      final rows = (widget.photos.length / 2).ceil();
      return Container(
        width: totalW,
        decoration: _stripDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFilm) _filmEdgeH(width: totalW),
            const SizedBox(height: padV),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: padH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rows, (r) {
                  final left = r * 2;
                  final right = r * 2 + 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: r < rows - 1 ? gap : 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _photoFrame(widget.photos[left], colW, photoH * 0.75),
                        SizedBox(width: gap),
                        if (right < widget.photos.length)
                          _photoFrame(widget.photos[right], colW, photoH * 0.75)
                        else
                          SizedBox(width: colW, height: photoH * 0.75),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: padV),
            _stripFooter(width: totalW),
            if (isFilm) _filmEdgeH(width: totalW),
          ],
        ),
      );
    }

    return Container(
      width: totalW,
      decoration: _stripDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFilm) _filmEdgeH(width: totalW),
          const SizedBox(height: padV),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: padH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.photos.length, (i) => Padding(
                padding: EdgeInsets.only(bottom: i < widget.photos.length - 1 ? gap : 0),
                child: _photoFrame(widget.photos[i], photoW, photoH),
              )),
            ),
          ),
          const SizedBox(height: padV),
          _stripFooter(width: totalW),
          if (isFilm) _filmEdgeH(width: totalW),
        ],
      ),
    );
  }

  // ── 가로 나열 스트립 ──
  Widget _buildHorizontalStrip() {
    const photoW = 230.0;
    const photoH = 173.0;
    const padH = 20.0;
    const padV = 20.0;
    final isFilm = _selectedTheme == StripTheme.film;
    const gap = 4.0;

    if (_twoRows) {
      final cols = (widget.photos.length / 2).ceil();
      final totalW = photoW * cols + gap * (cols - 1) + padH * 2;
      const rowH = photoH - 30;
      return Container(
        decoration: _stripDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFilm) _filmEdgeH(width: totalW),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(cols, (c) => Padding(
                      padding: EdgeInsets.only(right: c < cols - 1 ? gap : 0),
                      child: _photoFrame(widget.photos[c], photoW, rowH),
                    )),
                  ),
                  SizedBox(height: gap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(cols, (c) {
                      final idx = cols + c;
                      return Padding(
                        padding: EdgeInsets.only(right: c < cols - 1 ? gap : 0),
                        child: idx < widget.photos.length
                            ? _photoFrame(widget.photos[idx], photoW, rowH)
                            : SizedBox(width: photoW, height: rowH),
                      );
                    }),
                  ),
                ],
              ),
            ),
            _stripFooter(width: totalW),
            if (isFilm) _filmEdgeH(width: totalW),
          ],
        ),
      );
    }

    final totalW = photoW * widget.photos.length + gap * (widget.photos.length - 1) + padH * 2;
    return Container(
      decoration: _stripDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFilm) _filmEdgeH(width: totalW),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.photos.length, (i) => Padding(
                padding: EdgeInsets.only(right: i < widget.photos.length - 1 ? gap : 0),
                child: _photoFrame(widget.photos[i], photoW, photoH),
              )),
            ),
          ),
          _stripFooter(width: totalW),
          if (isFilm) _filmEdgeH(width: totalW),
        ],
      ),
    );
  }

  Widget _filmEdgeH({required double width}) {
    return Container(
      width: width,
      height: 20,
      color: const Color(0xFF080604),
      child: Row(
        children: List.generate((width ~/ 20), (_) => Container(
          width: 16,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A16),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
      ),
    );
  }

  Widget _stripFooter({required double width}) {
    final isFilm = _selectedTheme == StripTheme.film;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isFilm ? const Color(0xFF080604) : Colors.transparent,
      child: Center(
        child: Text(
          _dateStr,
          style: TextStyle(
            color: _meta.footerColor,
            fontSize: 11,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isSharedView)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(sharedPhotos: widget.photos),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _borderColor, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: _mutedText, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'SHOT TOGETHER',
                      style: TextStyle(
                        color: _mutedText,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _sharing ? null : _share,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _borderColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _sharing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _mutedText, strokeWidth: 2))
                        : const Icon(Icons.link_rounded, color: _mutedText, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _sharing ? 'SHARING...' : 'SHARE',
                      style: const TextStyle(
                        color: _mutedText,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _downloading ? null : _download,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _downloading ? _surfaceColor : _redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _downloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _downloading ? 'SAVING...' : 'SAVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
