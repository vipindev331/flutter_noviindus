import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/feed_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../data/models/category_model.dart';
import '../providers/home_provider.dart';
import '../providers/add_feed_provider.dart';
import '../providers/my_feed_provider.dart';
import 'add_feed_screen.dart';
import 'my_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1C1C1C);
  static const _border = Color(0xFF2E2E2E);
  static const _red = Color(0xFFD93025);
  static const _grey = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _buildFab(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Consumer<HomeProvider>(
              builder: (_, home, child) => _buildCategories(home.categories,
                  home.selectedCategoryIndex, home.selectCategory),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<HomeProvider>(
                builder: (_, home, child) => _buildFeedList(home),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Welcome back to Section',
                  style: TextStyle(color: _grey, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final myFeedProvider = context.read<MyFeedProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: myFeedProvider,
                    child: const MyFeedScreen(),
                  ),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.person, color: Colors.white70, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips ──────────────────────────────────────────

  Widget _buildCategories(
    List<CategoryModel> categories,
    int selectedIndex,
    void Function(int) onSelect,
  ) {
    final names = categories.isNotEmpty
        ? categories.map((c) => c.name).toList()
        : ['Explore', 'Trending', 'All Categories'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: names.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF3D1A1A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8B3333)
                      : const Color(0xFF2E2E2E),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.explore_outlined,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    names[index],
                    style: TextStyle(
                      color: selected ? Colors.white : _grey,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Feed list ───────────────────────────────────────────────

  Widget _buildFeedList(HomeProvider home) {
    if (home.isLoading) {
      return const LoadingWidget(color: Colors.white);
    }

    if (home.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(home.errorMessage,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: home.init,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (home.isEmpty || home.feeds.isEmpty) {
      return const Center(
        child: Text('No feeds available',
            style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: home.feeds.length,
      separatorBuilder: (_, i) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final feed = home.feeds[index];
        return FeedCard(
          feed: feed,
          isActive: home.currentlyPlayingId == feed.id,
          onPlay: () => home.setPlayingFeed(feed.id),
        );
      },
    );
  }

  // ── FAB ─────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final provider = context.read<AddFeedProvider>()..resetForm();
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const AddFeedScreen(),
            ),
          ),
        );
        // Refresh home feed when a new post was added
        if (added == true && context.mounted) {
          context.read<HomeProvider>().init();
        }
      },
      backgroundColor: _red,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}
