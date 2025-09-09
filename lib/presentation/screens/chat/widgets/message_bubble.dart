import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage? message;
  final String? streamingContent;
  final VoidCallback? onDelete;
  final bool isStreaming;

  const MessageBubble({
    Key? key,
    required this.message,
    this.onDelete,
  }) : streamingContent = null, isStreaming = false, super(key: key);

  const MessageBubble.streaming({
    Key? key,
    required String content,
  }) : message = null, streamingContent = content, onDelete = null, isStreaming = true, super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message?.isUser ?? false;
    final content = message?.content ?? streamingContent ?? '';
    final timestamp = message?.timestamp;
    final adType = message?.adType;

    final theme = Theme.of(context);

    // Bubble colors
    final userGradient = LinearGradient(
      colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final aiColor = theme.colorScheme.surfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (adType != null && adType.isNotEmpty)
                    Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          label: Text(
                            _getAdTypeDisplayName(adType),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Message bubble
                  GestureDetector(
                    onLongPress: message != null ? () => _showMessageOptions(context) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isUser ? userGradient : null,
                        color: isUser ? null : aiColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 6),
                          bottomRight: Radius.circular(isUser ? 6 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Use SelectableText for user convenience
                          SelectableText(
                            content,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                              fontSize: 15,
                              height: 1.32,
                            ),
                          ),

                          // Streaming indicator
                          if (isStreaming || (message?.metadata?['streaming'] == true))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isUser ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUser ? 'Sending...' : 'AI is replying...',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Timestamp
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                      child: Text(
                        DateFormat('HH:mm').format(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    if (message == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message!.content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Info'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Message details'),
                    content: SelectableText(message!.content),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () {
            Navigator.of(context).pop(true);
            onDelete?.call();
          }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  String _getAdTypeDisplayName(String value) {
    // Nicely format ad type value
    return value.split('.').last.replaceAll('_', ' ').toUpperCase();
  }
}
