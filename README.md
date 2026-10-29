# Flutter Shop

[![Flutter Shop CI](https://github.com/Brasther/Flutter_Shop/actions/workflows/ci.yml/badge.svg)](https://github.com/Brasther/Flutter_Shop/actions/workflows/ci.yml) [![Licencia MIT](https://img.shields.io/badge/licencia-MIT-green.svg)](LICENSE)

Tienda de muestra desarrollada en Flutter y Firebase: catálogo con opciones, filtros, promociones, carrito persistente, administración de pedidos e integración con Stripe.

> El catálogo demo se puede explorar al iniciar sesión aunque Firestore esté vacío. Los cobros y la administración solo se activan después de desplegar las Cloud Functions, configurar Stripe y asignar el rol de administrador. No se procesan pagos simulados.

## Funcionalidades

- Registro, inicio de sesión y recuperación de contraseña con Firebase Authentication.
- Catálogo remoto de Firestore con catálogo de demostración como respaldo.
- Búsqueda con sugerencias, categorías, rango de precio, orden y favoritos persistentes.
- Opciones de producto (talla/color), existencias compartidas, carrito con cantidades y eliminación de productos.
- Cupones con porcentaje o monto fijo, mínimo de compra, vigencia y límite de usos reservados en servidor.
- Checkout con validación de dirección, direcciones guardadas y Payment Sheet de Stripe.
- Revalidación de precio e inventario en Cloud Functions, reserva temporal de existencias y creación idempotente de pedidos después del pago.
- Confirmación de pago por callable function y webhook de Stripe.
- Seguimiento del pedido y panel administrativo con métricas, catálogo, cupones y flujo de preparación, envío y entrega.
- Correo de confirmación en cola después del pago; requiere configurar Trigger Email y un proveedor SMTP.
- Reglas de Firestore que bloquean escrituras de pedidos desde clientes y restringen administración.

## Tecnologías

Flutter / Dart · Provider · Firebase Authentication · Cloud Firestore · Cloud Functions (Node.js) · Stripe · Shared Preferences.

## Ejecutar la app

Requisitos: Flutter 3.27 o superior y Chrome para desarrollo. Node.js 22 y Firebase CLI se necesitan para desplegar las funciones. El proyecto ya contiene la configuración FlutterFire para Firebase (`flutter-shop-affed`). Si usas tu propio proyecto, vuelve a generar `lib/firebase_options.dart` con FlutterFire CLI.

```powershell
flutter pub get
flutter run -d chrome
```

En Windows, Flutter puede pedir habilitar el **Modo de desarrollador** para crear enlaces simbólicos de plugins. Reinicia PowerShell tras instalar Flutter y habilita esa opción desde la configuración de Windows si `flutter pub get` muestra el aviso de symlinks. En Firebase Console, activa **Authentication → Email/Password**. La opción **Explorar como invitado** permite recorrer el catálogo demo sin crear cuenta; si `products` está vacío o Firestore aún no está disponible, la app muestra los productos demo.

## Configurar datos y administración

Las reglas están en `firestore.rules`. Despliega reglas e índices con:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

Para publicar la versión web en Firebase Hosting:

```powershell
flutter build web
firebase deploy --only hosting
```

Para cargar el catálogo demo con credenciales de administrador de Firebase:

```powershell
cd functions
npm install
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\ruta\segura\service-account.json'
$env:GCLOUD_PROJECT = 'tu-project-id'
node scripts/seed-demo-catalog.js
node scripts/grant-admin.js 'UID_DEL_USUARIO'
```

No subas el archivo de cuenta de servicio. Tras asignar el custom claim, cierra y vuelve a iniciar sesión para que Firebase renueve el token. En **Mi perfil → Panel de administración** se consultan métricas, pedidos, cupones y catálogo. El seed crea `BIENVENIDO10` con 10% de descuento; si ya existe, conserva sus usos.

## Habilitar pagos

Necesitas una cuenta Stripe y un proyecto Firebase con Cloud Functions habilitadas. Las claves privadas se guardan como secretos administrados por Firebase; nunca las incluyas en Dart ni en Git.

```powershell
cd functions
npm install
cd ..
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Configura el endpoint de Stripe para `stripeWebhook` y suscríbelo a `payment_intent.succeeded`; guarda el valor `whsec_...` como `STRIPE_WEBHOOK_SECRET` y vuelve a desplegar Functions. La primera configuración del webhook requiere desplegar primero un secreto temporal, crear el endpoint con la URL de la función y luego guardar el `whsec_...` real.

Ejecuta la web con la clave pública de pruebas:

```powershell
flutter run -d chrome --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_TU_CLAVE
```

El servidor calcula el total con los precios de Firestore, reserva existencias durante 30 minutos y crea el pedido tras verificar Stripe. El ejemplo usa USD y no calcula impuestos ni tarifas de envío; configura esas reglas comerciales antes de aceptar ventas reales.

## Correo y seguimiento

Instala la extensión oficial [Trigger Email from Firestore](https://firebase.google.com/docs/extensions/official/firestore-send-email) para la colección `mail` y configura credenciales SMTP. La extensión requiere el plan Firebase Blaze y un proveedor SMTP. Una compra pagada encola un correo de confirmación; la app muestra el estado actualizado por administración. Sin la extensión y SMTP, el pedido se guarda igual, pero no se envía correo.

## Reglas y límites antes de producción

- Revisa las reglas y prueba casos permitidos/denegados con Firebase Emulator Suite antes de publicarlas.
- Configura dominio autorizado, restricciones de API keys, política de privacidad, términos, impuestos, envíos y reembolsos.
- El panel de admin requiere asignar manualmente el claim con el script protegido; no hay registro público de administradores.
- Actualiza el catálogo demo, las imágenes y los precios por datos que tengas derecho a usar.

## Verificación

```powershell
flutter analyze
flutter test
cd functions
npm run lint
```

## Demo y calidad

Puedes explorar el catálogo con **Explorar como invitado**. Pagos, cupones, correo y paneles administrativos requieren backend configurado; el catálogo demo no simula compras. GitHub Actions analiza Dart, ejecuta pruebas, compila web y comprueba la sintaxis de Functions en cada push y pull request. Consulta [la arquitectura](docs/ARCHITECTURE.md).

## Licencia

MIT. Consulta [LICENSE](LICENSE).
