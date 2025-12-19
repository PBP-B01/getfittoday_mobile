import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:getfittoday_mobile/models/blogsnevents_model.dart';

class BlogEventService {
  static const String baseUrl = 'http://localhost:8000';


  // Fetch all events
  Future<List<Event>> fetchEvents(CookieRequest request) async {
    try {
      final response = await request.get('$baseUrl/blognevent/api/events/');

      if (response is List) {
        return response.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Fetch all blogs
  Future<List<Blog>> fetchBlogs(CookieRequest request) async {
    try {
      final response = await request.get('$baseUrl/blognevent/api/blogs/');

      if (response is List) {
        return response.map((json) => Blog.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching blogs: $e');
      return [];
    }
  }

  // Fetch single event detail
  Future<Event?> fetchEventDetail(CookieRequest request, String eventId) async {
    try {
      final response = await request.get('$baseUrl/blognevent/api/event/$eventId/');
      return Event.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching event detail: $e');
      return null;
    }
  }

  // Fetch single blog detail
  Future<Blog?> fetchBlogDetail(CookieRequest request, String blogId) async {
    try {
      final response = await request.get('$baseUrl/blognevent/api/blog/$blogId/');
      return Blog.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching blog detail: $e');
      return null;
    }
  }

  // Delete event
  Future<bool> deleteEvent(CookieRequest request, String eventId) async {
    try {
      final response = await request.post(
        '$baseUrl/blognevent/delete-event/$eventId/',
        {},
      );
      return response['success'] == true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Delete blog
  Future<bool> deleteBlog(CookieRequest request, String blogId) async {
    try {
      final response = await request.post(
        '$baseUrl/blognevent/delete-blog/$blogId/',
        {},
      );
      return response['success'] == true;
    } catch (e) {
      print('Error deleting blog: $e');
      return false;
    }
  }
}