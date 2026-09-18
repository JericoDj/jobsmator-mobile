import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/theme.dart';
import '../shared/widgets/jm_logo_mark.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';

/// The numbers a share card shows.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.name,
    required this.searches,
    required this.jobs,
    required this.applied,
    required this.interviews,
    required this.streak,
    required this.applyRate,
  });
  final String name;
  final int searches, jobs, applied, interviews, streak;
  final double applyRate;
}

/// Card looks. [sticker] draws on a transparent background so it can sit
/// on the user's own photo.
enum ShareTemplate {
  cobalt('Cobalt'),
  light('Light'),
  bold('Bold'),
  sticker('Sticker');

  const ShareTemplate(this.label);
  final String label;
}

/// Full page over the shell, Strava-style: pick a template or put the
/// sticker on a photo, then save it or share it.
class ShareProgressScreen extends StatefulWidget {
  const ShareProgressScreen({super.key, required this.snap});
  final ProgressSnapshot snap;

  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  final _cardKey = GlobalKey();
  final _picker = ImagePicker();
  var _template = ShareTemplate.cobalt;
  var _camera = CameraDevice.rear;
  Uint8List? _photo;
  var _busy = false;

  bool get _photoMode => _photo != null;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: _camera,
        maxWidth: 2000,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photo = bytes;
        _template = ShareTemplate.sticker;
      });
    } catch (_) {
      _toast(
        'Could not open the ${source == ImageSource.camera ? 'camera' : 'photos'}.',
      );
    }
  }

  void _switchCamera() {
    setState(() {
      _camera = _camera == CameraDevice.rear
          ? CameraDevice.front
          : CameraDevice.rear;
    });
    _pickPhoto(ImageSource.camera);
  }

  Future<Uint8List?> _render() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final png = await _render();
      if (png == null) throw StateError('render');
      await Gal.putImageBytes(
        png,
        name: 'jobsmator-progress-${DateTime.now().millisecondsSinceEpoch}',
      );
      _toast('Saved to your photos.', tone: ToastTone.success);
    } on GalException catch (e) {
      _toast(
        e.type == GalExceptionType.accessDenied
            ? 'Allow photo access to save.'
            : 'Could not save right now.',
      );
    } catch (_) {
      _toast('Could not save right now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final png = await _render();
      if (png == null) throw StateError('render');
      final s = widget.snap;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'jobsmator-progress.png',
            ),
          ],
          text:
              '${s.applied} applications, ${s.streak}-day streak on JobsMator. Search less. Apply more.',
        ),
      );
    } catch (_) {
      _toast('Could not share right now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String title, {ToastTone tone = ToastTone.error}) {
    if (mounted) showJmToast(context, title: title, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return JmPage(
      appBar: AppBar(title: const Text('Share your progress')),
      bottom: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _save,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.oceanDeep,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: c.lineStrong),
                shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Save'),
            ),
          ),
          const SizedBox(width: JmSpace.x3),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _busy ? null : _share,
              style: FilledButton.styleFrom(
                backgroundColor: c.ocean,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: JmSpace.x2),

          // Preview — the RepaintBoundary is exactly what gets exported.
          RepaintBoundary(
            key: _cardKey,
            child: _photoMode
                ? _PhotoComposite(photo: _photo!, snap: widget.snap)
                : ProgressShareCard(snap: widget.snap, template: _template),
          ),
          const SizedBox(height: JmSpace.x4),

          // Templates
          JmLabel('Template', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in ShareTemplate.values) ...[
                  _TemplateChip(
                    template: t,
                    snap: widget.snap,
                    selected: !_photoMode && _template == t,
                    onTap: () => setState(() {
                      _photo = null;
                      _template = t;
                    }),
                  ),
                  const SizedBox(width: JmSpace.x2),
                ],
              ],
            ),
          ),
          const SizedBox(height: JmSpace.x4),

          // Photo
          JmLabel('Put it on a photo', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          Row(
            children: [
              _PhotoAction(
                icon: Icons.photo_camera_outlined,
                label: 'Take photo',
                onTap: _busy ? null : () => _pickPhoto(ImageSource.camera),
              ),
              const SizedBox(width: JmSpace.x2),
              _PhotoAction(
                icon: Icons.cameraswitch_outlined,
                label: _camera == CameraDevice.rear
                    ? 'Use selfie cam'
                    : 'Use rear cam',
                onTap: _busy ? null : _switchCamera,
              ),
              const SizedBox(width: JmSpace.x2),
              _PhotoAction(
                icon: Icons.photo_library_outlined,
                label: 'Choose photo',
                onTap: _busy ? null : () => _pickPhoto(ImageSource.gallery),
              ),
            ],
          ),
          if (_photoMode) ...[
            const SizedBox(height: JmSpace.x2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _photo = null),
                style: TextButton.styleFrom(foregroundColor: c.danger),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Remove photo'),
              ),
            ),
          ],
          const SizedBox(height: JmSpace.x4),
          Text(
            'Post it to your story or send it to a friend who\'s job hunting too.',
            style: context.type.meta,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The user's photo, 4:5, with the sticker card pinned to the bottom.
class _PhotoComposite extends StatelessWidget {
  const _PhotoComposite({required this.photo, required this.snap});
  final Uint8List photo;
  final ProgressSnapshot snap;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4 / 5,
    child: ClipRRect(
      borderRadius: JmRadius.lgR,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [.45, 1],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .55),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _StickerBody(snap: snap),
          ),
        ],
      ),
    ),
  );
}

