import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/feed_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../providers/my_feed_provider.dart';

class MyFeedScreen extends StatefulWidget {
  const MyFeedScreen({super.key});

  @override
  State<MyFeedScreen> createState() => _MyFeedScreenState();
}

class _MyFeedScreenState extends State<MyFeedScreen> {
  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1C1C1C);
  static const _border = Color(0xFF2E2E2E);
  static const _grey = Color(0xFF888888);

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyFeedProvider>().init();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MyFeedProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<MyFeedProvider>(
                builder: (_, provider, child) => _buildBody(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'My Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────

  Widget _buildBody(MyFeedProvider provider) {
    if (provider.isLoading) {
      return const LoadingWidget(color: Colors.white);
    }

    if (provider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white38,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: provider.init,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isEmpty || provider.feeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                color: Colors.white38,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No posts yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your uploaded feeds will appear here',
              style: TextStyle(color: _grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: provider.feeds.length + (provider.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, i) => const SizedBox(height: 28),
      itemBuilder: (context, index) {
        if (index == provider.feeds.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              ),
            ),
          );
        }

        final feed = provider.feeds[index];
        return FeedCard(
          feed: feed,
          isActive: provider.currentlyPlayingId == feed.id,
          onPlay: () => provider.setPlayingFeed(feed.id),
        );
      },
    );
  }
}
