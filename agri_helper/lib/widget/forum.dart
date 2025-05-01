// lib/widget/forum.dart
import 'package:flutter/material.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _composerCtrl = TextEditingController();
  final List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _composerCtrl.dispose();
    super.dispose();
  }

  void _addPost() {
    final txt = _composerCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _posts.insert(0, Post(
        avatarUrl: null,
        displayName: 'You',
        handle: '@you',
        time: DateTime.now(),
        content: txt,
      ));
      _composerCtrl.clear();
    });
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/avatar.png')),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _composerCtrl,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's happening?",
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: _addPost,
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    final timeAgo = _formatTime(post.time);
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: post.avatarUrl != null
                ? NetworkImage(post.avatarUrl!)
                : const AssetImage('assets/avatar.png') as ImageProvider,
          ),
          title: Row(
            children: [
              Text(post.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(post.handle, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 4),
              Text('· $timeAgo', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(post.content),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 72),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.chat_bubble_outline, size: 18),
              Icon(Icons.favorite_border, size: 18),
              Icon(Icons.share_outlined, size: 18),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Live'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB POSTS ---
          Column(
            children: [
              _buildComposer(),
              const Divider(height: 1),
              Expanded(
                child: _posts.isEmpty
                    ? const Center(child: Text('No posts yet'))
                    : ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (_, i) => _buildPostItem(_posts[i]),
                      ),
              ),
            ],
          ),

          // --- TAB LIVE (coming soon) ---
          const Center(
            child: Text(
              'Livestream feature coming soon!',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class Post {
  final String? avatarUrl;
  final String displayName;
  final String handle;
  final DateTime time;
  final String content;

  Post({
    this.avatarUrl,
    required this.displayName,
    required this.handle,
    required this.time,
    required this.content,
  });
}
