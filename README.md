# 📱 Aplicación de Lista de Tareas - Flutter

Esta es una aplicación móvil desarrollada con **Flutter**, diseñada como proyecto para el segundo bimestre. Permite la gestión de tareas (o publicaciones) personales con autenticación, carga de imágenes y exportación de reportes en PDF.

---

## ✨ Funcionalidades Principales

### 🔐 Autenticación de usuarios
- Inicio de sesión y registro mediante **correo electrónico y contraseña** usando Supabase.
- Verificación de usuarios e inicio de sesión seguro.

### ✅ Gestión de tareas (publicaciones)
- Visualización de **todas las publicaciones** y **publicaciones propias**.
- Cada tarea incluye:
  - Título y descripción.
  - Estado: pendiente o completada.
  - Hasta **6 imágenes** (galería o cámara).
  - Fecha de publicación con `Timestamp.now()` o `DatePicker`.

### 🖼️ Gestión de imágenes
- Puedes **subir imágenes** desde la galería o tomar fotos con la cámara.
- Máximo de 6 imágenes por tarea.
- Visualización de cada imagen con opciones para **actualizar o eliminar**.

### 🔄 Edición de tareas
- El usuario puede **modificar sus propias tareas**: título, descripción, imágenes, estado.

### 📥 Exportación a PDF
- Una vez que una tarea se marca como completada, se habilita el botón para **descargar un reporte en PDF** con toda la información de la tarea y sus imágenes.

---

## 🎨 Interfaz

- Pantalla de **inicio de sesión** estilizada con fondo tropical degradado.
- Pantalla de **registro** coherente visualmente.
- Pantalla de **publicaciones generales** y otra de **mis tareas personales**.
- Todos los botones están acompañados de **íconos y tooltips**.
---

## 📷 Evidencias
<img width="361" height="781" alt="image" src="https://github.com/user-attachments/assets/f8a45d59-9b31-4955-95f2-ebe5aa725d9e" />
<img width="362" height="782" alt="image" src="https://github.com/user-attachments/assets/75fe1fc1-d295-45b0-bb48-a45f9ba2aa87" />
<img width="360" height="781" alt="image" src="https://github.com/user-attachments/assets/d9606838-3506-40ea-85a3-46483864cded" />
<img width="358" height="781" alt="image" src="https://github.com/user-attachments/assets/c740368d-b1f3-4602-a290-de1513e618de" />
<img width="361" height="784" alt="image" src="https://github.com/user-attachments/assets/40ec520c-c2ec-4d37-8c54-f1404ea671c7" />
<img width="360" height="782" alt="image" src="https://github.com/user-attachments/assets/8a3da27b-d04d-4022-b35e-09b5ba2a068f" />
<img width="363" height="780" alt="image" src="https://github.com/user-attachments/assets/cba55c1a-699b-446e-b9f2-2899c943e6ed" />

