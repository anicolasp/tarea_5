# Directorio — Tarea 5

App Flutter de directorio sobre la API pública [JSONPlaceholder](https://jsonplaceholder.typicode.com). Tarea 5 de *Programación de dispositivos móviles* (UTESA).

- Lista de usuarios con nombre, correo y empresa (`/users`).
- Detalle de cada usuario con sus publicaciones (`/posts?userId={id}`).
- Favoritos guardados en SQLite, visibles sin conexión.
- Estados de carga, error y sin conexión; la app no se cierra por errores.
- Recarga automática al volver a la app si la carga había fallado.

Arquitectura MVVM por capas: ver [ARQUITECTURA.md](ARQUITECTURA.md). Capturas: [docs/capturas](docs/capturas/README.md).

## Requisitos

- Flutter 3.47 (Dart 3.13)
- Emulador o dispositivo Android con acceso a Internet

## Ejecutar

```bash
flutter pub get
flutter run
```

## Pruebas

```bash
flutter analyze
flutter test
```

## Estructura

```
lib/
  main.dart                  arranque: ApiClient, FavoritesDb, UserRepository
  data/
    models/                  User y Post (fromJson / toJson)
    remote/api_client.dart   cliente http de JSONPlaceholder
    local/favorites_db.dart  favoritos en SQLite (sqflite)
    user_repository.dart     única fuente de datos
  ui/
    app.dart                 MaterialApp y navegación inferior
    ui_state.dart            estados de la UI
    retry_on_resume.dart     ciclo de vida → recarga
    users/ detail/ favorites/  pantallas y ViewModels
    widgets/                 vistas de estado y fila de usuario
test/                        pruebas unitarias y de widgets
docs/                        diagrama y capturas
```
