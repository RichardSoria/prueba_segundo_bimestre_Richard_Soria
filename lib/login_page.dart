import 'package:flutter/material.dart';
import 'package:mi_supabase_flutter/tabs/publicador_tabs.dart';
import 'package:mi_supabase_flutter/tabs/visitante_tabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _obscurePassword = true;
  bool _cargando = false;

  void _showSnackBar(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Verifica que los campos no estén vacíos
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Correo y contraseña obligatorios.', error: true);
      return;
    }

    setState(() => _cargando = true); // Muestra el spinner de carga

    try {
      // Consulta si el usuario está marcado como eliminado
      final estadoUsuario = await supabase
          .from("users")
          .select('deleted')
          .eq('email', email)
          .maybeSingle(); // Evita error si no hay resultados

      // Si no existe el correo en la base
      if (estadoUsuario == null) {
        _showSnackBar('Correo o contraseña inválidos.', error: true);
        setState(() => _cargando = false);
        return;
      }

      // Si está eliminado, no permitir acceso
      if (estadoUsuario['deleted'] == true) {
        _showSnackBar('No existe ese usuario.', error: true);
        setState(() => _cargando = false);
        emailController.clear();
        passwordController.clear();
        return;
      }

      // Autenticación con Supabase
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Consulta el rol del usuario autenticado
        final data = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle(); // También puede no existir

        if (data == null || data['role'] == null) {
          _showSnackBar('No se encontró el rol del usuario.', error: true);
          setState(() => _cargando = false);
          return;
        }

        final String role = data['role'];

        if (!mounted) return;

        // Redirección según el rol obtenido
        if (role == 'publicador') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PublicadorTabs()),
            (route) => false,
          );
        } else if (role == 'visitante') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const VisitanteTabs()),
            (route) => false,
          );
        } else {
          _showSnackBar('Rol desconocido: $role', error: true);
          setState(() => _cargando = false);
        }
      } else {
        _showSnackBar('Correo o contraseña inválidos.', error: true);
        setState(() => _cargando = false);
      }
    } catch (e) {
      _showSnackBar('Correo o contraseña inválidos.', error: true);
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado tropical
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFf39c12), // Amarillo
                  Color(0xFFe74c3c), // Rojo
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
                      const Icon(
                        Icons.landscape,
                        size: 80,
                        color: Color(0xFFe74c3c),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Explora tu aventura',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        cursorColor: const Color(
                          0xFF1abc9c,
                        ), // Cambia el color del cursor
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF1abc9c), // Label flotante turquesa
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1abc9c),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1abc9c),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText:
                            _obscurePassword, // Oculta el texto por seguridad
                        cursorColor: const Color(0xFF1abc9c), // Cursor turquesa

                        decoration: InputDecoration(
                          labelText: 'Contraseña',

                          // Estilo del label flotante al hacer focus o escribir
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF1abc9c), // Color turquesa
                          ),

                          filled: true,
                          fillColor: Colors
                              .grey
                              .shade100, // Fondo gris claro del input
                          // Ícono de candado al inicio
                          prefixIcon: const Icon(Icons.lock),

                          // Ícono al final para mostrar/ocultar contraseña
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey, // Puedes cambiarlo si deseas
                            ),
                            onPressed: () {
                              // Cambia la visibilidad del texto
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),

                          // Bordes generales del input
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),

                          // Borde visible cuando el campo está inactivo
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1abc9c),
                            ),
                          ),

                          // Borde visible al hacer focus
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1abc9c),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      _cargando
                          ? ElevatedButton(
                              onPressed:
                                  null, // Desactiva el botón mientras carga
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF1abc9c,
                                ), // Fondo turquesa
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2ecc71), // Spinner verde
                                  ),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: login,
                              icon: const Icon(Icons.flight_takeoff),
                              label: const Text('Iniciar aventura'),
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
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpPage(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿No tienes cuenta? ¡Regístrate ahora!',
                          style: TextStyle(
                            color: Color(0xFFe74c3c),
                            fontWeight: FontWeight.bold,
                          ),
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
