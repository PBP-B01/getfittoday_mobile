import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/blogsnevents_model.dart';
import 'package:getfittoday_mobile/services/blogs_events_service.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class BlogsEventsDetailPage extends StatefulWidget {
  final String? blogId;
  final String? eventId;
  final bool isBlog;

  const BlogsEventsDetailPage({
    super.key,
    this.blogId,
    this.eventId,
    required this.isBlog,
  });

  @override
  State<BlogsEventsDetailPage> createState() => _BlogsEventsDetailPageState();
}

class _BlogsEventsDetailPageState extends State<BlogsEventsDetailPage> {
  final BlogEventService _service = BlogEventService();

  Blog? blog;
  Event? event;

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final request = context.read<CookieRequest>();

    try {
      if (widget.isBlog) {
        final data =
        await _service.fetchBlogDetail(request, widget.blogId!);
        blog = Blog.fromJson(data);
      } else {
        final data =
        await _service.fetchEventDetail(request, widget.eventId!);
        event = Event.fromJson(data);
      }
    } catch (e) {
      error = e.toString();
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(error!)),
      );
    }

    return widget.isBlog ? _buildBlogDetail() : _buildEventDetail();
  }

  Widget _buildBlogDetail() {
    final b = blog!;

    return Scaffold(
      appBar: AppBar(title: Text(b.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(b.image),
            const SizedBox(height: 16),

            Text(
              b.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Author: ${b.author}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),
            Text(
              b.body,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),
            if (b.isOwner) _buildOwnerBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail() {
    final e = event!;

    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(e.image),
            const SizedBox(height: 16),

            Text(
              e.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Organized by: ${e.user}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),
            _buildInfoRow(
              'Start Date',
              e.startingDate.toLocal().toString(),
            ),
            _buildInfoRow(
              'End Date',
              e.endingDate.toLocal().toString(),
            ),

            const SizedBox(height: 12),
            if (e.locations.isNotEmpty) ...[
              const Text(
                'Locations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(e.locations.join(', ')),
              const SizedBox(height: 16),
            ],

            Text(
              e.description,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),
            if (e.isOwner) _buildOwnerBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildOwnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'You are the owner',
        style: TextStyle(
          color: Colors.teal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
