# 15-Puzzle Flutter

Rompecabezas deslizante (15-Puzzle) hecho en Flutter para el micro-proyecto de la Universidad Metropolitana, período 2627-1.

**Jugar en línea:** https://vgallo1212.github.io/puzzle15-flutter/

La versión web es una PWA: se puede instalar desde el navegador ("Instalar app" o "Agregar a pantalla de inicio") y funciona sin conexión.

## Funcionalidades

- **Splash** con el logo animado y un botón para saltarlo.
- **Menú principal** con botones grandes que se encogen y cambian de color al presionarlos, y entradas animadas con `animate_do`.
- **Tres dificultades:** Fácil 3x3 (8 piezas), Medio 4x4 (15 piezas) y Difícil 5x5 (24 piezas). Si nunca se eligió una, se pregunta al tocar Jugar.
- **Mezcla siempre resoluble:** se baraja con Fisher-Yates y se valida la paridad de inversiones. Si la mezcla sale imposible, se intercambian dos piezas para corregirla.
- **Partida:** contador de movimientos, cronómetro que arranca con el primer movimiento, progreso de piezas en su sitio, pausa automática al cambiar de pestaña o minimizar, y aviso antes de salir a mitad de partida.
- **Controles:** tocar una pieza (si está en la misma fila o columna del hueco se arrastran todas las de en medio), deslizar el dedo sobre el tablero, o flechas / WASD en el teclado. Espacio pausa.
- **Victoria y derrota:** pantalla superpuesta con tiempo, movimientos, dificultad y aviso de "¡Nuevo récord!". Se pierde en el modo contrarreloj (si se acaba el tiempo) o al rendirse.
- **Marcadores** por dificultad: mejor tiempo, menos movimientos, fecha y las 10 mejores partidas. Se pueden borrar todos, con confirmación.
- **Configuración:** dificultad por defecto, modo contrarreloj, tema claro / oscuro / automático, estilo de las piezas (Clásico, Colorido, Retro, Minimalista o Imagen), animaciones y sonidos activos o inactivos.
- **Diseño responsive:** en móvil el tablero va en columna y en tablet horizontal o escritorio pasa a dos columnas (`LayoutBuilder` y `MediaQuery`).

Todo se guarda localmente con `shared_preferences`.

## Estructura

```
lib/
  main.dart                 carga las preferencias y arranca la app
  app.dart                  MaterialApp, temas y modo claro/oscuro
  app_scope.dart            InheritedWidget con ajustes y marcadores
  logic/
    puzzle_board.dart       reglas del juego: mezcla, paridad, movimientos, victoria
  models/                   Difficulty, TileStyle, ScoreEntry
  services/
    settings_controller.dart  preferencias (ChangeNotifier + shared_preferences)
    scores_repository.dart    marcadores por dificultad
  screens/                  splash, menú, juego, configuración, marcadores, instrucciones
  widgets/                  tablero, fichas, diálogos y botones reutilizables
  theme/  utils/
test/
  puzzle_board_test.dart    paridad, mezclas resolubles (incluye un BFS del 3x3) y movimientos
  game_flow_test.dart       partida completa: ganar, toque inválido y rendirse
web/
  sw.js                     service worker propio para el modo offline
tool/
  pwa/generate_sw.js        completa la lista de archivos del service worker
  pwa/check_pwa.js          comprueba que la app siga siendo una PWA
  make_icons.py             genera los íconos de la web
```

La lógica del juego (`lib/logic`) no importa nada de Flutter, por eso se puede probar sin interfaz. Las pantallas usan `setState` para su propio estado (tablero, cronómetro, selección) y escuchan los ajustes compartidos con `ListenableBuilder`.

## Cómo correrlo

```bash
flutter pub get
flutter run -d chrome        # o un emulador / dispositivo
flutter test
```

Compilar la versión web como en GitHub Pages:

```bash
flutter build web --release --no-web-resources-cdn --base-href /puzzle15-flutter/
node tool/pwa/generate_sw.js build/web
node tool/pwa/check_pwa.js build/web /puzzle15-flutter/
```

## Despliegue

El workflow `.github/workflows/deploy.yml` corre en cada push y pull request:

1. `flutter analyze` y `flutter test`.
2. Compila la web con CanvasKit incluido (sin depender del CDN, para que funcione offline).
3. Genera el service worker y verifica la PWA: manifest, íconos, registro del service worker y una prueba en Chrome headless que corta la red y recarga la página.
4. Si el push es a `main`, publica en GitHub Pages.

## Ramas

Se trabaja con gitflow: `main` tiene la versión publicada, `develop` integra, y cada funcionalidad sale de una rama `feature/*` que vuelve a `develop`. Las versiones pasan por `release/*` y los arreglos urgentes por `hotfix/*`.

## Autor

Vincenzo Gallo
