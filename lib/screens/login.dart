import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/screens/register.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _nextRouteFromArgs(Object? args) {
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final next = args['next'];
      if (next is String && next.trim().isNotEmpty) return next.trim();
    }
    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final nextRoute =
        _nextRouteFromArgs(ModalRoute.of(context)?.settings.arguments);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: const Text('GETFIT.TODAY'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: cardBorderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(48, 13, 43, 63),
                      offset: Offset(0, 12),
                      blurRadius: 28,
                    ),
                    BoxShadow(
                      color: Color.fromARGB(32, 13, 43, 63),
                      offset: Offset(0, 40),
                      blurRadius: 80,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 28.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LOGIN',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30.0),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                        ),
                        style: const TextStyle(color: inputTextColor),
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                        ),
                        style: const TextStyle(color: inputTextColor),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: () async {
                          final username = _usernameController.text;
                          final password = _passwordController.text;

                          try {
                            final response = await request.login(
                              '$djangoBaseUrl/auth/login/',
                              {
                                'username': username,
                                'password': password,
                              },
                            );

                            if (!mounted) return;

                            if (request.loggedIn) {
                              final message =
                                  response['message'] ?? 'Login successful!';
                              final uname = response['username'] ?? username;
                              context.read<AuthState>().setFromLoginResponse(
                                    Map<String, dynamic>.from(response),
                                    fallbackUsername: uname,
                                  );

                              final targetRoute = (nextRoute == null ||
                                      nextRoute == '/login')
                                  ? '/home'
                                  : nextRoute;
                              Navigator.pushReplacementNamed(
                                context,
                                targetRoute,
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('$message Welcome, $uname.'),
                                    backgroundColor: accentDarkColor,
                                  ),
                                );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Login Failed'),
                                  content: Text(
                                    response['message'] ??
                                        'Login failed, please check your credentials.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Login error: ${e.toString().split(":").last.trim()}',
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                ),
                              );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: accentColor,
                          foregroundColor: inputTextColor,
                          textStyle: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          shadowColor: accentDarkColor.withOpacity(0.3),
                          elevation: 8,
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 36.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              fontSize: 15.0,
                              color: inkWeakColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0),
                              foregroundColor: accentDarkColor,
                              textStyle: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
