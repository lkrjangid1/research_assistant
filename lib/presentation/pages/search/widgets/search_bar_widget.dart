import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../presentation/widgets/animated_gradient_border.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) widget.onSearch(q);
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
  }

  Duration get _animDuration {
    if (widget.isLoading) return const Duration(milliseconds: 800);
    if (_isFocused) return const Duration(seconds: 2);
    return const Duration(seconds: 3);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedGradientBorder(
        borderRadius: 28,
        borderWidth: 2,
        duration: _animDuration,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.gradientBlue,
                        ),
                      ),
                    )
                  : Icon(Icons.search_rounded,
                      size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Focus(
                  onFocusChange: (f) => setState(() => _isFocused = f),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search arXiv papers…',
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (_hasText)
                GestureDetector(
                  onTap: _clear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.gradientBlue,
                        AppColors.gradientSlateBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gradientBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
