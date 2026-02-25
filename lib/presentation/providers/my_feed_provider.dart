import '../../data/models/feed_model.dart';
import '../../data/services/api_service.dart';
import 'base_provider.dart';

class MyFeedProvider extends BaseProvider {
  final ApiService _apiService;

  MyFeedProvider(this._apiService);

  List<FeedModel> _feeds = [];
  int? _currentlyPlayingId;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<FeedModel> get feeds => _feeds;
  int? get currentlyPlayingId => _currentlyPlayingId;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> init() async {
    _page = 1;
    _hasMore = true;
    _feeds = [];
    _currentlyPlayingId = null;
    setLoading();
    await _fetchFeeds();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await _fetchFeeds();
  }

  Future<void> _fetchFeeds() async {
    try {
      final response = await _apiService.get('my_feed', queryParams: {'page': _page});
      final data = response.data as Map<String, dynamic>;

      if (data['status'] == true || data.containsKey('results')) {
        final results = data['results'] as List? ?? [];
        final newFeeds = results
            .map((e) => FeedModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _feeds.addAll(newFeeds);

        // Determine if more pages exist
        final next = data['next'];
        _hasMore = next != null;
        if (_hasMore) _page++;

        _isLoadingMore = false;
        _feeds.isEmpty ? setEmpty() : setIdle();
      } else {
        _isLoadingMore = false;
        _feeds.isEmpty
            ? setError(data['message'] ?? 'Failed to load feeds')
            : setIdle();
      }
    } on Exception catch (e) {
      _isLoadingMore = false;
      _feeds.isEmpty
          ? setError(e.toString().replaceFirst('Exception: ', ''))
          : setIdle();
    }
  }

  void setPlayingFeed(int? feedId) {
    if (_currentlyPlayingId == feedId) return;
    _currentlyPlayingId = feedId;
    notifyListeners();
  }

  void prependFeed(FeedModel feed) {
    _feeds.insert(0, feed);
    if (isEmpty) setIdle();
    notifyListeners();
  }
}
