import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/category_model.dart';
import '../../data/services/api_service.dart';
import 'base_provider.dart';

class AddFeedProvider extends BaseProvider {
  final ApiService _apiService;
  final ImagePicker _picker = ImagePicker();

  AddFeedProvider(this._apiService);

  List<CategoryModel> _categories = [];
  File? _videoFile;
  File? _thumbnailFile;
  Duration? _videoDuration;
  String _description = '';
  final Set<int> _selectedCategoryIds = {};
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  List<CategoryModel> get categories => _categories;
  File? get videoFile => _videoFile;
  File? get thumbnailFile => _thumbnailFile;
  Duration? get videoDuration => _videoDuration;
  String get description => _description;
  Set<int> get selectedCategoryIds => Set.unmodifiable(_selectedCategoryIds);
  double get uploadProgress => _uploadProgress;
  bool get isUploading => _isUploading;

  // ── Categories ──

  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      final response = await _apiService.get('category_list');
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == true) {
        final list = data['categories'] as List? ?? [];
        _categories = list
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Pickers --

  /// Returns a validation error string, or null on success.
  Future<String?> pickVideo() async {
    try {
      final xFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (xFile == null) return null;

      // 1. Extension must be .mp4
      final ext = xFile.path.split('.').last.toLowerCase();
      if (ext != 'mp4') {
        return 'Only MP4 videos are allowed';
      }

      // 2. Duration must be ≤ 5 minutes
      final controller = VideoPlayerController.file(File(xFile.path));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      if (duration.inSeconds > 300) {
        return 'Video must be 5 minutes or less';
      }

      _videoFile = File(xFile.path);
      _videoDuration = duration;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Failed to pick video';
    }
  }

  Future<void> pickThumbnail() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xFile == null) return;
      _thumbnailFile = File(xFile.path);
      notifyListeners();
    } catch (_) {}
  }

  // ── Form state ─────────────────────────────────────────────

  void setDescription(String value) {
    _description = value;
  }

  void toggleCategory(int categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  // ── Validation ─────────────────────────────────────────────

  String? validateFields() {
    if (_videoFile == null) return 'Please select a video';
    if (_thumbnailFile == null) return 'Please add a thumbnail';
    if (_description.trim().isEmpty) return 'Please add a description';
    if (_selectedCategoryIds.isEmpty) return 'Please select at least one category';
    return null;
  }

  // ── Upload ─────────────────────────────────────────────────

  Future<bool> uploadFeed() async {
    final error = validateFields();
    if (error != null) {
      setError(error);
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    setLoading();

    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          _videoFile!.path,
          filename: _videoFile!.path.split('/').last,
        ),
        'image': await MultipartFile.fromFile(
          _thumbnailFile!.path,
          filename: _thumbnailFile!.path.split('/').last,
        ),
        'desc': _description.trim(),
        'category': _selectedCategoryIds.toList(),
      });

      final response = await _apiService.postFormData(
        'my_feed',
        formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] == true) {
        _isUploading = false;
        setIdle();
        return true;
      } else {
        _isUploading = false;
        setError(data['message'] ?? 'Upload failed. Please try again.');
        return false;
      }
    } on Exception catch (e) {
      _isUploading = false;
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  void resetForm() {
    _videoFile = null;
    _thumbnailFile = null;
    _videoDuration = null;
    _description = '';
    _selectedCategoryIds.clear();
    _uploadProgress = 0.0;
    _isUploading = false;
    setIdle();
  }
}
