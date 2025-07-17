import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResenasPage extends StatefulWidget {
  final String lugarId;
  final String rolUsuario; // 'publicador' o 'visitante'

  const ResenasPage({
    super.key,
    required this.lugarId,
    required this.rolUsuario,
  });

  @override
  State<ResenasPage> createState() => _ResenasPageState();
}

Future<bool?> mostrarDialogoPersonalizado({
  required BuildContext context,
  required String titulo,
  required Widget contenido,
  required String textoConfirmar,
  required String textoCancelar,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF4EDF9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 20),
            contenido,
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Color(0xFF7E57C2)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    textoConfirmar,
                    style: const TextStyle(color: Color(0xFF7E57C2)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResenasPageState extends State<ResenasPage> {
  final TextEditingController resenaCtrl = TextEditingController();

  Future<String> obtenerAutor() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Desconocido';
    final data = await Supabase.instance.client
        .from('users')
        .select('name, lastName')
        .eq('id', user.id)
        .single();
    return '${data['name']} ${data['lastName']}';
  }

  Future<void> publicarResena() async {
    final texto = resenaCtrl.text.trim();
    if (texto.isEmpty) return;
    final autor = await obtenerAutor();
    final user = Supabase.instance.client.auth.currentUser;

    await FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('resenas')
        .add({
          'contenido': texto,
          'autor': autor,
          'fecha': Timestamp.now(),
          'userID': user?.id,
        });

    resenaCtrl.clear();
  }

  Future<void> actualizarResena(String resenaId, String contenidoActual) async {
    final TextEditingController updateCtrl = TextEditingController(
      text: contenidoActual,
    );

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Editar reseña',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF16243e),
          ),
        ),
        content: TextField(
          controller: updateCtrl,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Escribe tu reseña...',
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFE72F2B)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF16243e),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || updateCtrl.text.trim().isEmpty) return;

    // Mostrar spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('turismo')
          .doc(widget.lugarId)
          .collection('resenas')
          .doc(resenaId)
          .update({'contenido': updateCtrl.text.trim()});

      Navigator.pop(context); // Cierra spinner

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña actualizada con éxito')),
      );
    } catch (e) {
      Navigator.pop(context); // Cierra spinner

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar reseña: $e')));
    }
  }

  Future<void> eliminarResena(String resenaId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5EFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar reseña',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF16243e),
          ),
        ),
        content: const Text('¿Estás seguro de eliminar esta reseña?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFE72F2B)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE72F2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // Mostrar spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('turismo')
          .doc(widget.lugarId)
          .collection('resenas')
          .doc(resenaId)
          .delete();

      Navigator.pop(context); // Cierra spinner

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña eliminada exitosamente')),
      );
    } catch (e) {
      Navigator.pop(context); // Cierra spinner

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar reseña: $e')));
    }
  }

  Future<void> responderResena(String resenaId) async {
    final TextEditingController respuestaCtrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5EFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Responder reseña',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF16243e),
          ),
        ),
        content: TextField(
          controller: respuestaCtrl,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Escribe tu respuesta...',
            border: UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFE72F2B)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.reply, size: 16),
            label: const Text('Responder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF16243e),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || respuestaCtrl.text.trim().isEmpty) return;
    final autor = await obtenerAutor();

    await FirebaseFirestore.instance
        .collection('turismo')
        .doc(widget.lugarId)
        .collection('resenas')
        .doc(resenaId)
        .collection('respuestas')
        .add({
          'contenido': respuestaCtrl.text.trim(),
          'autor': autor,
          'fecha': Timestamp.now(),
          'userID':
              Supabase.instance.client.auth.currentUser?.id, // ¡Agrega esto!
        });
  }

  Future<void> _editarRespuesta(DocumentSnapshot respuesta) async {
    final data = respuesta.data() as Map<String, dynamic>;
    final lugarId = widget.lugarId;
    final resenaId = respuesta.reference.parent.parent!.id;
    final respuestaId = respuesta.id;

    final TextEditingController ctrl = TextEditingController(
      text: data['contenido'],
    );

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar respuesta'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Edita tu respuesta',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.save),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16243e), // Azul institucional
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || ctrl.text.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance
          .collection('turismo')
          .doc(lugarId)
          .collection('resenas')
          .doc(resenaId)
          .collection('respuestas')
          .doc(respuestaId)
          .update({'contenido': ctrl.text.trim()});

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Respuesta actualizada')));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar respuesta: $e')),
      );
    }
  }

  Future<void> _eliminarRespuesta(DocumentSnapshot respuesta) async {
    final lugarId = widget.lugarId;
    final resenaId = respuesta.reference.parent.parent!.id;
    final respuestaId = respuesta.id;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar respuesta'),
        content: const Text('¿Estás seguro de eliminar esta respuesta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE72F2B), // Rojo alerta
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance
          .collection('turismo')
          .doc(lugarId)
          .collection('resenas')
          .doc(resenaId)
          .collection('respuestas')
          .doc(respuestaId)
          .delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Respuesta eliminada')));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar respuesta: $e')),
      );
    }
  }

  Widget _buildRespuesta(DocumentSnapshot respuesta) {
    final data = respuesta.data() as Map<String, dynamic>;
    final user = Supabase.instance.client.auth.currentUser;
    final esAutor = data['userID'] == user?.id;

    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final fechaFormateada = fecha != null
        ? "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}"
        : '';

    return Container(
      margin: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['autor'] ?? 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (fechaFormateada.isNotEmpty)
                Text(
                  fechaFormateada,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data['contenido'] ?? '',
            style: const TextStyle(color: Colors.black87),
          ),
          if (esAutor)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFF16243e),
                  ),
                  tooltip: 'Editar respuesta',
                  onPressed: () => _editarRespuesta(respuesta),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 18,
                    color: Color(0xFFE72F2B),
                  ),
                  tooltip: 'Eliminar respuesta',
                  onPressed: () => _eliminarRespuesta(respuesta),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResena(DocumentSnapshot resena) {
    final data = resena.data() as Map<String, dynamic>;
    final resenaId = resena.id;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final userIDAutor = data['userID'];
    final esAutor = currentUserId == userIDAutor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: autor + fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['autor'] ?? 'Desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  (data['fecha'] as Timestamp).toDate().toString().substring(
                    0,
                    16,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contenido de la reseña
            Text(data['contenido'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),

            // Acciones (Responder - Editar - Eliminar)
            Row(
              children: [
                if (widget.rolUsuario == 'publicador')
                  TextButton.icon(
                    onPressed: () => responderResena(resenaId),
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Responder'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF16243e), // azul institucional
                    ),
                  ),
                const Spacer(),
                if (esAutor)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    iconSize: 20,
                    color: Color(0xFF16243e), // azul institucional
                    tooltip: 'Editar',
                    onPressed: () =>
                        actualizarResena(resenaId, data['contenido'] ?? ''),
                  ),
                if (esAutor)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 20,
                    color: Color(0xFFE72F2B), // rojo institucional
                    tooltip: 'Eliminar',
                    onPressed: () => eliminarResena(resenaId),
                  ),
              ],
            ),

            // Respuestas anidadas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('turismo')
                  .doc(widget.lugarId)
                  .collection('resenas')
                  .doc(resenaId)
                  .collection('respuestas')
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // alineación a la izquierda
                    children: snapshot.data!.docs.map(_buildRespuesta).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseñas del lugar'),
        backgroundColor: const Color(
          0xFF16243e,
        ), // Azul institucional corregido
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFFCF5FF), // Fondo general suave
        child: Column(
          children: [
            if (widget.rolUsuario == 'publicador')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: resenaCtrl,
                          decoration: InputDecoration(
                            labelText: 'Escribe una reseña',
                            labelStyle: const TextStyle(
                              color: Color(0xFF16243e),
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF16243e),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF16243e),
                                width: 2,
                              ),
                            ),
                          ),
                          maxLines: null,
                          cursorColor: Color(0xFF16243e),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: publicarResena,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Publicar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16243e),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('turismo')
                    .doc(widget.lugarId)
                    .collection('resenas')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final resenas = snapshot.data!.docs;

                  if (resenas.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay reseñas.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: resenas.map(_buildResena).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
