import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/chat_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/voice_mode_bottom_sheet.dart';
import 'widgets/neural_core.dart';
import '../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatProvider provider) {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      provider.sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chatProvider.currentThread?.title ?? 'Max',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              chatProvider.isVoiceEnabled
                  ? Icons.hearing
                  : Icons.hearing_disabled,
            ),
            color: chatProvider.isVoiceEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            onPressed: () => chatProvider.toggleVoice(),
            tooltip: chatProvider.isVoiceEnabled ? 'Mute Max' : 'Unmute Max',
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const VoiceModeBottomSheet(),
              );
            },
            tooltip: 'Live Voice Mode',
          ),
        ],
      ),
      drawer: _buildDrawer(theme, chatProvider),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MaxNeuralCore(
                          state: chatProvider.isGenerating ? CoreState.thinking : CoreState.idle,
                          size: 180,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Ready to explore.",
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "What's on your mind?",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider
                          .messages[chatProvider.messages.length - 1 - index];
                      return ChatBubble(
                        text: message.text,
                        isUser: message.isUser,
                        base64Images: message.base64Images,
                      );
                    },
                  ),
          ),
          if (chatProvider.isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chatProvider.isUsingTool)
                      Icon(
                        chatProvider.currentToolName.contains("weather")
                            ? Icons.wb_sunny_outlined
                            : chatProvider.currentToolName.contains("search")
                                ? Icons.search
                                : Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.primary,
                      )
                    else
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      chatProvider.currentPhrase,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: chatProvider.isUsingTool ? theme.colorScheme.primary : null,
                        fontWeight: chatProvider.isUsingTool ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildInputArea(theme, chatProvider),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  subtitle: const Text('Pick up to 6 images'),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(ThemeData theme, ChatProvider provider) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.createNewThread();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: provider.threads.length,
                itemBuilder: (context, index) {
                  final thread = provider.threads[provider.threads.length - 1 - index];
                  final isSelected = thread.id == provider.currentThreadId;

                  return ListTile(
                    selected: isSelected,
                    leading: Icon(
                      isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: Text(
                      thread.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      provider.switchThread(thread.id);
                      Navigator.pop(context);
                    },
                    trailing: isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showRenameDialog(thread.id, thread.title, provider),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _showDeleteConfirm(thread.id, provider),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),
            ),
              const Divider(),
            ListTile(
              leading: const Icon(Icons.psychology_outlined),
              title: const Text('Your Persona'),
              subtitle: const Text('What Max remembers about you'),
              onTap: () {
                Navigator.pop(context);
                _showPersonaVault(context, provider);
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showClearConfirm(context, provider, true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Clear All Chats'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showClearConfirm(context, provider, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                    icon: const Icon(Icons.memory_outlined, size: 18),
                    label: const Text('Clear My Memory'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonaVault(BuildContext context, ChatProvider provider) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentFacts = provider.memoryService.getFacts();
          return AlertDialog(
            backgroundColor: MaxTheme.surface.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 12),
                Text('Your Persona', style: theme.textTheme.titleLarge),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "This is the identity Max has built based on your conversations.",
                      style: theme.textTheme.bodyMedium?.copyWith(color: MaxTheme.secondary),
                    ),
                    const SizedBox(height: 16),
                    if (currentFacts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text("No facts remembered yet."),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: currentFacts.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentFacts[index],
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                                    onPressed: () async {
                                      await provider.deleteFact(index);
                                      setDialogState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearConfirm(BuildContext context, ChatProvider provider, bool isChats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isChats ? 'Clear All Chats' : 'Clear My Memory'),
        content: Text(isChats
            ? 'Are you sure you want to delete EVERY conversation? This cannot be undone.'
            : 'Are you sure you want to clear everything Max has learned about you? This resets his personalized memory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (isChats) {
                provider.clearAllChats();
              } else {
                provider.clearAllMemory();
              }
              Navigator.pop(context);
              Navigator.pop(context); // Close Drawer
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String id, String currentTitle, ChatProvider provider) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new title'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameThread(id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this conversation? Max will still remember the facts he learned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteThread(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: MaxTheme.glassDecoration,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.pickedImages.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 8, left: 16),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.pickedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(provider.pickedImages[index]),
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => provider.removePickedImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  color: theme.colorScheme.primary,
                  onPressed: provider.isOffline
                      ? null
                      : () => _showImageSourceSheet(context, provider),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !provider.isOffline,
                    keyboardType: TextInputType.multiline,
                    maxLines: 6,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(provider),
                    decoration: InputDecoration(
                      hintText: provider.isOffline
                          ? 'Offline: Connect to internet'
                          : _isListening
                          ? 'Listening...'
                          : 'Message Max...',
                      hintStyle: TextStyle(
                        color: provider.isOffline ? Colors.redAccent : null,
                      ),
                      filled: true,
                      fillColor: provider.isOffline
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, child) {
                    bool hasText = value.text.trim().isNotEmpty;

                    return GestureDetector(
                      onTap: hasText && !provider.isOffline
                          ? () => _sendMessage(provider)
                          : null,
                      onLongPressStart: hasText || provider.isOffline
                          ? null
                          : (_) async {
                              setState(() => _isListening = true);
                              await provider.voiceService.startListening((
                                text,
                              ) {
                                _textController.text = text;
                              });
                            },
                      onLongPressEnd: hasText || provider.isOffline
                          ? null
                          : (_) async {
                              setState(() => _isListening = false);
                              await provider.voiceService.stopListening();
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: provider.isOffline
                              ? Colors.grey
                              : _isListening
                              ? Colors.green
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          hasText ? Icons.send : Icons.mic,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
