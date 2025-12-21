import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/constants.dart';
class BlogFormPage extends StatefulWidget {
  final String? blogId;
  const BlogFormPage({
    super.key,
    this.blogId,
  });

  @override
  State<BlogFormPage> createState() => _BlogFormPageState();
}

class _BlogFormPageState extends State<BlogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();

  bool isSubmitting = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlogData();
    });
  }

  Future<void> _submitBlog(CookieRequest request) async {
    final url = widget.blogId == null
        ? '$djangoBaseUrl/blognevent/api/blog/create/'
        : '$djangoBaseUrl/blognevent/api/blogs/${widget.blogId}/edit/';

    final response = await request.post(
      url,
      {
        'title': _titleController.text,
        'body': _bodyController.text,
        'image': _imageController.text,
      },
    );

    if (response['success'] == true) {
      Navigator.pop(context); // go back to list
    } else {
      // show error
    }
  }
  Future<void> _submit() async {
    final request = context.read<CookieRequest>();
    await _submitBlog(request);
  }
  Future<void> _loadBlogData() async {
    if (widget.blogId == null) return;

    setState(() {
      isLoading = true;
    });

    final request = context.read<CookieRequest>();

    final response = await request.get(
      '$djangoBaseUrl/blognevent/api/blogs/${widget.blogId}/',
    );

    _titleController.text = response['title'] ?? '';
    _bodyController.text = response['body'] ?? '';
    _imageController.text = response['image'] ?? '';

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blogId == null ? 'Create Blog' : 'Edit Blog'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 6,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: Text(
                  widget.blogId == null ? 'Create Blog' : 'Update Blog',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
