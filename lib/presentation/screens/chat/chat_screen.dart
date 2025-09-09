import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/ad_type_selector.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advertising Support Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'clear':
                      await _showClearChatDialog(context, chatProvider);
                      break;
                    case 'refresh':
                      await chatProvider.refreshChatHistory();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear history'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ad Type Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const AdTypeSelector(),
          ),
          
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.state == ChatState.loading && chatProvider.messages.isEmpty) {
                  return const Center(child: LoadingWidget());
                }

                if (chatProvider.state == ChatState.error && chatProvider.messages.isEmpty) {
                  return Center(
                    child: CustomErrorWidget(
                      message: chatProvider.errorMessage ?? 'An error occurred',
                      onRetry: () => chatProvider.refreshChatHistory(),
                    ),
                  );
                }

                final listView = ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: () {
                    final hasPlaceholder = chatProvider.messages.isNotEmpty &&
                        (chatProvider.messages.last.metadata?['streaming'] == true);
                    return chatProvider.messages.length +
                        ((chatProvider.isStreaming && !hasPlaceholder) ? 1 : 0);
                  }(),
                  itemBuilder: (context, index) {
                    final hasPlaceholder = chatProvider.messages.isNotEmpty &&
                        (chatProvider.messages.last.metadata?['streaming'] == true);

                    if (index < chatProvider.messages.length) {
                      final message = chatProvider.messages[index];
                      return MessageBubble(
                        message: message,
                        onDelete: () => chatProvider.deleteMessage(message.id),
                      );
                    } else {
                      // Streaming message only when there is no placeholder saved in DB
                      return MessageBubble.streaming(
                        content: chatProvider.currentStreamingMessage,
                      );
                    }
                  },
                );

                // Ensure we scroll to bottom after this frame when there are
                // messages or when streaming is active so newly added user
                // message is visible immediately.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if ((chatProvider.messages.isNotEmpty || chatProvider.isStreaming) && _scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                return listView;
              },
            ),
          ),

          // Error Banner
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.errorMessage != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatProvider.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: chatProvider.clearError,
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: MessageInput(
              onSendMessage: (message) async {
                await context.read<ChatProvider>().sendMessageStream(message);
                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearChatDialog(BuildContext context, ChatProvider chatProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat history'),
        content: const Text('Are you sure you want to clear all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await chatProvider.clearChatHistory();
    }
  }
}