/// Compact stats block used by the sticker template and the photo overlay.
class _StickerBody extends StatelessWidget {
  const _StickerBody({required this.snap});
  final ProgressSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    const fg = Colors.white;
    final dim = fg.withValues(alpha: .75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const JmLogoMark(size: 20),
            const SizedBox(width: 6),
            Text(
              'JobsMator',
              style: context.type.heading.copyWith(fontSize: 14, color: fg),
            ),
            if (snap.streak > 0) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: c.volt,
              ),
              const SizedBox(width: 2),
              Text(
                '${snap.streak}d',
                style: context.type.meta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${snap.applied}',
              style: context.type.stat.copyWith(
                fontSize: 56,
                height: 1,
                color: fg,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                snap.applied == 1 ? 'application\nsent' : 'applications\nsent',
                style: context.type.ui.copyWith(
                  fontSize: 13,
                  height: 1.1,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          children: [
            _tiny('${snap.searches} searches', dim, context),
            _tiny('${snap.jobs} jobs', dim, context),
            _tiny(
              '${(snap.applyRate * 100).round()}% apply rate',
              dim,
              context,
            ),
            _tiny('${snap.interviews} interviews', dim, context),
          ],
        ),
      ],
    );
  }

  Widget _tiny(String t, Color color, BuildContext context) =>
      Text(t, style: context.type.meta.copyWith(fontSize: 11, color: color));
}

