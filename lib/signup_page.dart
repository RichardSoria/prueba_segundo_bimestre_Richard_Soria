import 'package:flutter/material.dart';
import 'package:mi_supabase_flutter/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  String? selectedRole;
  final supabase = Supabase.instance.client;
  final List<String> roles = ['visitante', 'publicador'];
  bool _obscurePassword = true;
  bool _cargando = false;

  void _showSnackBar(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool validarCampos() {
    final campos = {
      'Correo': emailController.text.trim(),
      'Contraseña': passwordController.text.trim(),
      'Rol': selectedRole,
      'Nombre': nameController.text.trim(),
      'Apellido': lastNameController.text.trim(),
    };

    for (final entry in campos.entries) {
      if (entry.value == null || (entry.value?.isEmpty ?? true)) {
        _showSnackBar('Todos los campos son obligatorios.', error: true);
        return false;
      }
    }
    return true;
  }

  Future<void> signup() async {
    if (!validarCampos()) return;

    setState(() => _cargando = true);

    try {
      final ususarioRegistrado = await supabase
          .from("usuarios")
          .select("deleted")
          .eq("email", emailController.text)
          .maybeSingle();

      if (ususarioRegistrado?['deleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Esta cuenta no se puede volver a registrar"),
          ),
        );

        setState(() {
          _cargando = false;
        });

        emailController.clear();
        passwordController.clear();
        //selectedRole
        nameController.clear();
        lastNameController.clear();

        return;
      }

      final response = await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
        emailRedirectTo: 'elbuhoturismo://auth/callback',
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('usuarios').insert({
          'id': user.id,
          'email': user.email,
          'role': selectedRole,
          'name': nameController.text,
          'lastName': lastNameController.text,
          'deleted': false,
        });

        _showSnackBar('Revisa tu correo para confirmar tu cuenta.');

        // Limpiar campos
        emailController.clear();
        passwordController.clear();
        nameController.clear();
        lastNameController.clear();
        setState(() => selectedRole = null);

        // Redirigir al login
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('Error al registrarse: $e', error: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  // Método para decorar los inputs de forma consistente
  InputDecoration inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: Color(0xFF1abc9c)),
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1abc9c)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1abc9c), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo degradado turístico (igual que login)
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF39C12), // Amarillo
                  Color(0xFFE74C3C), // Rojo
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ícono decorativo de registro
                      const Icon(
                        Icons.person_add,
                        size: 80,
                        color: Color(0xFFE11F1C),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Correo
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Color(0xFF1abc9c),
                        decoration: inputDecoration(
                          'Correo electrónico',
                          Icons.email,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Contraseña
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        cursorColor: Color(0xFF1abc9c),
                        decoration: inputDecoration(
                          'Contraseña',
                          Icons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Nombre
                      TextField(
                        controller: nameController,
                        cursorColor: Color(0xFF1abc9c),
                        decoration: inputDecoration('Nombre', Icons.person),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Apellido
                      TextField(
                        controller: lastNameController,
                        cursorColor: Color(0xFF1abc9c),
                        decoration: inputDecoration(
                          'Apellido',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón con spinner verde si está cargando
                      _cargando
                          ? const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2ecc71),
                                  ),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: signup,
                              icon: const Icon(Icons.app_registration),
                              label: const Text('Registrarse'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1abc9c),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),

                      const Text(
                        '¿Ya tienes una cuenta?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Enlace para ir a login
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(color: Color(0xFFE11F1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
