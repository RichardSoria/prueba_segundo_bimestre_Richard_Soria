# 📍 Turismo El Búho - App Móvil Flutter

**Turismo El Búho** es una aplicación móvil construida en Flutter que promueve el turismo ciudadano en Ecuador, permitiendo registrar, visualizar y reseñar lugares turísticos a través de un sistema de microblog.

## 🚀 Tecnologías usadas

- Flutter (SDK de interfaz multiplataforma)
- Supabase (Autenticación, base de datos, almacenamiento)
- Firebase (Analytics y notificaciones futuras)
- Dart (lenguaje principal de desarrollo)

## 👥 Perfiles de Usuario

### Visitante
- Ver todos los lugares turísticos
- Leer reseñas de otros usuarios

### Publicador
- Crear nuevos lugares turísticos
- Subir hasta 5 imágenes por lugar
- Editar y eliminar sus publicaciones
- Responder reseñas

## 🧩 Funcionalidades

- **Autenticación con Supabase:** Registro, login, verificación por correo
- **Deep linking:** Redirección automática desde enlaces de verificación
- **CRUD completo** para sitios turísticos
- **Gestión de imágenes:** Subida a Supabase Storage y visualización modal
- **Sistema de reseñas:** Comentarios y respuestas por lugar
- **Interfaz adaptable:** Diseño con Material UI personalizado

## 📸 Capturas de pantalla

*(Aquí puedes añadir imágenes de la interfaz de la app)*

## 🔐 Seguridad y control

- Roles gestionados directamente desde Supabase (publicador / visitante)
- Acceso restringido a funcionalidades según el tipo de cuenta
- Validaciones de campos y carga segura de imágenes

## 📦 Cómo compilar el APK

```bash
flutter build apk --release
