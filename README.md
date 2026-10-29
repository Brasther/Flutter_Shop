<div align="center">
  <img src="assets/icon/logofluter.png" alt="Flutter Shop" width="112" />
  <h1>Flutter Shop</h1>
  <p>Una tienda multiplataforma hecha con Flutter, Firebase y Stripe.</p>
  <p>
    <a href="https://github.com/Brasther/Flutter_Shop/actions/workflows/ci.yml"><img src="https://github.com/Brasther/Flutter_Shop/actions/workflows/ci.yml/badge.svg" alt="Flutter Shop CI" /></a>
    <img src="https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white" alt="Flutter 3.27 o superior" />
    <img src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white" alt="Dart 3" />
    <img src="https://img.shields.io/badge/Node.js-22-339933?logo=node.js&logoColor=white" alt="Node.js 22" />
    <a href="LICENSE"><img src="https://img.shields.io/badge/licencia-MIT-green.svg" alt="Licencia MIT" /></a>
  </p>
</div>

Flutter Shop es una aplicación de comercio electrónico de ejemplo pensada para mostrar una experiencia de compra completa y una arquitectura conectada a Firebase. Incluye catálogo, búsqueda, favoritos, carrito, checkout con Stripe y herramientas de administración.

> **Modo demo:** puedes explorar el catálogo con **Explorar como invitado**. Si Firestore está vacío o no está disponible, se muestran productos de demostración. Los pagos, pedidos y herramientas administrativas necesitan que configures y despliegues el backend; la app no finge que un pago se completó.

## Contenido

