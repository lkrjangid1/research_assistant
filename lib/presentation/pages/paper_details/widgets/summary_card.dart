import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../cubits/paper_details/paper_details_cubit.dart';
import '../../../cubits/paper_details/paper_details_state.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperDetailsCubit, PaperDetailsState>(
      builder: (context, state) {
        if (state is! PaperDetailsLoaded) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AI Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    _ExpertiseLevelSelector(
                      current: state.expertiseLevel,
                      onChanged: (level) => context
                          .read<PaperDetailsCubit>()
                          .setExpertiseLevel(level),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.isLoadingSummary)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.summary != null) ...[
                  MarkdownBody(
                    data: state.summary!,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium,
                    ),
                    shrinkWrap: true,
                  ),
                  if (state.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Key Points',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...state.keyPoints.map((kp) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(kp,
                                  style: Theme.of(context).textTheme.bodySmall)),
                            ],
                          ),
                        )),
                  ],
                ] else
                  Center(
                    child: FilledButton.icon(
                      onPressed: () => context
                          .read<PaperDetailsCubit>()
                          .generateSummary(level: state.expertiseLevel),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Generate Summary'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpertiseLevelSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _ExpertiseLevelSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: current,
      isDense: true,
      items: const [
        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
        DropdownMenuItem(value: 'expert', child: Text('Expert')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
