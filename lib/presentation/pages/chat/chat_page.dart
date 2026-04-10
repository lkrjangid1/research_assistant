import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart';
import '../../cubits/chat/chat_cubit.dart';
import '../../cubits/chat/chat_state.dart';
import '../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../cubits/paper_selection/paper_selection_state.dart';
import 'widgets/message_bubble.dart';
import 'widgets/slash_command_overlay.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (ctx) {
        final selection = ctx.read<PaperSelectionCubit>().state;
        return sl<ChatCubit>()..initSession(selection.selectedPapers);
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
    _inputController.selection = TextSelection.collapsed(offset: command.length + 1);
    setState(() => _showSlashOverlay = false);
  }

  void _sendMessage(BuildContext context) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final selectionState = context.read<PaperSelectionCubit>().state;
    context.read<ChatCubit>().sendMessage(text, selectionState.paperTitles);
    _inputController.clear();
    setState(() => _showSlashOverlay = false);
    _scrollToBottom();
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
    return BlocBuilder<PaperSelectionCubit, PaperSelectionState>(
      builder: (context, selState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              selState.selectedPapers.isEmpty
                  ? 'Chat'
                  : '${selState.selectedPapers.length} paper${selState.selectedPapers.length > 1 ? 's' : ''} selected',
            ),
            bottom: selState.selectedPapers.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(32),
                    child: SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        children: selState.selectedPapers.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(
                                p.title.length > 25
                                    ? '${p.title.substring(0, 25)}…'
                                    : p.title,
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                : null,
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(context)),
              if (_showSlashOverlay)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SlashCommandOverlay(
                    query: _slashQuery,
                    onSelect: _selectCommand,
                  ),
                ),
              _buildInputBar(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatSessionLoaded) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is ChatInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChatError) {
          return Center(
            child: Text(state.message, style: const TextStyle(color: Colors.red)),
          );
        }

        if (state is ChatSessionLoaded) {
          if (state.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Ask a question about your selected papers',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _starterChip(context, 'Summarize these papers'),
                      _starterChip(context, '/compare methodologies'),
                      _starterChip(context, '/gaps research gaps'),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.messages.length + (state.isProcessing ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.messages.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Thinking…', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return MessageBubble(message: state.messages[i]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _starterChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _inputController.text = label;
        _sendMessage(context);
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final isProcessing = state is ChatSessionLoaded && state.isProcessing;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onChanged: _onTextChanged,
                    enabled: !isProcessing,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(context),
                    decoration: InputDecoration(
                      hintText: 'Ask a question or type / for commands…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: isProcessing ? null : () => _sendMessage(context),
                  child: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
