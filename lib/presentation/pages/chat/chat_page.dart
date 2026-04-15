import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/colors.dart';
import '../../cubits/chat/chat_cubit.dart';
import '../../cubits/chat/chat_state.dart';
import '../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../cubits/paper_selection/paper_selection_state.dart';
import '../../widgets/animated_gradient_border.dart';
import 'widgets/message_bubble.dart';
import 'widgets/slash_command_overlay.dart';
import 'widgets/chat_papers_panel.dart';
import '../chat_history/chat_history_page.dart';

class ChatPage extends StatelessWidget {
  final String? sessionId;

  const ChatPage({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (ctx) {
        final cubit = sl<ChatCubit>();
        if (sessionId != null) {
          cubit.loadSession(sessionId!);
        } else {
          final selection = ctx.read<PaperSelectionCubit>().state;
          cubit.initSession(selection.selectedPapers);
        }
        return cubit;
      },
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSlashOverlay = false;
  String _slashQuery = '';
  bool _inputFocused = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      if (text.startsWith('/')) {
        _showSlashOverlay = true;
        _slashQuery = text;
      } else {
        _showSlashOverlay = false;
      }
    });
  }

  void _selectCommand(String command) {
    _inputController.text = '$command ';
    _inputController.selection =
        TextSelection.collapsed(offset: command.length + 1);
    setState(() => _showSlashOverlay = false);
  }

  void _sendMessage(BuildContext context) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final selectionState = context.read<PaperSelectionCubit>().state;
    if (!selectionState.allPapersReady) return;
    context.read<ChatCubit>().sendMessage(text, selectionState.paperTitles);
    _inputController.clear();
    setState(() => _showSlashOverlay = false);
    _scrollToBottom();
  }

  Future<void> _openHistory(BuildContext context) async {
    final sessionId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ChatHistoryPage()),
    );
    if (sessionId != null && context.mounted) {
      context.read<ChatCubit>().loadSession(sessionId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, cs),
      body: Column(
        children: [
          const ChatPapersPanel(),
          _buildIndexingBanner(context, cs),
          Expanded(child: _buildMessageList(context, cs)),
          if (_showSlashOverlay)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SlashCommandOverlay(
                query: _slashQuery,
                onSelect: _selectCommand,
              ),
            ),
          _buildInputBar(context, cs),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme cs) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: cs.onSurfaceVariant),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gradientPurple, AppColors.gradientFuchsia],
              ),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Chat'),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history_rounded, color: cs.onSurfaceVariant),
          tooltip: 'Chat History',
          onPressed: () => _openHistory(context),
        ),
      ],
    );
  }

  Widget _buildIndexingBanner(BuildContext context, ColorScheme cs) {
    return BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
      builder: (context, selState) {
        if (selState.selectedPapers.isEmpty || selState.allPapersReady) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.gradientFuchsia,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selState.hasProcessingPapers
                      ? 'Papers are being indexed — chat unlocks when ready.'
                      : (selState.error ??
                          'One or more papers failed to index. Remove them and try again.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(BuildContext context, ColorScheme cs) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatSessionLoaded) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is ChatInitial) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          );
        }

        if (state is ChatError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        size: 28, color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ChatSessionLoaded) {
          if (state.messages.isEmpty) {
            return _buildEmptyChat(context, cs);
          }
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: state.messages.length + (state.isProcessing ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.messages.length) {
                return _buildThinkingIndicator(cs);
              }
              return MessageBubble(message: state.messages[i]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyChat(BuildContext context, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.gradientPurple, AppColors.gradientFuchsia],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask Anything',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask questions about your selected papers\nor use / commands for AI-powered analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _StarterChip(
                  label: 'Summarize papers',
                  cs: cs,
                  onTap: () {
                    _inputController.text = 'Summarize these papers';
                    _sendMessage(context);
                  },
                ),
                _StarterChip(
                  label: '/compare methodologies',
                  cs: cs,
                  onTap: () {
                    _inputController.text = '/compare methodologies';
                    _sendMessage(context);
                  },
                ),
                _StarterChip(
                  label: '/gaps research gaps',
                  cs: cs,
                  onTap: () {
                    _inputController.text = '/gaps research gaps';
                    _sendMessage(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 48, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gradientPurple, AppColors.gradientFuchsia],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          _ThinkingDots(cs: cs),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ColorScheme cs) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final isProcessing =
            state is ChatSessionLoaded && state.isProcessing;
        final selectionState = context.watch<PaperSelectionCubit>().state;
        final inputEnabled = !isProcessing && selectionState.allPapersReady;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedGradientBorder(
                borderRadius: 24,
                borderWidth: 1.5,
                duration:
                    Duration(seconds: _inputFocused || isProcessing ? 2 : 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Focus(
                          onFocusChange: (f) =>
                              setState(() => _inputFocused = f),
                          child: TextField(
                            controller: _inputController,
                            onChanged: _onTextChanged,
                            enabled: inputEnabled,
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(context),
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: selectionState.allPapersReady
                                  ? 'Ask anything or type / for commands'
                                  : 'Waiting for paper indexing…',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: GestureDetector(
                          onTap: inputEnabled
                              ? () => _sendMessage(context)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: inputEnabled
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.gradientBlue,
                                        AppColors.gradientSlateBlue,
                                      ],
                                    )
                                  : null,
                              color: inputEnabled
                                  ? null
                                  : cs.surfaceContainerHighest,
                              boxShadow: inputEnabled
                                  ? [
                                      BoxShadow(
                                        color: AppColors.gradientBlue
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isProcessing
                                ? const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_upward_rounded,
                                    color: inputEnabled
                                        ? Colors.white
                                        : cs.onSurfaceVariant,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StarterChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _StarterChip(
      {required this.label, required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  final ColorScheme cs;
  const _ThinkingDots({required this.cs});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = ((_controller.value * 3) - i).clamp(0.0, 1.0);
              final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(0, -4 * bounce),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gradientBlue,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
