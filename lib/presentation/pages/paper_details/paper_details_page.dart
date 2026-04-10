import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../domain/entities/paper.dart';
import '../../cubits/paper_details/paper_details_cubit.dart';
import '../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../cubits/paper_selection/paper_selection_state.dart';
import 'widgets/metadata_section.dart';
import 'widgets/summary_card.dart';
import '../../../app/routes.dart';

class PaperDetailsPage extends StatelessWidget {
  final Paper paper;

  const PaperDetailsPage({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaperDetailsCubit>(
      create: (_) => sl<PaperDetailsCubit>()..loadPaper(paper),
      child: _PaperDetailsView(paper: paper),
    );
  }
}

class _PaperDetailsView extends StatelessWidget {
  final Paper paper;

  const _PaperDetailsView({required this.paper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Details'),
        actions: [
          BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
            builder: (context, state) {
              final isSelected = state.isSelected(paper.arxivId);
              return IconButton(
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: isSelected ? 'Remove from chat' : 'Add to chat',
                onPressed: () {
                  if (isSelected) {
                    context.read<PaperSelectionCubit>().removePaper(paper.arxivId);
                  } else if (state.canAddMore) {
                    context.read<PaperSelectionCubit>().addPaper(paper);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: MetadataSection(paper: paper)),
          const SliverToBoxAdapter(child: SummaryCard()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
        builder: (context, state) {
          if (!state.isSelected(paper.arxivId)) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
            icon: const Icon(Icons.chat),
            label: const Text('Open Chat'),
          );
        },
      ),
    );
  }
}
