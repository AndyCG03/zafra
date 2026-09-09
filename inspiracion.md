# QRfri

<p align="center">
  <img src="assets/horizontal.png" alt="QRfri" height="96">
</p>

<p align="center">Generador, personalizador y lector de códigos QR privado, local y offline-first.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38.6-3730E0?logo=flutter&logoColor=white" alt="Flutter 3.38.6">
  <img src="https://img.shields.io/badge/Android-ready-0FAE6B?logo=android&logoColor=white" alt="Android ready">
  <img src="https://img.shields.io/badge/Offline--first-0F172A" alt="Offline first">
</p>

## Qué es QRfri

QRfri permite crear códigos QR para contenidos cotidianos, personalizar su diseño y guardarlos en una biblioteca privada dentro del dispositivo. No necesita cuenta ni servidor para crear, consultar o editar códigos.

La identidad visual combina índigo (`#3730E0`), verde esmeralda (`#0FAE6B`) y superficies claras u oscuras de alto contraste.

## Galería de la aplicación

Las cinco capturas se muestran consecutivamente para que el repositorio refleje el flujo principal de la aplicación.

### 1. Inicio y accesos rápidos

<p align="center">
  <img src="imagenes/image1.webp" alt="Inicio de QRfri" width="320">
</p>

### 2. Creación del código

<p align="center">
  <img src="imagenes/image2.webp" alt="Editor de QR" width="320">
</p>

### 3. Personalización del diseño

<p align="center">
  <img src="imagenes/image3.webp" alt="Diseño del QR" width="320">
</p>

### 4. Biblioteca Mis QR

<p align="center">
  <img src="imagenes/image4.webp" alt="Biblioteca de códigos" width="320">
</p>

### 5. Escaneo y resultado

<p align="center">
  <img src="imagenes/image5.webp" alt="Escáner de QR" width="320">
</p>

## Funcionalidades principales

- Crear QR para enlaces, texto, Wi-Fi, contactos, WhatsApp, email, teléfono, SMS, ubicaciones, eventos, redes sociales, negocios, criptomonedas y tiendas de aplicaciones.
- Ver una previsualización inmediata durante la edición.
- Elegir colores independientes para módulos, ojos y fondo.
- Usar módulos cuadrados o circulares y ojos cuadrados o circulares.
- Aplicar degradados lineales o radiales, zona tranquila, corrección de errores y transparencia.
- Añadir un logo central con tamaño, máscara, fondo y borde configurables.
- Buscar, filtrar, ordenar, marcar favoritos y alternar entre lista y cuadrícula en `Mis QR`.
- Escanear con cámara o importar una imagen, detectando el tipo de contenido automáticamente.
- Editar los datos detectados antes de guardarlos, con nombre personalizado y payload normalizado.
- Copiar el contenido, guardarlo, abrir su destino o compartir contactos y eventos como archivos compatibles.
- Exportar QR a PNG, JPG o PDF con diferentes niveles de calidad.
- Crear y restaurar copias de seguridad JSON locales.
- Usar tema claro, tema oscuro, diez idiomas y un widget Android compacto.

## Tipos de contenido

| Tipo | Uso |
| --- | --- |
| Enlace | URLs HTTP y HTTPS |
| Contacto | vCard y MECARD |
| Wi-Fi | SSID, contraseña y seguridad |
| WhatsApp | Conversaciones mediante `wa.me` |
| Email | Destinatario, asunto y mensaje |
| Teléfono / SMS | Número y mensaje opcional |
| Ubicación | Coordenadas geográficas |
| Evento | Datos de calendario |
| Redes sociales | Perfiles y enlaces |
| Negocio | Nombre, dirección y web |
| Criptomoneda | Esquema y cantidad opcional |
| Texto | Cualquier contenido plano |

El editor valida y normaliza cada payload. Al editar un QR existente interpreta el contenido original y rellena los campos correspondientes sin duplicar información al guardar.

## Lectura e importación

El resultado del escaneo o de una imagen importada aparece en una previsualización amplia con tipo detectado, nombre editable, texto completo y acciones contextuales. Los enlaces, WhatsApp, email, teléfono, SMS, ubicaciones y criptomonedas pueden abrirse mediante la aplicación del sistema. Las imágenes importadas se procesan para conservar únicamente el código QR y evitar fondos negros en áreas transparentes.

