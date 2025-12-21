import 'package:getfittoday_mobile/models/blogsnevents_model.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:getfittoday_mobile/utils/constants.dart';


class BlogEventService {

  static const String _baseApiUrl =
      '$djangoBaseUrl/blognevent/api';

  Future<List<Blog>> fetchBlogs(CookieRequest request) async {
    final url = '$_baseApiUrl/blogs/';
    print('FETCH BLOGS URL: $url');

    final response = await request.get(url);

    if (response is String) {
      throw Exception('Server returned HTML instead of JSON (blogs list)');
    }

    return (response as List)
        .map<Blog>((json) => Blog.fromJson(json))
        .toList();
  }

  Future<List<Event>> fetchEvents(CookieRequest request) async {
    final url = '$_baseApiUrl/events/';
    print('FETCH EVENTS URL: $url');

    final response = await request.get(url);

    if (response is String) {
      throw Exception('Server returned HTML instead of JSON (events list)');
    }

    return (response as List)
        .map<Event>((json) => Event.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> fetchBlogDetail(
      CookieRequest request,
      String blogId,
      ) async {
    final url = '$_baseApiUrl/blogs/$blogId/';
    print('DETAIL URL (BLOG): $url');

    final response = await request.get(url);

    if (response is String) {
      print(response.substring(0, 200));
      throw Exception('Server returned HTML instead of JSON (blog detail)');
    }

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchEventDetail(
      CookieRequest request,
      String eventId,
      ) async {
    final url = '$_baseApiUrl/events/$eventId/';
    print('DETAIL URL (EVENT): $url');

    final response = await request.get(url);

    if (response is String) {
      print(response.substring(0, 200));
      throw Exception('Server returned HTML instead of JSON (event detail)');
    }

    return response as Map<String, dynamic>;
  }
}
