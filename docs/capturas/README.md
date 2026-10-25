# Capturas de la verificación E2E

Capturas tomadas con Marionette en un emulador Android (Pixel 8, API 35), con la API real de JSONPlaceholder y los datos de la app borrados antes de empezar. El modo avión se activó y desactivó con `adb shell cmd connectivity airplane-mode enable|disable`.

| Captura | Paso | Qué muestra | Requisito |
|---|---|---|---|
| [01-lista.png](01-lista.png) | 1 | Lista de usuarios con nombre, correo y empresa (`company.name`) | 1 |
| [02-detalle.png](02-detalle.png) | 2 | Detalle de un usuario con sus publicaciones (`/posts?userId=1`) | 2 |
| [03-favoritos.png](03-favoritos.png) | 3 | Dos usuarios marcados como favoritos, el más reciente primero | 3 |
| [04-sin-conexion.png](04-sin-conexion.png) | 4 | App reiniciada en modo avión: mensaje "Sin conexión a Internet" con "Reintentar", sin cierre | 4 |
| [05-favoritos-offline.png](05-favoritos-offline.png) | 5 | Favoritos visibles en modo avión (leídos de SQLite) | 3 |
| [06-detalle-offline.png](06-detalle-offline.png) | 6 | Detalle en modo avión: datos del usuario visibles, publicaciones con el aviso de sin conexión | 2, 4 |
| [07-recarga-automatica.png](07-recarga-automatica.png) | 7 | Tras recuperar la red y volver a la app, las publicaciones se recargan solas (`resumed`) | 4, 6 |
| [08-oscuro.png](08-oscuro.png) | 8 | Lista en tema oscuro, con las estrellas de los favoritos | 1, 3 |

El paso 4 es un reinicio real: la app se cerró con `am force-stop` y se abrió de nuevo con `am start`.
