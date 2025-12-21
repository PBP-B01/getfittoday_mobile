import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/blogsnevents_model.dart';
import 'package:getfittoday_mobile/services/blogs_events_service.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'blogsnevents_detail.dart';
import 'blog_form_page.dart';
import 'event_form_page.dart';

class BlogsEventsPage extends StatefulWidget {
  const BlogsEventsPage({super.key});

  @override
  State<BlogsEventsPage> createState() => _BlogsEventsPageState();
}

class _BlogsEventsPageState extends State<BlogsEventsPage> {
  final BlogEventService _service = BlogEventService();
  final TextEditingController _searchController = TextEditingController();


  bool showBlogs = true;
  bool showOnlyMine = false;
  String searchQuery = '';



  List<Blog> blogs = [];
  List<Event> events = [];
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final request = context.read<CookieRequest>();

    await _fetchCurrentUser(request);

    blogs = await _service.fetchBlogs(request);
    events = await _service.fetchEvents(request);

    setState(() {});
  }

  Future<void> _fetchCurrentUser(CookieRequest request) async {
    try {
      final res = await request.get(
        '$djangoBaseUrl/blognevent/api/me/',
      );
      setState(() {
        currentUsername = res['username'];
      });
    } catch (_) {
      setState(() {
        currentUsername = null;
      });
    }
  }

  Future<void> _confirmDeleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final request = context.read<CookieRequest>();

    final response = await request.post(
      '$djangoBaseUrl/blognevent/api/events/$eventId/delete/',
      {},
    );

    if (response['success'] == true) {
      setState(() {
        events.removeWhere((e) => e.id == eventId);
      });
    }
  }

  Future<void> _confirmDeleteBlog(String blogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete blog'),
        content: const Text('Are you sure you want to delete this blog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBlog(blogId);
      _fetchData();
    }
  }

  Future<void> _deleteBlog(String blogId) async {
    final request = context.read<CookieRequest>();

    await request.post(
      '$djangoBaseUrl/blognevent/api/blogs/$blogId/delete/',
      {},
    );
  }

  @override
  Widget build(BuildContext context) {
    print('LOGGED IN USER = $currentUsername');
    final request = context.watch<CookieRequest>();
    final bool isLoggedIn = request.loggedIn;

    if (!isLoggedIn && showOnlyMine) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => showOnlyMine = false);
      });
    }

    final filteredBlogs = blogs.where((b) {
      final matchesSearch =
          searchQuery.isEmpty ||
              b.title.toLowerCase().contains(searchQuery);

      final matchesOwner =
          !showOnlyMine || b.isOwner;

      return matchesSearch && matchesOwner;
    }).toList();

    final filteredEvents = events.where((e) {
      final matchesSearch =
          searchQuery.isEmpty ||
              e.name.toLowerCase().contains(searchQuery);

      final matchesOwner =
          !showOnlyMine || e.isOwner;

      return matchesSearch && matchesOwner;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          const SiteNavBar(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'BLOGS & EVENTS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search blogs or events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.add),
                  onSelected: (value) {
                    if (value == 'blog') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BlogFormPage(),
                        ),
                      ).then((created) {
                        if (created == true) _fetchData();
                      });

                    } else if (value == 'event') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EventFormPage(),
                        ),
                      ).then((created) {
                        if (created == true) _fetchData();
                      });

                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'blog',
                      child: Text('Create Blog'),
                    ),
                    const PopupMenuItem(
                      value: 'event',
                      child: Text('Create Event'),
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _slidingToggle(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              value: isLoggedIn ? showOnlyMine : false,
              onChanged: isLoggedIn
                  ? (value) {
                setState(() {
                  showOnlyMine = value;
                });
              }
                  : null,
              title: Text(
                'View my own',
                style: TextStyle(
                  color: isLoggedIn ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: !isLoggedIn
                  ? const Text(
                'Log in to enable this filter',
                style: TextStyle(fontSize: 12),
              )
                  : null,
              dense: true,
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount:
              showBlogs ? filteredBlogs.length : filteredEvents.length,
              itemBuilder: (context, index) {
                return showBlogs
                    ? _buildBlogCard(filteredBlogs[index])
                    : _buildEventCard(filteredEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _slidingToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment:
            showBlogs ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width / 2 - 32,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => showBlogs = true),
                  child: Center(
                    child: Text(
                      'Blogs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: showBlogs ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => showBlogs = false),
                  child: Center(
                    child: Text(
                      'Events',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !showBlogs ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(Blog blog) {
    String briefDescription() {
      final words = blog.body.split(RegExp(r'\s+'));
      if (words.length <= 15) return blog.body;
      return words.take(15).join(' ') + '...';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlogsEventsDetailPage(
                blogId: blog.id,
                isBlog: true,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                blog.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                briefDescription(),
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 12),

            if (blog.isOwner)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit blog',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlogFormPage(blogId: blog.id),
                          ),
                        ).then((_) => _fetchData());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete blog',
                      onPressed: () => _confirmDeleteBlog(blog.id),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    String briefDescription() {
      final words = event.description.split(RegExp(r'\s+'));
      if (words.length <= 15) return event.description;
      return words.take(15).join(' ') + '...';
    }

    String formatDate(DateTime date) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(date.day)}/${two(date.month)}/${date.year.toString().substring(2)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlogsEventsDetailPage(
                eventId: event.id,
                isBlog: false,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Starting Date : ${formatDate(event.startingDate.toLocal())}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Ending Date   : ${formatDate(event.endingDate.toLocal())}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                briefDescription(),
                style: const TextStyle(fontSize: 14),
              ),

              if (event.locations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: event.locations.map((loc) {
                    return Chip(
                      label: Text(
                        loc,
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

            if (event.isOwner)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit event',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventFormPage(eventId: event.id),
                          ),
                        ).then((_) => _fetchData());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete event',
                      onPressed: () => _confirmDeleteEvent(event.id),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final d = twoDigits(date.day);
    final m = twoDigits(date.month);
    final y = date.year.toString().substring(2);
    final h = twoDigits(date.hour);
    final min = twoDigits(date.minute);

    return '$d/$m/$y $h:$min';
  }

  Widget _card({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
