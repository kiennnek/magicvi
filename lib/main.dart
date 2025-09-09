import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Data sources
import 'data/datasources/local/hive_database.dart';
import 'data/datasources/remote/gemini_api_service.dart';

// Repositories
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/advertisement_repository_impl.dart';
import 'data/repositories/analytics_repository_impl.dart';

// Use cases
import 'domain/usecases/send_message_usecase.dart';
import 'domain/usecases/get_ad_suggestions_usecase.dart';
import 'domain/usecases/generate_analytics_usecase.dart';

// Providers
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/advertisement_provider.dart';
import 'presentation/providers/analytics_provider.dart';

// Screens
import 'presentation/screens/home/home_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await HiveDatabase.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Data sources - lowest level dependencies
        Provider<GeminiApiService>(
          create: (_) => GeminiApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        
        // Repositories - depend only on data sources
        Provider<ChatRepositoryImpl>(
          create: (_) => ChatRepositoryImpl(),
          dispose: (_, repo) => repo.dispose(),
        ),
        Provider<AdvertisementRepositoryImpl>(
          create: (_) => AdvertisementRepositoryImpl(),
          dispose: (_, repo) => repo.dispose(),
        ),
        Provider<AnalyticsRepositoryImpl>(
          create: (_) => AnalyticsRepositoryImpl(),
          dispose: (_, repo) => repo.dispose(),
        ),
        
        // Use cases - depend on repositories and data sources
        Provider<SendMessageUseCase>(
          create: (context) => SendMessageUseCase(
            context.read<ChatRepositoryImpl>(),
            context.read<GeminiApiService>(),
          ),
        ),
        Provider<GetAdSuggestionsUseCase>(
          create: (context) => GetAdSuggestionsUseCase(
            context.read<AdvertisementRepositoryImpl>(),
            context.read<GeminiApiService>(),
          ),
        ),
        Provider<GenerateAnalyticsUseCase>(
          create: (context) => GenerateAnalyticsUseCase(
            context.read<AnalyticsRepositoryImpl>(),
            context.read<GeminiApiService>(),
          ),
        ),
        
        // Change notifier providers - highest level dependencies
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(
            context.read<SendMessageUseCase>(),
          ),
        ),
        ChangeNotifierProvider<AdvertisementProvider>(
          create: (context) => AdvertisementProvider(
            context.read<GetAdSuggestionsUseCase>(),
          ),
        ),
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (context) => AnalyticsProvider(
            context.read<GenerateAnalyticsUseCase>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Advertising Topic Support',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
