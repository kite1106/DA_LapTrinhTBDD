import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'views/admin_home_screen.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';
import 'providers/favorites_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00A86B);
    return ChangeNotifierProvider<FavoritesProvider>(
      create: (_) => FavoritesProvider(),
      child: MaterialApp(
        title: 'Flutter Firebase App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGreen,
            primary: primaryGreen,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.read<FavoritesProvider>();
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // đồng bộ user cho favorites (async, không chờ)
          favorites.setUser(user.uid);
          final firestoreService = FirestoreService();

          return FutureBuilder<AppUser?>(
            future: firestoreService.getUserById(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final appUser = userSnapshot.data!;
                if (appUser.isAdmin) {
                  return const AdminHomeScreen();
                } else {
                  return const HomeScreen();
                }
              }

              // Nếu chưa có document user trên Firestore, mặc định coi là user thường
              return const HomeScreen();
            },
          );
        } else {
          favorites.setUser(null);
          return LoginScreen();
        }
      },
    );
  }
}
