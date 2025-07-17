import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_supabase_flutter/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublisherProfilePage extends StatefulWidget {
  const PublisherProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _PublisherProfilePageState();
}

class _PublisherProfilePageState extends State<PublisherProfilePage> {
  late TextEditingController emailController;
  late TextEditingController nombreController;
  late TextEditingController apellidoController;
  late TextEditingController rolController;

  bool _datosCargados = false;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    nombreController = TextEditingController();
    apellidoController = TextEditingController();
    rolController = TextEditingController();

    _getProfileData();
  }

  final supabase = Supabase.instance.client;

  void _getProfileData() async {
    try {
      final userId = supabase.auth.currentSession?.user.id;

      if (userId == null) return;

      final List<dynamic> response = await supabase
          .from("users")
          .select('*')
          .eq('id', userId)
          .limit(1);

      if (response.isNotEmpty) {
        final user = response.first;

        setState(() {
          emailController.text = user['email'] ?? '';
          nombreController.text = user['name'] ?? '';
          apellidoController.text = user['lastName'] ?? '';
          rolController.text = user['role'] ?? '';
          _datosCargados = true;
        });
      }
    } catch (e) {
      throw ("Error al obtener los datos del perfil");
    }
  }

  String capitalizarPrimeraLetra(String valor) {
    if (valor.isEmpty) return "";
    var dato = valor[0].toUpperCase() + valor.substring(1).toLowerCase();
    return dato.trim();
  }

  Future<void> updateUsersData() async {
    try {
      final nombre = capitalizarPrimeraLetra(nombreController.text);
      final apellido = capitalizarPrimeraLetra(apellidoController.text);

      if (nombre == "" || apellido == "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Debe enviar su apellido y nombre"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final response = await supabase
          .from("users")
          .update({'name': nombre, 'lastName': apellido})
          .eq('id', '${supabase.auth.currentUser?.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sus datos se actualizaron exitosamente"),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al actualizar sus datos ${e}"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: 
          Text("Su sesión no existe"))
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      await supabase
      .from('users')
      .update({'deleted': true})
      .eq('id', userId);


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cuenta eliminada exitosamente"),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar su cuenta ${e}"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    nombreController.dispose();
    apellidoController.dispose();
    rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_datosCargados) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 22, 36, 62),
        foregroundColor: Colors.white,
        title: const Text("Perfil de publicador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    buildField(
                      "Correo electrónico",
                      emailController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    buildField("Rol", rolController, readOnly: true),
                    const SizedBox(height: 16),
                    buildField("Nombre", nombreController),
                    const SizedBox(height: 16),
                    buildField("Apellido", apellidoController),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateUsersData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8AD25),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Actualizar datos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 5),

            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFFF3F4F8),
                    title: const Text(
                      "Eliminar cuenta",
                      textAlign: TextAlign.center,
                    ),
                    content: const Text(
                      "¿Está seguro que desea eliminar su cuenta? Este cambio es irreversible.",
                      textAlign: TextAlign.justify,
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          deleteUserAccount();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE72F2B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Eliminar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancelar"),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE72F2B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Eliminar cuenta"),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para campos reutilizables
  Widget buildField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          inputFormatters:
              label.contains("Nombre") || label.contains("Apellido")
              ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))]
              : null,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Color(0xFF98B7DF), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
