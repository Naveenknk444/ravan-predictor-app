import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

// Global Supabase client accessor
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ravan Predictor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
        useMaterial3: true,
      ),
      home: const ConnectionTestPage(),
    );
  }
}

// Temporary test page to verify Supabase connection
class ConnectionTestPage extends StatefulWidget {
  const ConnectionTestPage({super.key});

  @override
  State<ConnectionTestPage> createState() => _ConnectionTestPageState();
}

class _ConnectionTestPageState extends State<ConnectionTestPage> {
  String _status = 'Testing connection...';
  List<dynamic> _tiers = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      // Test query to fetch user tiers
      final response = await supabase
          .from('user_tiers')
          .select()
          .order('min_points');

      setState(() {
        _status = 'Connected successfully!';
        _tiers = response;
      });
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _status.contains('successfully')
                    ? Colors.green
                    : _status.contains('failed')
                        ? Colors.red
                        : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            if (_tiers.isNotEmpty) ...[
              const Text(
                'User Tiers from Database:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._tiers.map((tier) => Card(
                child: ListTile(
                  title: Text(tier['name'] ?? 'Unknown'),
                  subtitle: Text('Min Points: ${tier['min_points']} | Multiplier: ${tier['multiplier']}x'),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
