import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/entities/paper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/theme/colors.dart';

class MetadataSection extends StatelessWidget {
  final Paper paper;

  const MetadataSection({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _MetaRow(icon: Icons.person_outline_rounded,
                  text: paper.authors.join(', '), cs: cs),
              const SizedBox(height: 8),
              _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormatter.formatPublishedDate(paper.publishedDate),
                  cs: cs),
              const SizedBox(height: 8),
              _MetaRow(icon: Icons.label_outline_rounded,
                  text: paper.categories.join(' · '), cs: cs),
              const SizedBox(height: 8),
              _MetaRow(icon: Icons.fingerprint_rounded,
                  text: paper.arxivId, cs: cs, isMonospace: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'View PDF',
                    onTap: () => _launch(paper.pdfUrl),
                    isPrimary: true,
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'arXiv Page',
                    onTap: () =>
                        _launch('https://arxiv.org/abs/${paper.arxivId}'),
                    isPrimary: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientBlue,
                          AppColors.gradientPurple,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Abstract',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                paper.abstract,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final bool isMonospace;

  const _MetaRow({
    required this.icon,
    required this.text,
    required this.cs,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.gradientBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: AppColors.gradientBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight:
                    isMonospace ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(
                    colors: _hovered
                        ? [const Color(0xFF5A95F5), const Color(0xFF8B7AEF)]
                        : [
                            AppColors.gradientBlue,
                            AppColors.gradientSlateBlue,
                          ],
                  )
                : null,
            color: widget.isPrimary ? null : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: widget.isPrimary
                ? null
                : Border.all(color: cs.outlineVariant),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color:
                          AppColors.gradientBlue.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isPrimary ? Colors.white : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isPrimary
                      ? Colors.white
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
