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
      final ususarioRegistrado = await supabase.from("users")
      .select("deleted")
      .eq("email", emailController.text)
      .maybeSingle();

      if (ususarioRegistrado?['deleted'] == true)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: 
          Text("Esta cuenta no se puede volver a registrar"))
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
        await supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'role': selectedRole,
          'name': nameController.text,
          'lastName': lastNameController.text,
          'deleted': false
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Registrarse - El Búho', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 22, 36, 62),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Color.fromARGB(255, 225, 31, 28),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol de usuario',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: roles.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value[0].toUpperCase() + value.substring(1),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: signup,
                          icon: const Icon(Icons.app_registration),
                          label: const Text('Registrarse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 225, 31, 28),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                  const SizedBox(height: 12),

                  const Text(
                    '¿Ya tienes una cuenta?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text('Iniciar sesión', style: TextStyle(color: Color.fromARGB(255, 225, 31, 28)),),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
