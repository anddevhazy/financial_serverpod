import 'dart:async';

import 'package:fine_man_client/fine_man_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'client.dart';
import 'data/ledger_repository.dart';
import 'data/server_ledger_repository.dart';
import 'screens/sign_in_screen.dart';
import 'screens/tables_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Runs without a server, keeping tables in this browser only:
/// `flutter run --dart-define=LOCAL_MODE=true`.
const _localMode = bool.fromEnvironment('LOCAL_MODE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final local = await LocalLedgerRepository.open();
  if (!_localMode) await initializeClient();
  runApp(_localMode ? LocalFineManApp(local: local) : FineManApp(local: local));
}

/// The app with no server or accounts.
class LocalFineManApp extends StatelessWidget {
  const LocalFineManApp({super.key, required this.local});

  final LocalLedgerRepository local;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fine Man',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => Column(
        children: [
          const LocalModeBanner(),
          Expanded(child: child!),
        ],
      ),
      home: TablesScreen(repo: local),
    );
  }
}

/// The app with accounts. Owns the signed-in user's repository, which lasts as
/// long as they stay signed in.
class FineManApp extends StatefulWidget {
  const FineManApp({super.key, required this.local});

  /// Tables saved in this browser, offered for moving into the account.
  final LocalLedgerRepository local;

  @override
  State<FineManApp> createState() => _FineManAppState();
}

class _FineManAppState extends State<FineManApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  UuidValue? _user;
  ServerLedgerRepository? _repo;

  @override
  void initState() {
    super.initState();
    client.auth.authInfoListenable.addListener(_onAuthChanged);
    _user = client.auth.authInfo?.authUserId;
    if (_user != null) _repo = _newRepo();
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_onAuthChanged);
    _repo?.dispose();
    super.dispose();
  }

  ServerLedgerRepository _newRepo() => ServerLedgerRepository(
    ClientLedgerApi(client),
    onRejected: (message) => _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message))),
  );

  // Token refreshes also land here, so this acts only when the user changes.
  void _onAuthChanged() {
    final user = client.auth.authInfo?.authUserId;
    if (user == _user) return;
    // Open screens hold the old repository; none may outlive it.
    _navigator.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _repo?.dispose();
      _user = user;
      _repo = user == null ? null : _newRepo();
    });
  }

  Future<void> _signOut() async {
    // Gives changes on their way a moment to arrive while still signed in.
    try {
      await _repo?.flush().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Signing out shouldn't get stuck on a save that can't finish.
    }
    await client.auth.signOutDevice();
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    return MaterialApp(
      title: 'Fine Man',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: _navigator,
      scaffoldMessengerKey: _messenger,
      builder: (context, child) => repo == null
          ? child!
          : ValueListenableBuilder(
              valueListenable: repo.connected,
              builder: (context, connected, _) => Column(
                children: [
                  if (!connected) const OfflineBanner(),
                  Expanded(child: child!),
                ],
              ),
            ),
      home: repo == null
          ? const SignInScreen()
          : TablesScreen(
              key: ValueKey(_user),
              repo: repo,
              moveFrom: widget.local,
              onSignOut: () => unawaited(_signOut()),
            ),
    );
  }
}