## Privacidad

- La biblioteca se guarda localmente con `SharedPreferences`.
- Las copias de seguridad son archivos JSON controlados por el usuario.
- El permiso de cámara solo se solicita al usar el escáner.
- QRfri no envía logos, códigos ni contenidos a un backend propio.
- Las copias se validan antes de reemplazar la biblioteca existente.

## Estructura del proyecto

```text
lib/
  main.dart                         Arranque mínimo y exportación compatible
  app/app.dart                       Configuración raíz, tema y launch gate
  core/qr/qr_payload.dart            Detección, validación y acciones QR
  core/storage/local_store.dart      Persistencia, modelos y copias JSON
  features/home/                     Inicio y navegación principal
  features/qr_creation/              Editor y personalización QR
  features/qr_library/               Biblioteca, tarjetas y exportación
  features/qr_scanner/               Cámara, importación y lectura
  features/settings/                 Ajustes, idiomas y accesos rápidos
  features/tutorial/                 Tutorial de primera ejecución
  design_system.dart                  Paleta, tema, toasts y diálogos
  localization.dart                   Catálogo y delegado de idiomas
android/                              Actividad, widget y recursos Android
assets/                               Logos, ilustraciones y animaciones
imagenes/                             Capturas usadas en esta documentación
test/                                 Pruebas de widgets
```

La aplicación conserva el estado actual con `ChangeNotifier` y `SharedPreferences`. Las funciones relacionadas se agrupan mediante archivos `part` para mantener compatibilidad con los modelos, claves de almacenamiento y clases privadas existentes durante la migración arquitectónica.

## Idiomas

QRfri incluye español, inglés, portugués, francés, chino simplificado, alemán, japonés, coreano, italiano y ruso. Las claves están centralizadas en `QrFriLocalizations`, de modo que añadir otro idioma no requiere cambiar la lógica de las pantallas.

## Requisitos

- Flutter estable `3.38.6`.
- Dart compatible con `^3.10.7` (incluido en Flutter `3.38.6`).
- `flutter_lints` `6.0.0`, compatible con Dart `3.10.7`.
- Android Studio y SDK de Android para Android.
- Xcode para iOS o macOS.
- Visual Studio con herramientas de escritorio para Windows.

## Uso local

1. Clona el repositorio.
2. Abre el proyecto en Android Studio, VS Code o IntelliJ.
3. Instala las dependencias usando el `pubspec.lock` incluido.
4. Selecciona un dispositivo o emulador y ejecuta QRfri desde tu entorno Flutter.

El `pubspec.lock` se conserva para reproducir las mismas versiones de dependencias entre equipos y CI.

## Compilación y releases

El workflow [`.github/workflows/android-release.yml`](.github/workflows/android-release.yml) usa Flutter `3.38.6`, Java 17 y `flutter pub get --enforce-lockfile`. Genera APK por arquitectura y App Bundle, sube los artefactos y crea una GitHub Release al publicar un tag `v*`.

```bash
git add .
git commit -m "Refactor architecture and restore tutorial"
git push origin main
git tag v1.0.1
git push origin v1.0.1
```

El tag debe apuntar al commit que ya está publicado en `main`. El tag `v1.0.0` ya fue utilizado; para cambios posteriores se recomienda incrementar la versión (`v1.0.1`, `v1.0.2`, etc.).

La configuración Android actual usa firma debug para facilitar las compilaciones iniciales. Antes de publicar en Google Play, configura una firma release mediante secretos de GitHub y `key.properties`, excluido por `.gitignore`.

## Calidad y contribución

Las operaciones asíncronas muestran confirmaciones solo después de completarse y utilizan mensajes de error cuando fallan. Mantén los componentes de `design_system.dart`, la paleta QRfri, el contraste claro/oscuro y las traducciones al realizar cambios.

No subas credenciales, archivos `.env` reales, backups con datos personales ni artefactos de compilación. Consulta `.gitignore` antes de crear un commit.

## Licencia

Este proyecto todavía no define una licencia de distribución. Añade una licencia antes de publicar QRfri fuera de tu equipo.