/// The card: wordmark, streak chip, big applied count, four small stats
/// and the tagline. Colours come from [template]. Sized 4:5 so it fits a
/// story or a post.
class ProgressShareCard extends StatelessWidget {
  const ProgressShareCard({
    super.key,
    required this.snap,
    this.template = ShareTemplate.cobalt,
  });
  final ProgressSnapshot snap;
  final ShareTemplate template;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    if (template == ShareTemplate.sticker) {
      // Transparent export; a faint checker in the preview so it reads as such.
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: JmRadius.lgR,
            ),
            child: _StickerBody(snap: snap),
          ),
        ),
      );
    }

    final (
      Color bg,
      Color fg,
      List<Color> washA,
      List<Color> washB,
    ) = switch (template) {
      ShareTemplate.cobalt => (
        const Color(0xFF0B1B3A),
        Colors.white,
        [c.ocean.withValues(alpha: .9), Colors.transparent],
        [c.match.withValues(alpha: .45), Colors.transparent],
      ),
      ShareTemplate.light => (
        Colors.white,
        c.ink,
        [c.sky.withValues(alpha: .35), Colors.transparent],
        [c.match.withValues(alpha: .22), Colors.transparent],
      ),
      ShareTemplate.bold => (
        c.ocean,
        Colors.white,
        [c.volt.withValues(alpha: .55), Colors.transparent],
        [c.match.withValues(alpha: .6), Colors.transparent],
      ),
      ShareTemplate.sticker => throw UnimplementedError(),
    };
    final dim = fg.withValues(alpha: .7);
    final rule = fg.withValues(alpha: .18);
    final chipBg = fg.withValues(
      alpha: template == ShareTemplate.light ? .08 : .14,
    );

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: JmRadius.lgR,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: bg)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.1, -1.1),
                    radius: 1.3,
                    colors: washA,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.2, 1.3),
                    radius: 1.1,
                    colors: washB,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const JmLogoMark(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'JobsMator',
                        style: context.type.heading.copyWith(
                          fontSize: 16,
                          color: fg,
                        ),
                      ),
                      const Spacer(),
                      if (snap.streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: JmRadius.pillR,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: template == ShareTemplate.light
                                    ? c.warn
                                    : c.volt,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${snap.streak}-day streak',
                                style: context.type.meta.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    "${snap.name}'s job hunt",
                    style: context.type.meta.copyWith(fontSize: 14, color: dim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snap.applied}',
                    style: context.type.stat.copyWith(
                      fontSize: 84,
                      height: 1,
                      color: fg,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    snap.applied == 1
                        ? 'application sent'
                        : 'applications sent',
                    style: context.type.ui.copyWith(fontSize: 17, color: fg),
                  ),
                  const SizedBox(height: 22),
                  Container(height: 1, color: rule),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Mini(
                        value: '${snap.searches}',
                        label: 'Searches',
                        fg: fg,
                        dim: dim,
                      ),
                      _Mini(
                        value: '${snap.jobs}',
                        label: 'Jobs found',
                        fg: fg,
                        dim: dim,
                      ),
                      _Mini(
                        value: '${(snap.applyRate * 100).round()}%',
                        label: 'Apply rate',
                        fg: fg,
                        dim: dim,
                      ),
                      _Mini(
                        value: '${snap.interviews}',
                        label: 'Interviews',
                        fg: fg,
                        dim: dim,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Search less. Apply more.',
                    style: context.type.meta.copyWith(
                      fontSize: 12,
                      color: dim,
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.value,
    required this.label,
    required this.fg,
    required this.dim,
  });
  final String value, label;
  final Color fg, dim;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: context.type.stat.copyWith(fontSize: 20, color: fg)),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.type.meta.copyWith(fontSize: 11, color: dim),
        ),
      ],
    ),
  );
}

/// Thumbnail of a template with its name under it.
class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.snap,
    required this.selected,
    required this.onTap,
  });
  final ShareTemplate template;
  final ProgressSnapshot snap;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return InkWell(
      onTap: onTap,
      borderRadius: JmRadius.mdR,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: JmRadius.smR,
              border: Border.all(
                color: selected ? c.ocean : c.line,
                width: selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 320,
                  height: 400,
                  child: template == ShareTemplate.sticker
                      ? ColoredBox(
                          color: c.surface2,
                          child: ProgressShareCard(
                            snap: snap,
                            template: template,
                          ),
                        )
                      : ProgressShareCard(snap: snap, template: template),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            template.label,
            style: context.type.meta.copyWith(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c.oceanDeep : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Expanded(
      child: Material(
        color: c.card,
        borderRadius: JmRadius.mdR,
        child: InkWell(
          onTap: onTap,
          borderRadius: JmRadius.mdR,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: JmRadius.mdR,
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: c.oceanDeep),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: context.type.meta.copyWith(
                    fontSize: 11.5,
                    color: c.text,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
