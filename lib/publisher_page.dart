import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TurismosPage extends StatefulWidget {
  const TurismosPage({super.key});

  @override
  State<TurismosPage> createState() => _TurismosPageState();
}

class _TurismosPageState extends State<TurismosPage> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  final List<Uint8List> fotosBytes = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final uuid = const Uuid();

  Future<void> _pickImages(StateSetter setModalState) async {
    final picker = ImagePicker();

    final origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    if (origen == ImageSource.camera) {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (fotosBytes.length < 6) {
          setModalState(() {
            fotosBytes.add(bytes);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Máximo 6 imágenes permitidas.'),
              backgroundColor: Color(0xFF16243e), // Azul institucional
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (origen == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if ((pickedFiles.length + fotosBytes.length) <= 6) {
        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          setModalState(() {
            fotosBytes.add(bytes);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puedes subir entre 1 y 6 imágenes.'),
            backgroundColor: Color(0xFF16243e), // Azul institucional
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<String>> _subirImagenesASupabase() async {
    final storage = Supabase.instance.client.storage.from('imagenes');
    final List<String> urls = [];

    for (var i = 0; i < fotosBytes.length; i++) {
      final String fileName = 'img_${uuid.v4()}.jpg';

      final String path = await storage.uploadBinary(
        fileName,
        fotosBytes[i],
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      if (path.isNotEmpty) {
        final publicUrl = storage.getPublicUrl(fileName);
        urls.add(publicUrl);
      } else {
        throw Exception(
          'Error al subir imagen: No se pudo obtener la ruta del archivo subido.',
        );
      }
    }

    return urls;
  }

  Future<void> _guardarTarea(BuildContext context) async {
    final campos = [tituloController.text, descripcionController.text];

    final camposVacios = campos.any((campo) => campo.trim().isEmpty);

    if (camposVacios) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Campos incompletos',
            style: TextStyle(
              color: Color(0xFF16243e), // Azul institucional
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Por favor completa todos los campos obligatorios.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF8AD25), // Amarillo de atención
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    if (fotosBytes.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Faltan imágenes',
            style: TextStyle(
              color: Color(0xFF16243e),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Debes agregar al menos una fotografía.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF8AD25),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    if (camposVacios) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Campos incompletos',
            style: TextStyle(
              color: Color(0xFF16243e), // Azul institucional
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Por favor completa todos los campos obligatorios.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF8AD25), // Amarillo institucional
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    if (fotosBytes.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Faltan imágenes',
            style: TextStyle(
              color: Color(0xFF16243e), // Azul institucional
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Debes agregar al menos una fotografía.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF8AD25), // Amarillo de atención
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmado = await _confirmarGuardarTarea();
    if (!confirmado) return;

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
      final urls = await _subirImagenesASupabase();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('usuarios')
          .select('name, lastName')
          .eq('id', user.id)
          .single();

      final String autorNombre = '${data['name']} ${data['lastName']}';

      await FirebaseFirestore.instance.collection('tareas').add({
        'autor': autorNombre,
        'userID': user.id,
        'titulo': tituloController.text,
        'descripcion': descripcionController.text,
        'fotografias': urls,
        'estado': 'Pendiente',
        'fecha': Timestamp.now(),
      });

      Navigator.pop(context); // Cierra el spinner
      Navigator.pop(context); // Cierra el modal

      // Limpiar campos y fotos
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea turístico guardado exitosamente.'),
          backgroundColor: Color(0xFF16243e), // Azul institucional
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cierra el spinner
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Ocurrió un error al guardar: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  void _clearForm() {
    tituloController.clear();
    descripcionController.clear();
    fotosBytes.clear();
  }

  void _mostrarModalImagen(String url, String lugarId, bool esAutor) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),

              !esAutor
                  ? Text("")
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmarEliminarImagen(lugarId, url);
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE72F2B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _actualizarImagen(lugarId, url);
                          },
                          icon: const Icon(
                            Icons.image_search,
                            color: Colors.white,
                          ),
                          label: const Text('Actualizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16243e),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmarGuardarTarea() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '¿Estás seguro?',
              style: TextStyle(
                color: Color(0xFF16243e), // Azul institucional
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: const Text(
              '¿Deseas guardar este lugar turístico?',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF8AD25), // Amarillo de atención
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _confirmarEliminarTarea(String id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Estás seguro de eliminar la tarea?',
          style: TextStyle(
            color: Color(0xFFE72F2B), // Rojo de alerta
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFE72F2B), // Rojo de alerta
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar tarea'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await FirebaseFirestore.instance.collection('tareas').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea eliminado exitosamente.'),
          backgroundColor: Color(0xFF16243e), // Azul institucional
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmarCompletarTarea(String id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Estás seguro de completar la tarea?',
          style: TextStyle(
            color: Color(0xFF1abc9c), // Rojo de alerta
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF1abc9c), // Rojo de alerta
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, completar tarea'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await FirebaseFirestore.instance.collection('tareas').doc(id).update({
        'estado': 'Completada',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea completada exitosamente.'),
          backgroundColor: Color(0xFF16243e), // Azul institucional
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmarEliminarImagen(String lugarId, String url) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Imagen',
          style: TextStyle(
            color: Color(0xFFE72F2B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          '¿Deseas eliminar esta imagen?',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFE72F2B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
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
        final doc = FirebaseFirestore.instance
            .collection('tareas')
            .doc(lugarId);
        await doc.update({
          'fotografias': FieldValue.arrayRemove([url]),
        });

        Navigator.pop(context); // Cierra el spinner
        return true;
      } catch (e) {
        Navigator.pop(context); // Cierra el spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la imagen: $e')),
        );
      }
    }

    return false;
  }

  Future<void> _agregarMasImagenes(String lugarId, int cantidadActual) async {
    final ImageSource? origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    final int cantidadDisponible = 6 - cantidadActual;
    final storage = Supabase.instance.client.storage.from('imagenes');
    final nuevasUrls = <String>[];

    try {
      if (origen == ImageSource.camera) {
        final pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 100,
        );

        if (pickedFile != null) {
          if (cantidadDisponible < 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ya tienes 6 imágenes.'),
                backgroundColor: Color(0xFF16243e), // Azul institucional
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
              ),
            ),
          );

          final bytes = await pickedFile.readAsBytes();
          final fileName = 'img_${uuid.v4()}.jpg';
          final path = await storage.uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

          if (path.isNotEmpty) {
            final url = storage.getPublicUrl(fileName);
            nuevasUrls.add(url);
          }

          Navigator.pop(context);
        }
      } else if (origen == ImageSource.gallery) {
        final pickedFiles = await picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 100,
        );

        if (pickedFiles.isEmpty) return;

        if (pickedFiles.length > cantidadDisponible) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Solo puedes agregar $cantidadDisponible imágenes.',
              ),
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8AD25)),
            ),
          ),
        );

        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          final fileName = 'img_${uuid.v4()}.jpg';

          final path = await storage.uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

          if (path.isNotEmpty) {
            final url = storage.getPublicUrl(fileName);
            nuevasUrls.add(url);
          }
        }

        Navigator.pop(context);
      }

      if (nuevasUrls.isNotEmpty) {
        final doc = FirebaseFirestore.instance
            .collection('tareas')
            .doc(lugarId);
        await doc.update({'fotografias': FieldValue.arrayUnion(nuevasUrls)});
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imágenes: $e')));
    }
  }

  Future<void> _actualizarImagen(String lugarId, String urlAntiguo) async {
    final origen = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Seleccionar de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (origen == null) return;

    final pickedFile = await picker.pickImage(source: origen);
    if (pickedFile == null) return;

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
      final nuevoBytes = await pickedFile.readAsBytes();
      final storage = Supabase.instance.client.storage.from('imagenes');
      final nuevoNombre = 'img_${uuid.v4()}.jpg';

      final nuevoPath = await storage.uploadBinary(
        nuevoNombre,
        nuevoBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      if (nuevoPath.isNotEmpty) {
        final nuevaUrl = storage.getPublicUrl(nuevoNombre);
        final doc = FirebaseFirestore.instance
            .collection('tareas')
            .doc(lugarId);

        // Reemplaza la imagen antigua por la nueva
        await doc.update({
          'fotografias': FieldValue.arrayRemove([urlAntiguo]),
        });

        await doc.update({
          'fotografias': FieldValue.arrayUnion([nuevaUrl]),
        });
      }

      Navigator.pop(context); // Cierra el spinner
      // No cierres el modal de imagen aquí, déjalo al botón si es necesario
    } catch (e) {
      Navigator.pop(context); // Cierra el spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la imagen: $e')),
      );
    }
  }

  void _editarTarea(String id, Map<String, dynamic> data) {
    final tituloCtrl = TextEditingController(text: data['titulo']);
    final descripcionCtrl = TextEditingController(text: data['descripcion']);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar Tarea',
          style: TextStyle(
            color: Color(0xFF16243e),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 500, // <-- Aquí defines el ancho deseado
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _styledField(tituloCtrl, 'Nombre del Tarea'),
                  const SizedBox(height: 10),
                  _styledField(
                    descripcionCtrl,
                    'Descripción de la tarea',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFFE72F2B), // Rojo de alerta
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.edit,
            ), // Ícono más representativo para editar
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16243e), // Azul institucional
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final campos = [tituloCtrl.text, descripcionCtrl.text];

              final camposVacios = campos.any((campo) => campo.trim().isEmpty);

              if (camposVacios) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Campos incompletos',
                      style: TextStyle(
                        color: Color(0xFFE72F2B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      'Por favor completa todos los campos.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(
                            color: Color(0xFF16243e),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return;
              }

              final confirmado = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    '¿Confirmar actualización?',
                    style: TextStyle(
                      color: Color(0xFF16243e), // Azul institucional
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  content: const Text(
                    '¿Estás seguro de actualizar este lugar turístico?',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFFE72F2B), // Rojo de alerta
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sí, actualizar',
                        style: TextStyle(
                          color: Color(0xFF16243e), // Azul institucional
                          fontWeight: FontWeight.w600,
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
                builder: (_) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFF8AD25),
                    ),
                  ),
                ),
              );

              try {
                await FirebaseFirestore.instance
                    .collection('tareas')
                    .doc(id)
                    .update({
                      'titulo': tituloCtrl.text,
                      'descripcion': descripcionCtrl.text,
                    });

                Navigator.pop(context); // spinner
                Navigator.pop(context); // modal

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tarea actualizado exitosamente.'),
                    backgroundColor: Color(0xFF16243e), // Azul institucional
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _styledField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
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

  Widget _infoText(String label, String value, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16, // más grande
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black87, // azul institucional
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 30,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _styledField(tituloController, 'Título de la tarea'),
                    const SizedBox(height: 12),
                    _styledField(
                      descripcionController,
                      'Descripción de la tarea',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _pickImages(setModalState),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Seleccionar Fotografías'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8AD25),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: fotosBytes.map((bytes) {
                        return Image.memory(
                          bytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _guardarTarea(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Tarea'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16243e),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _clearForm(); // Limpia aunque el modal se cierre por fuera (por ejemplo deslizando)
    });
  }

  Future<void> _generarPDF(
    String titulo,
    String descripcion,
    String autor,
    String fehca,
    String estado,
    List<String> fotos,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final List<pw.ImageProvider> loadedImages = await Future.wait(
      fotos.map((url) => networkImage(url)),
    );

    final now = DateTime.now();
    final fechaGeneracion = '${now.day}/${now.month}/${now.year}';
    final fechaPublicacion = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.parse(fehca));

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(margin: const pw.EdgeInsets.all(32)),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Reporte de Tarea',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 22,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),

          pw.Text(
            'Fecha de generación: $fechaGeneracion',
            style: pw.TextStyle(
              fontSize: 10,
              font: font,
              color: PdfColors.grey600,
            ),
          ),

          pw.SizedBox(height: 16),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey700),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Título:', titulo, font, boldFont),
                _infoRow('Descripción:', descripcion, font, boldFont),
                _infoRow('Autor:', autor, font, boldFont),
                _infoRow(
                  'Fecha de publicación:',
                  fechaPublicacion,
                  font,
                  boldFont,
                ),
                _infoRow('Estado:', estado.toUpperCase(), font, boldFont),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          if (loadedImages.isNotEmpty) ...[
            pw.Text(
              'Fotografías',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 18,
                color: PdfColors.deepOrange800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: loadedImages
                  .map(
                    (img) => pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey600),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(
                        img,
                        width: 162,
                        height: 162,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _infoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 12)),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFf39c12), // Amarillo fuerte
                  Color(0xFFe74c3c), // Rojo vibrante
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar transparente y coherente
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    'To-Do: Organiza tu Día',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Cerrar sesión',
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tareas')
                          .orderBy('fecha', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF8AD25),
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return const Text(
                            'Aún no hay tareas registradas.',
                            style: TextStyle(color: Colors.white),
                          );
                        }

                        final user = Supabase.instance.client.auth.currentUser;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final docId = docs[index].id;

                            final titulo = data['titulo'] ?? '';
                            final descripcion = data['descripcion'] ?? '';
                            final autor = data['autor'] ?? 'Desconocido';
                            final estado = data['estado'] ?? 'Pendiente';
                            final userID = data['userID'];
                            final fecha =
                                data['fecha']?.toDate() ?? DateTime.now();
                            final fotos = List<String>.from(
                              data['fotografias'] ?? [],
                            );

                            final esCreador = userID == user?.id;

                            return Card(
                              color: Colors.white,
                              elevation: 6,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titulo,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFe74c3c),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      descripcion,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    _infoText("Publicado por: ", autor),
                                    _infoText(
                                      "Fecha de publicación",
                                      "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}",
                                    ),
                                    _infoText("Estado", estado),

                                    const SizedBox(height: 8),

                                    // Imágenes
                                    if (fotos.isNotEmpty)
                                      SizedBox(
                                        height: (fotos.length / 3).ceil() * 110,
                                        child: GridView.count(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: fotos.map((url) {
                                            return GestureDetector(
                                              onTap: () => _mostrarModalImagen(
                                                url,
                                                docId,
                                                esCreador,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  url,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.broken_image,
                                                            color: Colors.red,
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),

                                    const SizedBox(height: 12),

                                    if (esCreador && fotos.length < 6)
                                      TextButton.icon(
                                        onPressed: () => _agregarMasImagenes(
                                          docId,
                                          fotos.length,
                                        ),
                                        icon: const Icon(Icons.add_a_photo),
                                        label: const Text('Agregar imagen'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF16243e,
                                          ),
                                        ),
                                      ),

                                    if (esCreador) const Divider(height: 24),

                                    // Botones
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (esCreador && estado != 'Completada')
                                          IconButton(
                                            onPressed: () =>
                                                _editarTarea(docId, data),
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Editar',
                                            color: Colors.white,
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                    Color(0xFF16243e),
                                                  ),
                                            ),
                                          ),
                                        if (esCreador && estado != 'Completada')
                                          IconButton(
                                            onPressed: () =>
                                                _confirmarEliminarTarea(docId),
                                            icon: const Icon(Icons.delete),
                                            tooltip: 'Eliminar',
                                            color: Colors.white,
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                    Color(0xFFe74c3c),
                                                  ),
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: () => _generarPDF(
                                            titulo,
                                            descripcion,
                                            autor,
                                            fecha.toIso8601String(),
                                            estado,
                                            fotos,
                                          ),
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                          ),
                                          tooltip: 'Exportar a PDF',
                                          color: Colors.white,
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                  Color(0xFFF8AD25),
                                                ),
                                          ),
                                        ),
                                        if (estado == 'Pendiente')
                                          IconButton(
                                            onPressed: () =>
                                                _confirmarCompletarTarea(docId),
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                            ),
                                            tooltip: 'Completar tarea',
                                            color: Colors.white,
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                    Color(0xFF1abc9c),
                                                  ),
                                            ),
                                          ),
                                      ],
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
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1abc9c),
        foregroundColor: Colors.white,
        tooltip: 'Añadir una tarea',
        onPressed: () => _mostrarFormularioModal(context),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
    );
  }
}
