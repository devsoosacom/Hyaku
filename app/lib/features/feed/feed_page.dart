import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('百物語')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('まだ怪談がありません', style: TextStyle(color: Colors.grey)));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _PostCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PostCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final ts = data['createdAt'] as Timestamp?;
    final date = ts != null
        ? DateFormat('yyyy/MM/dd HH:mm').format(ts.toDate())
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(radius: 16, backgroundColor: Color(0xFF333333),
                child: Icon(Icons.person, size: 16, color: Colors.grey)),
            const SizedBox(width: 8),
            Text(data['authorName'] ?? '名無し',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(data['title'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            data['body'] ?? '',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFCCCCCC), height: 1.7),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${data['likeCount'] ?? 0}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(width: 16),
            const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${data['commentCount'] ?? 0}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}
