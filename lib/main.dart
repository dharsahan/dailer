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
          title: 'Material 3 Dialer',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, // More expressive default
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            // Fallback font, but ideally we use standard Roboto/Product Sans for M3
          ),
          darkTheme: ThemeData(
             colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Keypad', style: theme.textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
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
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        _searchResults[index][0],
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text(
                      _searchResults[index],
                      style: theme.textTheme.bodyLarge,
                    ),
                    onTap: () {
                        // In a real app, this would fill the number
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Text(
                _input,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildKeypad(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, ['1', '2', '3']),
        _buildRow(context, ['4', '5', '6']),
        _buildRow(context, ['7', '8', '9']),
        _buildRow(context, ['*', '0', '#']),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 56), // Placeholder for alignment
              FloatingActionButton.large(
                heroTag: 'call_btn',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: const CircleBorder(), // Classic round FAB or slightly rounded for M3
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
                child: const Icon(Icons.call, size: 36),
              ),
              IconButton(
                onPressed: _onDelete,
                icon: const Icon(Icons.backspace_outlined),
                iconSize: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          return SizedBox(
            width: 72,
            height: 72,
            child: FilledButton.tonal(
              onPressed: () => _onKeyPress(key),
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                key,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                   fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CallScreen extends StatelessWidget {
    final CallState state;
    const CallScreen({super.key, required this.state});

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: colorScheme.tertiaryContainer,
                              child: Icon(Icons.person, size: 48, color: colorScheme.onTertiaryContainer),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              state.number,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.status.toString().split('.').last.toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.5,
                              )
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: FloatingActionButton.large(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            shape: const CircleBorder(),
                            onPressed: () {
                                // Implement Hangup
                                Navigator.pop(context);
                            },
                            child: const Icon(Icons.call_end, size: 36),
                        ),
                      )
                  ],
              ),
            ),
        );
    }
}
