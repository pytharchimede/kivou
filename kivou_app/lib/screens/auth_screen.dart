import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isAuthenticated) {
      // If already logged, go home/profile
      Future.microtask(() => context.go('/home'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion / Inscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Accueil',
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Se connecter'),
          Tab(text: 'Créer un compte'),
        ]),
      ),
      body: TabBarView(controller: _tab, children: [
        _LoginForm(
            loading: loading,
            onSubmit: _doLogin,
            email: _loginEmail,
            pass: _loginPass),
        _RegisterForm(
            loading: loading,
            onSubmit: _doRegister,
            name: _regName,
            email: _regEmail,
            phone: _regPhone,
            pass: _regPass),
      ]),
    );
  }

  Future<void> _doLogin(String email, String pass) async {
    setState(() => loading = true);
    try {
      await ref.read(authStateProvider.notifier).login(email, pass);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _doRegister(
      String name, String email, String phone, String pass) async {
    setState(() => loading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .register(email, pass, name, phone: phone.isEmpty ? null : phone);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _LoginForm extends StatelessWidget {
  final bool loading;
  final void Function(String email, String pass) onSubmit;
  final TextEditingController email;
  final TextEditingController pass;
  const _LoginForm(
      {required this.loading,
      required this.onSubmit,
      required this.email,
      required this.pass});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(
            controller: pass,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            obscureText: true),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                loading ? null : () => onSubmit(email.text.trim(), pass.text),
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Se connecter'),
          ),
        )
      ]),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final bool loading;
  final void Function(String name, String email, String phone, String pass)
      onSubmit;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController pass;
  const _RegisterForm(
      {required this.loading,
      required this.onSubmit,
      required this.name,
      required this.email,
      required this.phone,
      required this.pass});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 12),
          TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Téléphone')),
          const SizedBox(height: 12),
          TextField(
              controller: pass,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading
                  ? null
                  : () => onSubmit(name.text.trim(), email.text.trim(),
                      phone.text.trim(), pass.text),
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Créer mon compte"),
            ),
          )
        ]),
      ),
    );
  }
}
