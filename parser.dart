import 'dart:io';
import 'towerdefense.dart';
import 'lexer.dart';

void run(List<Token> tokens, GameManager game) {
  TokenGetter getter = TokenGetter(tokens);
  List<Statement> statements = [];
  while(getter.peek is! EofToken) {
    statements.add(parseStatement(getter));
  }
  for (Statement statement in statements) {
    statement.run(game);
  }
}

//Statements

Statement parseStatement(TokenGetter tokens) {
  if(tokens.peek is! KeywordToken) {
    print("[line ${tokens.peek.line} column ${tokens.peek.column}] ${tokens.peek} is not a keyword.");
    exit(1);
    return TickStatement();
  }
  KeywordToken token = tokens.advance;
  switch(token.name) {
    case "tick":
      return TickStatement();
    case "tower":
      return TowerStatement.parse(tokens);
    case "view":
      return ViewStatement.parse(tokens);
    case "print":
      return PrintStatement.parse(tokens);
    default:
      print("$token is not a valid start-of-statement keyword");
      exit(1);
  }
}

abstract class Statement {
  void run(GameManager game); 
}

class TickStatement extends Statement {
  void run(GameManager game) {
    game.tick();
  }
}

class TowerStatement extends Statement {
  TowerStatement(this.a, this.b);

  final Expression a;
  final Expression b;

  factory TowerStatement.parse(TokenGetter tokens) {
    Expression a = parseLiteral(tokens);
    Expression b = parseLiteral(tokens);
    return TowerStatement(a, b);
  }

  void run(GameManager game) {
    game.tower(a.eval(), b.eval());
  }
}

class ViewStatement extends Statement {
  ViewStatement(this.a, this.b);

  final Expression a;
  final Expression b;

  factory ViewStatement.parse(TokenGetter tokens) {
    Expression a = parseLiteral(tokens);
    Expression b = parseLiteral(tokens);
    return ViewStatement(a, b);
  }

  void run(GameManager game) {
    game.view(a.eval(), b.eval());
  }
}

class PrintStatement extends Statement {
  PrintStatement(this.expr);
  Expression expr;
  factory PrintStatement.parse(TokenGetter tokens) {
    Expression expr = parseLiteral(tokens);
    return PrintStatement(expr);
  }
  void run() {
    print(expr.eval());
  }
}
// Expressions

Expression parseLiteral(TokenGetter tokens) {
  switch(tokens.peek.runtimeType) {
    case IntegerToken:
      int value = (tokens.advance as IntegerToken).value;
      return IntegerExpression(value);
    case KeywordToken:
      KeywordToken token = tokens.advance;
      if(token.name != "money") {
        print("$token is not recognized as a start-of-expression token.");
      }
      return MoneyExpression();
    default: 
      print('${tokens.peek} is not recognized as a start-of-expression token.');
      exit(1);
      return IntegerExpression(null);
  }
}

abstract class Expression {
  dynamic eval(GameManager game);
}

class IntegerExpression extends Expression {
  IntegerExpression(this.value);
  final int value;
  int eval(GameManager game) => value;
}

class MoneyExpression extends Expression {
  int eval(GameManager game) => game.money; 
}

// t0ken getter

class TokenGetter {
  TokenGetter(this._tokens);
  int index = 0;
  final List<Token> _tokens;
  Token get peek => _tokens[index];
  Token get advance => _tokens[index++];
}