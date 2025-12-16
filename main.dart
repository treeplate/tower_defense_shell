import 'lexer.dart';
import 'towerdefense.dart';
import 'parser.dart';
import 'dart:io';

void main() {
  print('tower_defense_shell');
  GameManager manager = GameManager(
    width: 10,
    height: 10,
    maxEnemies: 10,
    enemyHp: 5,
    initialMoney: 20,
  );
  Scope scope = run(tokenize(File('ai.td').readAsStringSync()).toList(), manager);
  while (true) {
    scope = run(tokenize(stdin.readLineSync()).toList(), manager, scope);
  }
}