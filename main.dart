import 'lexer.dart';
import 'towerdefense.dart';
import 'parser.dart';
import 'dart:io';

void main() {
  GameManager manager = GameManager(3, 3);
  while(true) {
    run(tokenize(stdin.readLineSync()).toList() + [EofToken()], manager);
  }
}