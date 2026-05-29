# Catálogo Interactivo

App Flutter para almacenar y organizar URLs de videos, páginas web, fotos y archivos en categorías y subcategorías.

## Características

- **Tipos de ítems**: Video, Página web, Foto, Archivo
- **Organización**: Categorías con ícono + subcategorías anidadas
- **Navegación**: Sidebar con árbol de categorías (responsive: drawer en móvil, panel fijo en desktop)
- **Vista**: Lista con swipe-to-action en móvil, grid de cards en desktop
- **Búsqueda**: Por título, descripción, tags y URL
- **Favoritos**: Marcado de ítems favoritos
- **Miniaturas**: Detección automática de thumbnails de YouTube
- **Export/Import**: JSON para backup y transferencia entre dispositivos

## Plataformas

- Android (minSdk 21)
- Windows desktop
- Linux desktop

## Setup

```bash
# Instalar Flutter >= 3.0
# https://docs.flutter.dev/get-started/install

flutter pub get
flutter run                    # Android (con dispositivo conectado)
flutter run -d windows         # Windows desktop
flutter run -d linux           # Linux desktop
```

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| `sqflite` + `sqflite_common_ffi` | SQLite en Android y desktop |
| `provider` | State management |
| `url_launcher` | Abrir URLs en el navegador/app nativa |
| `file_picker` | Seleccionar archivo JSON para importar |
| `share_plus` | Compartir/exportar el archivo JSON |
| `uuid` | Generación de IDs únicos |
| `flutter_slidable` | Swipe actions en lista móvil |
