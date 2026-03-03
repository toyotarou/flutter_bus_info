import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'screens/home_screen.dart';

//////////////////////////////////////////////////////////////////

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  runApp(const MyApp());
}

//////////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String endpoint = 'http://49.212.175.205:8081/graphql';

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink(endpoint);

    return GraphQLProvider(
      // ignore: always_specify_types
      client: ValueNotifier(
        GraphQLClient(
          link: httpLink,
          cache: GraphQLCache(store: HiveStore()),
        ),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111111),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(color: Color(0xFF1C1C1C)),
          dividerTheme: const DividerThemeData(color: Colors.white12),
          listTileTheme: const ListTileThemeData(textColor: Colors.white, iconColor: Colors.white60),
          expansionTileTheme: const ExpansionTileThemeData(
            iconColor: Colors.white60,
            collapsedIconColor: Colors.white54,
            textColor: Colors.white,
            collapsedTextColor: Colors.white,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1C1C1C)),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
