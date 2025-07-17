import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'resenas_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LugaresVisitantePage extends StatelessWidget {
  const LugaresVisitantePage({super.key});

  void _mostrarModalImagenSoloLectura(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _verResenas(BuildContext context, String lugarId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResenasPage(lugarId: lugarId, rolUsuario: 'visitante'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 22, 36, 62),
        foregroundColor: Colors.white,
        title: const Text('Lugares Turísticos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('turismo')
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text('Aún no hay lugares turísticos registrados.'),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final docId = docs[index].id;

                final nombre = data['nombre'] ?? '';
                final descripcion = data['descripcion'] ?? '';
                final ciudad = data['ciudad'] ?? '';
                final provincia = data['provincia'] ?? '';
                final autor = data['autor'] ?? 'Desconocido';
                final latitud = data['latitud']?.toString() ?? '-';
                final longitud = data['longitud']?.toString() ?? '-';
                final fotos = List<String>.from(data['fotografias'] ?? []);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(descripcion, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(
                                text: 'Provincia: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: provincia),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(
                                text: 'Ciudad: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ciudad),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(
                                text: 'Coordenadas: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '$latitud°, $longitud°'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Publicado por: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: autor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (fotos.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: fotos.map((url) {
                              return GestureDetector(
                                onTap: () => _mostrarModalImagenSoloLectura(
                                  context,
                                  url,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const Divider(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.reviews),
                            tooltip: 'Ver reseñas',
                            onPressed: () => _verResenas(context, docId),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
