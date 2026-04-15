import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../cubits/paper_details/paper_details_cubit.dart';
import '../../../cubits/paper_details/paper_details_state.dart';
import '../../../../core/theme/colors.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaperDetailsCubit, PaperDetailsState>(
      builder: (context, state) {
        if (state is! PaperDetailsLoaded) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientPurple,
                              AppColors.gradientFuchsia,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _ExpertiseLevelSelector(
                        current: state.expertiseLevel,
                        onChanged: (level) => context
                            .read<PaperDetailsCubit>()
                            .setExpertiseLevel(level),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content
                  if (state.isLoadingSummary)
                    _buildLoadingState()
                  else if (state.summary != null) ...[
                    MarkdownBody(
                      data: state.summary!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                        h1: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        h2: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        h3: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        code: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.gradientPurple,
                          backgroundColor: Color(0xFFF5F3FF),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                      ),
                      shrinkWrap: true,
                    ),
                    if (state.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: AppColors.surfaceBorder,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
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
                          const Text(
                            'Key Points',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...state.keyPoints.map(
                        (kp) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 10),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gradientBlue,
                                      AppColors.gradientPurple,
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  kp,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else
                    _buildGenerateButton(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.gradientPurple),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Generating AI summary…',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGenerateButton(
      BuildContext context, PaperDetailsLoaded state) {
    return Center(
      child: GestureDetector(
        onTap: () => context
            .read<PaperDetailsCubit>()
            .generateSummary(level: state.expertiseLevel),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.gradientPurple,
                AppColors.gradientFuchsia,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientPurple.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Generate Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpertiseLevelSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _ExpertiseLevelSelector(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppColors.textTertiary),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          items: const [
            DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
            DropdownMenuItem(
                value: 'intermediate', child: Text('Intermediate')),
            DropdownMenuItem(value: 'expert', child: Text('Expert')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
