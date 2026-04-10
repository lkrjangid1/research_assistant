import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/paper_selection/paper_selection_cubit.dart';
import '../cubits/paper_selection/paper_selection_state.dart';
import '../../app/routes.dart';

class PaperSelectionBar extends StatelessWidget {
  const PaperSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
      builder: (context, state) {
        if (state.selectedPapers.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: state.selectedPapers.map((paper) {
                          final status = state.statusFor(paper.arxivId);
                          final suffix = switch (status) {
                            'processing' => ' (indexing)',
                            'failed' => ' (failed)',
                            _ => '',
                          };

                          return Chip(
                            label: Text(
                              '${paper.title.length > 24 ? '${paper.title.substring(0, 24)}…' : paper.title}$suffix',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onDeleted: () =>
                                context.read<PaperSelectionCubit>().removePaper(paper.arxivId),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                      if (state.hasProcessingPapers)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Preparing papers for chat...',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: state.allPapersReady
                      ? () => Navigator.pushNamed(context, AppRoutes.chat)
                      : null,
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text('Chat (${state.selectedPapers.length})'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
