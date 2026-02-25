import '../../data/models/category_model.dart';
import '../../data/models/feed_model.dart';
import '../../data/services/api_service.dart';
import 'base_provider.dart';

class HomeProvider extends BaseProvider {
  final ApiService _apiService;

  HomeProvider(this._apiService);

  List<CategoryModel> _categories = [];
  List<FeedModel> _feeds = [];
  int _selectedCategoryIndex = 0;
  int? _currentlyPlayingId;

  List<CategoryModel> get categories => _categories;
  List<FeedModel> get feeds => _feeds;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  int? get currentlyPlayingId => _currentlyPlayingId;

  Future<void> init() async {
    setLoading();
    await Future.wait([_fetchCategories(), _fetchFeeds()]);
  }

  Future<void> _fetchCategories() async {
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

  Future<void> _fetchFeeds() async {
    try {
      final response = await _apiService.get('home');
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == true) {
        // Parse feeds from 'results' key
        final results = data['results'] as List? ?? [];
        _feeds = results
            .map((e) => FeedModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Use category_dict from home response if category_list returned nothing
        if (_categories.isEmpty) {
          final categoryDict = data['category_dict'] as List? ?? [];
          _categories = categoryDict
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        _feeds.isEmpty ? setEmpty() : setIdle();
      } else {
        setError(data['message'] ?? 'Failed to load feeds');
      }
    } on Exception catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void selectCategory(int index) {
    if (_selectedCategoryIndex == index) return;
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  void setPlayingFeed(int? feedId) {
    if (_currentlyPlayingId == feedId) return;
    _currentlyPlayingId = feedId;
    notifyListeners();
  }
}
