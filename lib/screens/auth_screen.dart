import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../themes/minecraft_theme.dart';
import 'package:flutter/services.dart';
import '../widgets/app_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
      _checkAuthState();
    });
  }

  void _updateSystemUI() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final backgroundColor = Theme.of(context).colorScheme.background;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeProvider.isDarkMode 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarDividerColor: backgroundColor,
        systemNavigationBarIconBrightness: themeProvider.isDarkMode 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }

  Future<void> _checkAuthState() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUserSync();
    
    if (currentUser != null && mounted) {
      debugPrint('Пользователь уже авторизован, переход на главный экран');
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success;
      
      if (_isLogin) {
        debugPrint('Попытка входа для пользователя: ${_usernameController.text}');
        success = await authService.login(
          _usernameController.text,
          _passwordController.text,
        );
      } else {
        debugPrint('Попытка регистрации для пользователя: ${_usernameController.text}');
        success = await authService.register(
          _usernameController.text,
          _passwordController.text,
        );
      }

      if (success && mounted) {
        debugPrint('Успешная авторизация, переход на главный экран');
          Navigator.pushReplacementNamed(context, '/main');
      } else if (mounted) {
        setState(() {
          _errorMessage = _isLogin
              ? 'Неверное имя пользователя или пароль'
              : 'Пользователь с таким именем уже существует';
        });
      }
    } catch (e) {
      debugPrint('Ошибка при авторизации: $e');
        if (mounted) {
        setState(() {
          _errorMessage = 'Произошла ошибка. Попробуйте позже.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Вход' : 'Регистрация',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя пользователя',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите имя пользователя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите пароль';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                      : Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _usernameController.clear();
                            _passwordController.clear();
                            _errorMessage = null;
                          });
                        },
                  child: Text(_isLogin
                      ? 'Создать новый аккаунт'
                      : 'Уже есть аккаунт? Войти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 