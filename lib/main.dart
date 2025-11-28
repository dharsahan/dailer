import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/dialer/call_bloc.dart';
import 'features/dialer/call_state.dart';
import 'core/call_repository.dart';
import 'features/contacts/contact_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => CallRepository()),
        RepositoryProvider(create: (context) => ContactRepository()),
      ],
      child: BlocProvider(
        create: (context) => CallBloc(context.read<CallRepository>()),
        child: MaterialApp(
          title: 'iOS Style Dialer',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            fontFamily: 'San Francisco', // Fallback will be used if not found
          ),
          home: const DialerPage(),
        ),
      ),
    );
  }
}

class DialerPage extends StatefulWidget {
  const DialerPage({super.key});

  @override
  State<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends State<DialerPage> {
  String _input = "";
  List<String> _searchResults = [];

  void _onKeyPress(String key) {
    setState(() {
      _input += key;
    });
    _searchContacts();
  }

  // ignore: unused_element
  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
      _searchContacts();
    }
  }

  void _searchContacts() async {
    if (_input.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final results = await context.read<ContactRepository>().searchContacts(_input);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Keypad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_phone),
            onPressed: () async {
              try {
                await context.read<CallBloc>().requestDefaultDialer();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error setting default dialer: $e')),
                  );
                }
              }
            },
          )
        ],
      ),
      body: BlocListener<CallBloc, CallState>(
        listener: (context, state) {
          if (state.status == CallStatus.active || state.status == CallStatus.ringing || state.status == CallStatus.dialing) {
             Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallScreen(state: state)));
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults[index]),
                    onTap: () {
                        // In a real app, this would fill the number
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _input,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow(['*', '0', '#']),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            shape: const CircleBorder(),
            onPressed: () async {
              if (_input.isNotEmpty) {
                try {
                  await context.read<CallBloc>().makeCall(_input);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error making call: $e')),
                  );
                }
              }
            },
            child: const Icon(Icons.call, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _onKeyPress(key),
            child: Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Text(
                key,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CallScreen extends StatelessWidget {
    final CallState state;
    const CallScreen({super.key, required this.state});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Icon(Icons.person, size: 100, color: Colors.white),
                        const SizedBox(height: 20),
                        Text(state.number, style: const TextStyle(color: Colors.white, fontSize: 30)),
                        const SizedBox(height: 10),
                        Text(state.status.toString().split('.').last.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 50),
                        FloatingActionButton(
                            backgroundColor: Colors.red,
                            onPressed: () {
                                // Implement Hangup
                                Navigator.pop(context);
                            },
                            child: const Icon(Icons.call_end),
                        )
                    ],
                ),
            ),
        );
    }
}
