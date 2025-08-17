import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Business Name Field
                    _buildBusinessNameField(),

                    const SizedBox(height: 16),

                    // Name Field
                    _buildNameField(),

                    const SizedBox(height: 16),

                    // Email Field
                    _buildEmailField(),

                    const SizedBox(height: 16),

                    // Password Field
                    _buildPasswordField(),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    _buildConfirmPasswordField(),

                    const SizedBox(height: 24),

                    // Register Button
                    _buildRegisterButton(authProvider),

                    const SizedBox(height: 16),

                    // Error Message
                    if (authProvider.errorMessage != null)
                      _buildErrorMessage(authProvider.errorMessage!),

                    const SizedBox(height: 24),

                    // Login Link
                    _buildLoginLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon/Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1e3a8a),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.store, size: 50, color: Colors.white),
        ),

        const SizedBox(height: 16),

        Text(
          'Malzemecim\'e Hoş Geldiniz',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF1e3a8a),
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'İşletmenizi kaydedin ve yönetmeye başlayın',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBusinessNameField() {
    return TextFormField(
      controller: _businessNameController,
      decoration: const InputDecoration(
        labelText: 'İşletme Adı',
        hintText: 'Örnek: Mehmet Nalbur',
        prefixIcon: Icon(Icons.business),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'İşletme adı gereklidir';
        }
        return null;
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Adınız Soyadınız',
        hintText: 'Örnek: Mehmet Karataşlar',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ad soyad gereklidir';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'ornek@email.com',
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email gereklidir';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Geçerli bir email adresi giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Şifre',
        hintText: 'En az 6 karakter',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Şifre gereklidir';
        }
        if (value.length < 6) {
          return 'Şifre en az 6 karakter olmalıdır';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Şifre Tekrar',
        hintText: 'Şifrenizi tekrar giriniz',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Şifre tekrarı gereklidir';
        }
        if (value != _passwordController.text) {
          return 'Şifreler eşleşmiyor';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton(AuthProvider authProvider) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleRegister,
        child: authProvider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Kayıt Ol',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı? ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Giriş Yap',
            style: TextStyle(
              color: Color(0xFF1e3a8a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
      );

      if (success) {
        // Kayıt başarılı, ana sayfaya yönlendir
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Kayıt başarılı! Hoş geldiniz.')),
              ),
            ),
          );
        }
      }
    }
  }
}
