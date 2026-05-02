import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purewill/core/widgets/clean_bottom_navigation_bar.dart';
import 'package:purewill/features/conversation/models/conversation_model.dart';
import 'package:purewill/features/conversation/providers/conversation_provider.dart';
import 'package:purewill/features/conversation/views/conversation_detail_screen.dart';
import 'package:purewill/features/habit/views/habit_screen.dart';
import 'package:purewill/features/home/views/home_screen.dart';
import 'package:purewill/features/nofap/views/nofap_screen.dart';
import 'package:purewill/core/widgets/dialogs/app_confirm_dialog.dart';
import 'package:purewill/core/widgets/dialogs/app_input_dialog.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  final _currentIndex = 3;
  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HabitScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NoFapScreen()),
      );
    } else if (index == 3) {
      return;
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ConversationListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        title: const Text(
          'Conversations',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewConversation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(conversationNotifierProvider.notifier).refresh();
            },
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading conversations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(conversationNotifierProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (conversations) => conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a new conversation to chat with AI',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _createNewConversation,
                      icon: const Icon(Icons.add),
                      label: const Text('New Conversation'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(conversationNotifierProvider.notifier)
                      .refresh();
                },
                child: ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ConversationListItem(
                      conversation: conversation,
                      onTap: () => _openConversation(conversation),
                      onDelete: () => _deleteConversation(conversation.id),
                    );
                  },
                ),
              ),
      ),
      bottomNavigationBar: CleanBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  void _createNewConversation() async {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppInputDialog(
        title: 'New Conversation',
        hintText: 'Enter conversation title (optional)',
        controller: titleController,
        confirmLabel: 'Create',
        onConfirm: () async {
          final title = titleController.text.trim().isEmpty
              ? null
              : titleController.text.trim();

          final result = await ref
              .read(conversationNotifierProvider.notifier)
              .createConversation(title: title);

          if (result != null && mounted) {
            _openConversation(result);
          }
        },
      ),
    );
  }

  void _openConversation(ConversationModel conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConversationDetailScreen(conversation: conversation),
      ),
    );
  }

  void _deleteConversation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Conversation',
        message: 'Are you sure you want to delete this conversation?',
        confirmLabel: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () async {
          final success = await ref
              .read(conversationNotifierProvider.notifier)
              .deleteConversation(conversationId);

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conversation deleted')),
            );
          }
        },
      ),
    );
  }
}

class ConversationListItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.chat_bubble_outline),
      title: Text(
        conversation.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.getFormattedDate(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(child: const Text('Delete'), onTap: onDelete),
        ],
      ),
      onTap: onTap,
    );
  }
}
