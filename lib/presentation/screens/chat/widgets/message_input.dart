import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat_provider.dart';

class MessageInput extends StatefulWidget {
  final Future<void> Function(String) onSendMessage;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _controller.text.trim().isNotEmpty;
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Fire-and-forget: start sending but clear input immediately so the
    // user's bubble can appear and the user can continue typing.
    widget.onSendMessage(text).catchError((e) {
      // Show error but keep UX responsive
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    });

    // Clear input immediately
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isLoading = chatProvider.isLoading || chatProvider.isStreaming;
        
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // Quick Actions Button
              IconButton(
                onPressed: isLoading ? null : () => _showQuickActions(context),
                icon: const Icon(Icons.add),
                tooltip: 'Quick actions',
              ),
              
              // Text Input
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Enter your advertising question...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: isLoading ? null : (_) => _handleSendMessage(),
                ),
              ),
              
              // Voice Input Button (placeholder)
              IconButton(
                onPressed: isLoading ? null : () => _showVoiceInputDialog(context),
                icon: const Icon(Icons.mic),
                tooltip: 'Voice input',
              ),
              
              // Send Button
              Container(
                margin: const EdgeInsets.only(right: 4),
                child: isLoading
                    ? Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _isComposing ? () => _handleSendMessage() : null,
                        icon: Icon(
                          Icons.send,
                          color: _isComposing
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        tooltip: 'Send message',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Suggested questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _getQuickQuestions().length,
                itemBuilder: (context, index) {
                  final question = _getQuickQuestions()[index];
                  return ListTile(
                    title: Text(
                      question,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _controller.text = question;
                      _handleSendMessage();
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showVoiceInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice input'),
        content: const Text('Voice input feature will be developed in the next version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<String> _getQuickQuestions() {
    return [
      'How to optimize a Google Ads campaign?',
      'How should I allocate budget for Facebook Ads?',
      'How to increase CTR for Instagram ads?',
      'Effective targeting audience for TikTok Ads?',
      'Analyze ROI of an advertising campaign?',
      'How to write attractive ad copy?',
      'Optimize landing page for conversions?',
      'How to A/B test ads?',
    ];
  }
}
