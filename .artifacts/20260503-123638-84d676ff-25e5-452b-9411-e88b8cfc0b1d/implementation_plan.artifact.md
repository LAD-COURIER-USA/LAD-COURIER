# Plan Maestro: Superación del Escollo de Merchant (V16.0)

Este plan detalla los pasos técnicos para eliminar el error `PERMISSION_DENIED` que impide al Driver vincular su banco en modo real, mientras que el Cliente funciona correctamente.

## User Review Required

- Confirmación de que el usuario ha puesto manualmente la función `setupDriverBank` en modo **Public** en la consola de Google Cloud.
- Confirmación de que la cuenta de Stripe sigue en modo **Live** con todos los pasos de la guía completados.

## Proposed Changes

### Cloud Functions (Servidor)

Asegurar que el servidor use la versión más estable y moderna de Node.js y que ignore las restricciones de App Check que bloquean las llamadas de APKs locales.

#### [index.js](file:///C:/src/lad_courier/LAD-COURIER/functions/index.js)
- Mantener `exports.setupDriverBank`.
- Asegurar la propiedad `enforceAppCheck: false` en la configuración de la función.
- Añadir logs de auditoría más detallados al inicio de la función para confirmar que Google Cloud deja pasar la llamada.

#### [package.json](file:///C:/src/lad_courier/LAD-COURIER/functions/package.json)
- Regresar a `node: "22"` como motor de ejecución para cumplir con los requisitos de Google.

---

### App Flutter (Cliente/Driver)

Sincronizar la App con la nueva configuración del servidor para garantizar una comunicación limpia.

#### [stripe_service.dart](file:///C:/src/lad_courier/LAD-COURIER/lib/services/stripe_service.dart)
- Verificar que la llamada apunte a `setupDriverBank`.
- Asegurar el paso de un objeto vacío `{}` en la llamada.

## Verification Plan

### Automated Tests
- `firebase deploy --only functions`: Debe mostrar éxito en la creación de `setupDriverBank` bajo Node 22.
- `flutter build apk --release`: Debe compilar sin advertencias de desincronización.

### Manual Verification
1.  **Google Cloud Web:** Entrar en la función `setupDriverBank` > Security y confirmar que dice "Allow unauthenticated invocations".
2.  **Google Cloud Web:** En Networking, confirmar que Ingress está en "Allow all traffic".
3.  **Samsung Phone:** Pulsar "Vincular Banco" y capturar el Logcat.
    - Si el error persiste, el Logcat nos dirá si es de Firebase Auth o de los secretos de Stripe.
