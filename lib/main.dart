import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/security/fcm_service.dart';
import 'core/security/inactivity_manager.dart';
import 'core/security/inactivity_detector.dart';
import 'core/security/session_guard.dart';
import 'core/security/security_check_view.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/main_navigation_view.dart';
import 'features/auth/presentation/views/splash_view.dart';
import 'features/auth/presentation/views/terms_acceptance_view.dart';
import 'features/properties/data/datasources/property_remote_datasource.dart';
import 'features/properties/data/repositories/property_repository_impl.dart';
import 'features/properties/domain/usecases/get_properties_usecase.dart';
import 'features/properties/domain/usecases/create_property_usecase.dart';
import 'features/properties/domain/usecases/delete_property_usecase.dart';
import 'features/properties/presentation/viewmodels/property_viewmodel.dart';
import 'features/favorites/data/repositories/favorites_repository_impl.dart';
import 'features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'features/search/presentation/viewmodels/search_viewmodel.dart';

// Clave global para navegación sin contexto (útil para inactividad y wipes)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Stripe
  Stripe.publishableKey = 'pk_test_TU_PUBLISHABLE_KEY';
  await Stripe.instance.applySettings();
  
  // Inicializar FCM
  final fcmService = FcmService();
  await fcmService.initialize();

  // Escuchar el evento de Wipe Remoto de forma global
  FcmService.onWipeStream.listen((triggered) {
    if (triggered) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    }
  });

  await initializeDateFormatting('es', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HomeMatchApp());
}

class HomeMatchApp extends StatelessWidget {
  const HomeMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authDataSource = AuthRemoteDataSourceImpl();
    final authRepository = AuthRepositoryImpl(authDataSource);
    final propertyDataSource = PropertyRemoteDataSourceImpl();
    final propertyRepository = PropertyRepositoryImpl(propertyDataSource);
    final favoritesRepository = FavoritesRepositoryImpl();

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.playfairDisplay(fontSize: 45, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontSize: 16),
      bodyMedium: GoogleFonts.inter(fontSize: 14),
      bodySmall: GoogleFonts.inter(fontSize: 12),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
    );

    final materialTheme = MaterialTheme(textTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InactivityManager()),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            loginWithGoogleUseCase: LoginWithGoogleUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PropertyViewModel(
            getPropertiesUseCase: GetPropertiesUseCase(propertyRepository),
            createPropertyUseCase: CreatePropertyUseCase(propertyRepository),
            deletePropertyUseCase: DeletePropertyUseCase(propertyRepository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesViewModel(favoritesRepository),
        ),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'HomeMatch AI',
            debugShowCheckedModeBanner: false,
            theme: materialTheme.light(),
            darkTheme: materialTheme.dark(),
            themeMode: ThemeMode.light,
            builder: (context, child) {
              // El envoltorio de seguridad debe estar dentro de MaterialApp.builder
              // para tener acceso al contexto de Material (temas, etc.)
              // y para superponerse a toda la navegación.
              return SecurityCheckWrapper(
                child: InactivityDetector(
                  child: SessionGuard(
                    child: child!,
                  ),
                ),
              );
            },
            home: _getHome(authVM),
          );
        },
      ),
    );
  }

  Widget _getHome(AuthViewModel authVM) {
    switch (authVM.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashView();
      case AuthStatus.authenticated:
        if (authVM.user?.acceptedTerms == false) {
          return const TermsAcceptanceView();
        }
        return const MainNavigationView();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginView();
    }
  }
}