- [Funciones](#funciones)
- [Tecnologías y arquitectura](#tecnologías-y-arquitectura)
- [Requisitos](#requisitos)
- [Ejecutar localmente](#ejecutar-localmente)
- [Configurar Firebase y administración](#configurar-firebase-y-administración)
- [Habilitar pagos con Stripe](#habilitar-pagos-con-stripe)
- [Correo de confirmación](#correo-de-confirmación)
- [Verificaciones y CI](#verificaciones-y-ci)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Antes de producción](#antes-de-producción)
- [Licencia](#licencia)

## Funciones

### Experiencia de compra

- Catálogo adaptable con búsqueda, sugerencias, categorías, filtros por precio y ordenamiento.
- Favoritos persistentes y opciones de producto como talla o color.
- Carrito persistente con cantidades, existencias compartidas y total actualizado.
- Direcciones guardadas y checkout con validación de datos.
- Historial y seguimiento del estado de los pedidos.
- Modo claro y oscuro, con preferencia guardada en el dispositivo.
- Transiciones Hero entre el catálogo y el detalle del producto, entrada animada de tarjetas, favoritos animados y confirmación visual al agregar al carrito.
- Las animaciones personalizadas respetan la opción del sistema para reducir movimiento.

### Backend y administración

- Firebase Authentication para registro, inicio de sesión y recuperación de contraseña.
- Cloud Firestore para productos, pedidos, direcciones y cupones.
- Cloud Functions revalidan precios e inventario, reservan existencias y verifican pagos antes de crear pedidos.
- Stripe Payment Sheet y webhook para confirmar pagos.
- Panel de administración para métricas, productos, cupones y flujo de pedidos.
- Reglas de Firestore limitan operaciones administrativas y evitan que el cliente cree pedidos pagados directamente.
- Correo de confirmación en cola mediante la extensión Trigger Email de Firebase.

## Tecnologías y arquitectura

| Capa | Tecnología |
| --- | --- |
| Aplicación | Flutter, Dart, Material 3 y Provider |
| Datos locales | Shared Preferences para carrito, favoritos y tema |
| Backend | Firebase Authentication, Cloud Firestore y Cloud Functions |
| Pagos | Stripe |
| Correo | Firebase Trigger Email Extension y SMTP |
| Automatización | GitHub Actions |

La app Flutter presenta la tienda y envía las operaciones sensibles a Cloud Functions. Firestore aplica reglas de acceso; Stripe procesa el pago y confirma su resultado mediante la función y el webhook.

## Requisitos

- Flutter **3.27 o superior**, con Dart 3.
- Chrome para ejecutar la versión web local.
- Node.js **22** y npm para las Cloud Functions.
- Firebase CLI para desplegar reglas, índices, funciones y Hosting.
- Una cuenta Firebase para autenticación y backend. El repositorio incluye `lib/firebase_options.dart` para el proyecto de demostración `flutter-shop-affed`; puedes sustituirlo por la configuración de tu propio proyecto.

## Ejecutar localmente

En PowerShell, desde la carpeta del proyecto:

<pre><code>flutter pub get
flutter run -d chrome</code></pre>

Activa el proveedor **Authentication → Email/Password** en Firebase Console. Puedes probar el catálogo con **Explorar como invitado**. La primera ejecución de `flutter pub get` puede tardar mientras descarga los paquetes.

Si PowerShell no reconoce el comando `flutter`, instala el SDK de Flutter, añade la carpeta `flutter\bin` al `PATH` de Windows y abre una terminal nueva. Comprueba la instalación con `flutter --version` y `flutter doctor`.

Para compilar y publicar la web en Firebase Hosting:

<pre><code>flutter build web
firebase deploy --only hosting</code></pre>

## Configurar Firebase y administración

Las reglas y los índices están en `firestore.rules` y `firestore.indexes.json`. Despliega ambos con:

<pre><code>firebase deploy --only firestore:rules,firestore:indexes</code></pre>

Para cargar el catálogo de ejemplo y dar permisos administrativos a un usuario, primero crea una cuenta de servicio desde Firebase Console y guárdala **fuera del repositorio**. Luego, en PowerShell:

<pre><code>cd functions
npm install
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\ruta\segura\service-account.json'
$env:GCLOUD_PROJECT = 'tu-project-id'
node scripts/seed-demo-catalog.js
node scripts/grant-admin.js 'UID_DEL_USUARIO'</code></pre>

El script crea el cupón `BIENVENIDO10` con 10 % de descuento. Tras asignar el rol, cierra y vuelve a iniciar sesión para que Firebase renueve el token. El panel aparece en **Mi perfil → Panel de administración**.

## Habilitar pagos con Stripe

Necesitas Stripe y Cloud Functions habilitadas en un proyecto Firebase con el plan correspondiente. Instala las dependencias y guarda las claves privadas como secretos de Firebase:

<pre><code>cd functions
npm install
cd ..
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase deploy --only functions,firestore:rules,firestore:indexes</code></pre>

En el Dashboard de Stripe, configura el webhook para la función `stripeWebhook` y el evento `payment_intent.succeeded`. Guarda el secreto `whsec_...` en Firebase y vuelve a desplegar las funciones. En la configuración inicial puede ser necesario desplegar primero con un secreto temporal, crear el endpoint y después guardar el secreto real.

En desarrollo, proporciona una clave pública de pruebas:

<pre><code>flutter run -d chrome --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_TU_CLAVE</code></pre>

El ejemplo usa USD. No calcula impuestos ni tarifas de envío; define esas reglas antes de procesar ventas reales.

## Correo de confirmación

Instala la extensión oficial [Trigger Email from Firestore](https://firebase.google.com/docs/extensions/official/firestore-send-email) para la colección `mail` y configura un proveedor SMTP. La extensión requiere el plan Firebase Blaze. Sin ella, el pedido se guarda después del pago, pero no se envía el correo.

## Verificaciones y CI

Ejecuta las comprobaciones desde la raíz del repositorio:

<pre><code>flutter analyze
flutter test
cd functions
npm run lint</code></pre>

GitHub Actions ejecuta análisis de Dart, pruebas, compilación web y revisión de sintaxis de Cloud Functions en cada push a `main` o `master` y en cada pull request.

## Estructura del proyecto

<pre><code>lib/
  src/
    models/       modelos de productos, carrito y pedidos
    providers/    estado de autenticación, carrito, pedidos, favoritos y tema
    services/     acceso a productos y pagos
    ui/           pantallas, widgets, tema y búsqueda
functions/       pagos, pedidos, inventario, cupones y scripts
firestore.rules  reglas de acceso a Firestore
docs/             documentación de arquitectura
test/             pruebas de Flutter</code></pre>

## Antes de producción

- Revisa las reglas y prueba accesos permitidos y denegados con Firebase Emulator Suite.
- Restringe las API keys de Firebase y no subas claves privadas, secretos Stripe ni cuentas de servicio.
- Configura dominios autorizados, privacidad, términos, impuestos, envíos y reembolsos.
- Reemplaza el catálogo demo por productos, imágenes y precios que tengas derecho a utilizar.
- Revisa la moneda, los límites de inventario y el flujo del webhook en tu propio entorno antes de aceptar pagos reales.

## Licencia

Este proyecto se distribuye bajo la licencia [MIT](LICENSE).
