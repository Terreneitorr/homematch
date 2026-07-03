import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_with_google_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/main_navigation_view.dart';
import 'features/properties/data/datasources/property_remote_datasource.dart';
import 'features/properties/data/repositories/property_repository_impl.dart';
import 'features/properties/domain/usecases/get_properties_usecase.dart';
import 'features/properties/domain/usecases/create_property_usecase.dart';
import 'features/properties/domain/usecases/delete_property_usecase.dart';
import 'features/properties/presentation/viewmodels/property_viewmodel.dart';
import 'features/favorites/data/repositories/favorites_repository_impl.dart';
import 'features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'features/search/presentation/viewmodels/search_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
    );

    final materialTheme = MaterialTheme(textTheme);

    return MultiProvider(
      providers: [
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
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'HomeMatch AI',
        debugShowCheckedModeBanner: false,
        theme: materialTheme.light(),
        darkTheme: materialTheme.dark(),
        themeMode: ThemeMode.light,
        home: Consumer<AuthViewModel>(
          builder: (context, authVM, _) {
            if (authVM.status == AuthStatus.authenticated) {
              return const MainNavigationView();
            }
            return const LoginView();
          },
        ),
      ),
    );
  }
}