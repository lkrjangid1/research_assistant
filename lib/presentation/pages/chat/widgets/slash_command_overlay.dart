import 'package:flutter/material.dart';

const _commands = [
  ('/summary', 'Generate a summary of selected papers'),
  ('/compare', 'Compare methodology of papers'),
  ('/gaps', 'Identify research gaps'),
  ('/review', 'Get a peer-review style critique'),
  ('/code', 'Generate implementation pseudocode'),
  ('/visualize', 'Describe charts/architecture'),
  ('/search', 'Search for related work'),
  ('/explain', 'Explain a concept from the papers'),
];

class SlashCommandOverlay extends StatelessWidget {
  final String query;
  final ValueChanged<String> onSelect;

  const SlashCommandOverlay({
    super.key,
    required this.query,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final lq = query.toLowerCase();
    final matches = _commands
        .where((c) => c.$1.contains(lq) || c.$2.toLowerCase().contains(lq))
        .toList();

    if (matches.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, i) {
            final cmd = matches[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.terminal, size: 18),
              title: Text(cmd.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(cmd.$2, style: const TextStyle(fontSize: 11)),
              onTap: () => onSelect(cmd.$1),
            );
          },
        ),
      ),
    );
  }
}
