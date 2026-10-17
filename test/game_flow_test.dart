import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle15/app_scope.dart';
import 'package:puzzle15/logic/puzzle_board.dart';
import 'package:puzzle15/models/difficulty.dart';
import 'package:puzzle15/screens/game_screen.dart';
import 'package:puzzle15/services/scores_repository.dart';
import 'package:puzzle15/services/settings_controller.dart';

Future<ScoresRepository> pumpGame(
  WidgetTester tester,
  PuzzleBoard board, {
  Size screen = const Size(390, 844),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'animations': false});
  final prefs = await SharedPreferences.getInstance();
  final scores = ScoresRepository(prefs);
  await tester.pumpWidget(
    AppScope(
      settings: SettingsController(prefs),
      scores: scores,
      child: MaterialApp(
        home: GameScreen(difficulty: Difficulty.easy, initialBoard: board),
      ),
    ),
  );
  return scores;
}

void main() {
  testWidgets('resolver el tablero muestra la victoria y guarda el record', (
    tester,
  ) async {
    final scores = await pumpGame(
      tester,
      PuzzleBoard.fromList(3, [1, 2, 3, 4, 5, 6, 7, 0, 8]),
    );
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('8'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('¡Ganaste!'), findsOneWidget);
    expect(find.text('¡Nuevo récord!'), findsOneWidget);
    expect(scores.entriesFor(Difficulty.easy).length, 1);
    expect(scores.entriesFor(Difficulty.easy).first.moves, 1);
  });

  testWidgets('tocar una pieza que no puede moverse no cuenta', (tester) async {
    await pumpGame(
      tester,
      PuzzleBoard.fromList(3, [1, 2, 3, 4, 5, 6, 7, 0, 8]),
    );

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('¡Ganaste!'), findsNothing);
  });

  testWidgets('rendirse termina la partida como perdida', (tester) async {
    final scores = await pumpGame(
      tester,
      PuzzleBoard.fromList(3, [1, 2, 3, 4, 0, 5, 7, 8, 6]),
    );
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rendirse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rendirme'));
    await tester.pumpAndSettle();

    expect(find.text('Perdiste'), findsOneWidget);
    expect(scores.isEmpty, isTrue);
  });

}
