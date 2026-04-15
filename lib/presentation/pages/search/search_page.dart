import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/colors.dart';
import '../../cubits/search/search_cubit.dart';
import '../../cubits/search/search_state.dart';
import '../../widgets/paper_selection_bar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/gradient_orbs_background.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/paper_card_widget.dart';
import '../../../app/routes.dart';
import '../chat_history/chat_history_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => sl<SearchCubit>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: GradientOrbsBackground(
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            return Column(
              children: [
                SearchBarWidget(
                  isLoading: state is SearchLoading,
                  onSearch: (q) => context.read<SearchCubit>().search(q),
                ),
                Expanded(child: _buildBody(context, state)),
                const PaperSelectionBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.gradientBlue,
                  AppColors.gradientPurple,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Research Assistant'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'Chat History',
          onPressed: () async {
            final sessionId = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const ChatHistoryPage()),
            );
            if (sessionId != null && context.mounted) {
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: ChatRouteArgs(sessionId: sessionId),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (state is SearchInitial) {
      return _buildEmptyState();
    }

    if (state is SearchLoading) {
      return _buildShimmer();
    }

    if (state is SearchError) {
      return _buildError(context, state.message);
    }

    if (state is SearchLoaded) {
      if (state.papers.isEmpty) {
        return _buildNoResults();
      }

      return LoadingOverlay(
        isLoading: state.isLoadingMore,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          itemCount: state.papers.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.papers.length) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.gradientBlue,
                      ),
                    ),
                  ),
                ),
              );
            }
            return PaperCardWidget(paper: state.papers[index]);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gradientBlue.withValues(alpha: 0.15),
                    AppColors.gradientPurple.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 36, color: AppColors.gradientBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Discover Research',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search millions of academic papers\non arXiv to find relevant research',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Large Language Models',
      'Diffusion Models',
      'Transformer Architecture',
      'Neural Radiance Fields',
      'Retrieval Augmented Generation',
    ];

    return Builder(builder: (context) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return GestureDetector(
            onTap: () => context.read<SearchCubit>().search(s),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                s,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 32, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No papers found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try different keywords or broaden your search',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.read<SearchCubit>().retry(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.gradientBlue,
                      AppColors.gradientSlateBlue
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFFFFFFF),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
