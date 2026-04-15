import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/entities/paper.dart';
import '../../cubits/paper_details/paper_details_cubit.dart';
import '../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../cubits/paper_selection/paper_selection_state.dart';
import '../../widgets/gradient_orbs_background.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, cs),
      body: GradientOrbsBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: MetadataSection(paper: paper)),
            const SliverToBoxAdapter(child: SummaryCard()),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton:
          BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
        builder: (context, state) {
          if (!state.isSelected(paper.arxivId)) return const SizedBox.shrink();
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientBlue, AppColors.gradientSlateBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Open Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme cs) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: cs.onSurfaceVariant),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Paper Details'),
      actions: [
        BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
          builder: (context, state) {
            final isSelected = state.isSelected(paper.arxivId);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (isSelected) {
                    context
                        .read<PaperSelectionCubit>()
                        .removePaper(paper.arxivId);
                  } else if (state.canAddMore) {
                    context.read<PaperSelectionCubit>().addPaper(paper);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientBlue,
                              AppColors.gradientSlateBlue,
                            ],
                          )
                        : null,
                    color: isSelected ? null : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_rounded : Icons.add_rounded,
                        size: 15,
                        color: isSelected ? Colors.white : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'In Chat' : 'Add to Chat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
