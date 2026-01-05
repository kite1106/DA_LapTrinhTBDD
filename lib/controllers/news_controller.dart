import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsController {
  final NewsService _newsService;

  NewsController({NewsService? newsService}) : _newsService = newsService ?? NewsService();

  Future<String> addNews(News news) {
    return _newsService.addNews(news);
  }
}
