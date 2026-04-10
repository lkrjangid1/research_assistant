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
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: state.selectedPapers.map((paper) {
                      return Chip(
                        label: Text(
                          paper.title.length > 30
                              ? '${paper.title.substring(0, 30)}…'
                              : paper.title,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onDeleted: () =>
                            context.read<PaperSelectionCubit>().removePaper(paper.arxivId),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
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
