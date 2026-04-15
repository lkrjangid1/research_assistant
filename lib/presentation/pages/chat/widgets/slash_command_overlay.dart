import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

const _commands = [
  ('/summary', 'Generate a summary of selected papers', Icons.summarize_outlined),
  ('/compare', 'Compare methodology of papers', Icons.compare_arrows_rounded),
  ('/gaps', 'Identify research gaps', Icons.search_rounded),
  ('/review', 'Get a peer-review style critique', Icons.rate_review_outlined),
  ('/code', 'Generate implementation pseudocode', Icons.code_rounded),
  ('/visualize', 'Describe charts/architecture', Icons.auto_graph_rounded),
  ('/search', 'Search for related work', Icons.travel_explore_rounded),
  ('/explain', 'Explain a concept from the papers', Icons.lightbulb_outline_rounded),
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
    final cs = Theme.of(context).colorScheme;
    final lq = query.toLowerCase();
    final matches = _commands
        .where((c) => c.$1.contains(lq) || c.$2.toLowerCase().contains(lq))
        .toList();

    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: matches.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, indent: 48, endIndent: 16, color: cs.outlineVariant),
          itemBuilder: (context, i) {
            final cmd = matches[i];
            return _CommandTile(
              command: cmd.$1,
              description: cmd.$2,
              icon: cmd.$3,
              onTap: () => onSelect(cmd.$1),
            );
          },
        ),
      ),
    );
  }
}

class _CommandTile extends StatefulWidget {
  final String command;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _CommandTile({
    required this.command,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CommandTile> createState() => _CommandTileState();
}

class _CommandTileState extends State<_CommandTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? AppColors.gradientBlue.withValues(alpha: 0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.gradientBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon,
                    size: 16, color: AppColors.gradientBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.command,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
