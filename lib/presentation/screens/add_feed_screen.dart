import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/category_model.dart';
import '../providers/add_feed_provider.dart';

class AddFeedScreen extends StatefulWidget {
  const AddFeedScreen({super.key});

  @override
  State<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends State<AddFeedScreen> {
  final _descController = TextEditingController();

  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1C1C1C);
  static const _border = Color(0xFF2E2E2E);
  static const _dash = Color(0xFF3A3A3A);
  static const _grey = Color(0xFF888888);
  static const _red = Color(0xFFD93025);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddFeedProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    final provider = context.read<AddFeedProvider>();
    final error = await provider.pickVideo();
    if (!mounted) return;
    if (error != null) AppUtils.showSnackBar(context, error, isError: true);
  }

  Future<void> _pickThumbnail() async {
    await context.read<AddFeedProvider>().pickThumbnail();
  }

  Future<void> _onSharePost() async {
    AppUtils.hideKeyboard(context);
    final provider = context.read<AddFeedProvider>();
    provider.setDescription(_descController.text);

    final success = await provider.uploadFeed();
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(context, 'Post shared successfully!');
      Navigator.pop(context, true);
    } else {
      AppUtils.showSnackBar(context, provider.errorMessage, isError: true);
    }
  }

  void _showAllCategories(AddFeedProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<AddFeedProvider>(
            builder: (context, p, _) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.categories
                            .map((c) => _CategoryChip(
                                  category: c,
                                  isSelected:
                                      p.selectedCategoryIds.contains(c.id),
                                  onTap: () => p.toggleCategory(c.id),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
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

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Consumer<AddFeedProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Upload progress bar
              if (provider.isUploading)
                LinearProgressIndicator(
                  value: provider.uploadProgress,
                  backgroundColor: _surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(_red),
                  minHeight: 3,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVideoPicker(provider),
                      const SizedBox(height: 16),
                      _buildThumbnailPicker(provider),
                      const SizedBox(height: 28),
                      _buildDescriptionField(),
                      const SizedBox(height: 28),
                      _buildCategoriesSection(provider),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      title: const Text(
        'Add Feeds',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Consumer<AddFeedProvider>(
          builder: (context, provider, _) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: provider.isUploading ? null : _onSharePost,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: provider.isUploading
                        ? _border
                        : const Color(0xFF8B3333),
                  ),
                ),
                child: Text(
                  'Share Post',
                  style: TextStyle(
                    color: provider.isUploading ? _grey : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Video picker ───────────────────────────────────────────

  Widget _buildVideoPicker(AddFeedProvider provider) {
    final hasVideo = provider.videoFile != null;

    return GestureDetector(
      onTap: provider.isUploading ? null : _pickVideo,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: _dash, borderRadius: 14),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasVideo
              ? _buildVideoPreview(provider)
              : const _PickerPlaceholder(
                  icon: Icons.upload_rounded,
                  label: 'Select a video from Gallery',
                  iconSize: 52,
                ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(AddFeedProvider provider) {
    final name = provider.videoFile!.path.split('/').last;
    final dur = provider.videoDuration;
    final durText = dur != null
        ? '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}'
        : '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.video_file_rounded, color: Colors.white70, size: 48),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (durText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            durText,
            style: const TextStyle(color: _grey, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        _smallLabel('Tap to change'),
      ],
    );
  }

  // ── Thumbnail picker ───────────────────────────────────────

  Widget _buildThumbnailPicker(AddFeedProvider provider) {
    final hasImage = provider.thumbnailFile != null;

    return GestureDetector(
      onTap: provider.isUploading ? null : _pickThumbnail,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: _dash,
          borderRadius: 14,
          dashLength: 6,
          gap: 6,
        ),
        child: Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(provider.thumbnailFile!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 8,
                        right: 10,
                        child: _smallLabel('Tap to change'),
                      ),
                    ],
                  ),
                )
              : const _PickerPlaceholder(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Add a Thumbnail',
                  iconSize: 32,
                  row: true,
                ),
        ),
      ),
    );
  }

  // ── Description ────────────────────────────────────────────

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descController,
          maxLines: 5,
          style: const TextStyle(
            color: Color(0xFFCCCCCC),
            fontSize: 13,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText:
                'Write something about your video...',
            hintStyle: const TextStyle(color: _grey, fontSize: 13),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white38, width: 1.2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  // ── Categories ─────────────────────────────────────────────

  Widget _buildCategoriesSection(AddFeedProvider provider) {
    final selectedIds = provider.selectedCategoryIds;
    final preview = provider.categories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories This Project',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () => _showAllCategories(provider),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(color: _grey, fontSize: 13),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.info_outline_rounded, color: _grey, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (provider.categories.isEmpty)
          const Text('Loading categories...',
              style: TextStyle(color: _grey, fontSize: 12))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preview
                .map((c) => _CategoryChip(
                      category: c,
                      isSelected: selectedIds.contains(c.id),
                      onTap: () => provider.toggleCategory(c.id),
                    ))
                .toList(),
          ),
        if (selectedIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${selectedIds.length} selected',
            style: const TextStyle(color: _grey, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _smallLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Category chip
// ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3D1A1A)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B3333)
                : const Color(0xFF3A3A3A),
          ),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF888888),
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Picker placeholder
// ────────────────────────────────────────────────────────────

class _PickerPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final bool row;

  const _PickerPlaceholder({
    required this.icon,
    required this.label,
    required this.iconSize,
    this.row = false,
  });

  @override
  Widget build(BuildContext context) {
    if (row) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white54, size: iconSize),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white54, size: iconSize),
        const SizedBox(height: 14),
        Text(label,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Dashed border painter
// ────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashLength;
  final double gap;

  static const double _strokeWidth = 1.5;

  const _DashedBorderPainter({
    this.color = const Color(0xFF3A3A3A),
    this.borderRadius = 12,
    this.dashLength = 8,
    this.gap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_strokeWidth / 2, _strokeWidth / 2,
          size.width - _strokeWidth, size.height - _strokeWidth),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
