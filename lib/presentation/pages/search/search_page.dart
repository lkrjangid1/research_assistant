import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/di/injection_container.dart';
import '../../cubits/search/search_cubit.dart';
import '../../cubits/search/search_state.dart';
import '../../widgets/paper_selection_bar.dart';
import '../../widgets/loading_overlay.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/paper_card_widget.dart';
import '../../../app/routes.dart';

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
      appBar: AppBar(
        title: const Text('Research Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.chatHistory),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
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
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (state is SearchInitial) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search for academic papers on arXiv',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (state is SearchLoading) {
      return _buildShimmer();
    }

    if (state is SearchError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<SearchCubit>().retry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is SearchLoaded) {
      if (state.papers.isEmpty) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No papers found', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }

      return LoadingOverlay(
        isLoading: state.isLoadingMore,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.papers.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.papers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return PaperCardWidget(paper: state.papers[index]);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(height: 160),
        ),
      ),
    );
  }
}
