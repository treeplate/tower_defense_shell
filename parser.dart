import 'dart:io';
import 'towerdefense.dart';
import 'lexer.dart';

const bool debug = true;

Scope run(List<Token> tokens, GameManager game, [Scope scope]) {
  TokenGetter getter = TokenGetter(tokens);
  List<Statement> statements = [];
  while (getter.peek is! EofToken) {
    statements.add(parseStatement(getter));
  }
  scope = scope ?? Scope();
  for (Statement statement in statements) {
    statement.run(game, scope);
  }
  return scope;
}

//Statements

Statement parseStatement(TokenGetter tokens) {
  if(tokens.peek is! KeywordToken) {
    return ExprStatement.parse(tokens);
  }
  KeywordToken token = tokens.peek;
  switch(token.name) {
    case "tick":
      tokens.advance;
      return TickStatement();
    case "debug":
      tokens.advance;
      if (!debug) {
        print("Debug not allowed in non-debug mode");
        exit(3);
      }
      return DebugStatement();
    case "while":
      tokens.advance;
      return WhileStatement.parse(tokens);
    case "if":
      tokens.advance;
      return IfStatement.parse(tokens);
    case "tower":
      tokens.advance;
      return TowerStatement.parse(tokens);
    case "print":
      tokens.advance;
      return PrintStatement.parse(tokens);
    case "var":
      tokens.advance;
      return DeclareStatement.parse(tokens);
    default:
      return ExprStatement.parse(tokens);
  }
}

abstract class Statement {
  void run(GameManager game, Scope scope); 
}

class TickStatement extends Statement {
  void run(GameManager game, Scope scope) {
    game.tick();
  }
}

class DebugStatement extends Statement {
  void run(GameManager game, Scope scope) {
    game.debug();
  }
}

class TowerStatement extends Statement {
  TowerStatement(this.a, this.b);

  final Expression a;
  final Expression b;

  factory TowerStatement.parse(TokenGetter tokens) {
    Expression a = parseExpression(tokens);
    Expression b = parseExpression(tokens);
    return TowerStatement(a, b);
  }

  void run(GameManager game, Scope scope) {
    game.tower(a.eval(game, scope), b.eval(game, scope));
  }
}

class ExprStatement extends Statement {
  ExprStatement(this.a);

  final Expression a;

  factory ExprStatement.parse(TokenGetter tokens) {
    Expression a = parseExpression(tokens);
    return ExprStatement(a);
  }

  void run(GameManager game, Scope scope) {
    a.eval(game, scope);
  }
}

class DeclareStatement extends Statement {
  DeclareStatement(this.a, this.b);

  final String a;
  final Expression b;

  factory DeclareStatement.parse(TokenGetter tokens) {
    if(tokens.peek is! KeywordToken) {
      print("No identifier after 'var'; ${tokens.peek} instead.");
      exit(1);
    }
    KeywordToken token = tokens.advance;
    String a = token.name;
    if(tokens.peek is! SymbolToken || (tokens.peek as SymbolToken).symbol != "=") {
      print("No = in declaration; ${tokens.peek} instead.");
      exit(1);
    }
    tokens.advance;
    Expression b = parseExpression(tokens);
    return DeclareStatement(a, b);
  }

  void run(GameManager game, Scope scope) {
    scope.declare(a, b.eval(game, scope));
  }
}

class PrintStatement extends Statement {
  PrintStatement(this.expr);
  Expression expr;
  factory PrintStatement.parse(TokenGetter tokens) {
    Expression expr = parseExpression(tokens);
    return PrintStatement(expr);
  }
  void run(GameManager game, Scope scope) {
    print(expr.eval(game, scope));
  }
}

class Block {
  Block(this.statements);
  
  Scope getNewScope() => Scope(parent);
  List<Statement> statements;
  Scope parent;

  void run(GameManager game) {
    Scope blockScope = getNewScope();
    for (Statement statement in statements) {
      statement.run(game, blockScope);
    }
  }
}

class WhileStatement extends Statement {
  WhileStatement(this.expr, this.block);
  final Expression expr;
  final Block block;
  factory WhileStatement.parse(TokenGetter tokens) {
    Expression expr = parseExpression(tokens);
    if(tokens.peek is! SymbolToken) {
      print("Unexpected ${tokens.peek}, expected {");
      exit(1);
    }
    SymbolToken symbol = tokens.advance;
    if(symbol.symbol != "{") {
      print("Unexpected ${tokens.peek}, expected {");
      exit(1);
    }
    List<Statement> statements = [];
    while(tokens.peek is! SymbolToken || (tokens.peek as SymbolToken).symbol != "}") {
      statements.add(parseStatement(tokens));
    }
    tokens.advance;
    Block block = Block(statements);
    return WhileStatement(expr, block);
  }
  void run(GameManager game, Scope scope) {
    block.parent = scope;
    while(expr.eval(game, scope)) {
      block.run(game);
    }
  }
}

class IfStatement extends Statement {
  IfStatement(this.expr, this.block);
  final Expression expr;
  final Block block;
  factory IfStatement.parse(TokenGetter tokens) {
    Expression expr = parseExpression(tokens);
    if(tokens.peek is! SymbolToken) {
      print("Unexpected ${tokens.peek}, expected {");
      exit(1);
    }
    SymbolToken symbol = tokens.advance;
    if(symbol.symbol != "{") {
      print("Unexpected ${tokens.peek}, expected {");
      exit(1);
    }
    List<Statement> statements = [];
    while(tokens.peek is! SymbolToken || (tokens.peek as SymbolToken).symbol != "}") {
      statements.add(parseStatement(tokens));
    }
    tokens.advance;
    Block block = Block(statements);
    return IfStatement(expr, block);
  }
  void run(GameManager game, Scope scope) {
    block.parent = scope;
    if(expr.eval(game, scope)) {
      block.run(game);
    }
  }
}
// Expressions
Expression parseExpression(TokenGetter tokens) => AssignmentExpression.parse(tokens);

Expression parseLiteral(TokenGetter tokens) {
  switch(tokens.peek.runtimeType) {
    case IntegerToken:
      int value = (tokens.advance as IntegerToken).value;
      return IntegerExpression(value);
    case KeywordToken:
      KeywordToken token = tokens.advance;
      switch(token.name) {
        case "money":
          return MoneyExpression();
        case "true":
          return TrueExpression();
        case "false":
          return FalseExpression();
        default:
          return IdentifierExpression(token.name);
      }
      throw "Unreachable";
    default: 
      print("${tokens.peek} is not recognized as a start-of-expression token.");
      exit(1);
  }
}

abstract class Expression {
  dynamic eval(GameManager game, Scope scope);
}

class AssignmentExpression extends Expression {
  AssignmentExpression(this.a, this.b);

  final String a;
  final Expression b;

  static Expression parse(TokenGetter tokens) {
    if(tokens.peek is! KeywordToken) return GreaterEqualExpression.parse(tokens);
    KeywordToken token = tokens.peek;
    String a = token.name;
    if(tokens.peekAhead is! SymbolToken || (tokens.peekAhead as SymbolToken).symbol != "=") {
      return GreaterEqualExpression.parse(tokens);
    }
    tokens.advance;
    tokens.advance;
    Expression b = GreaterEqualExpression.parse(tokens);
    return AssignmentExpression(a, b);
  }

  void eval(GameManager game, Scope scope) {
    scope.assign(a, b.eval(game, scope));
  }
}

class GreaterEqualExpression extends Expression {
  GreaterEqualExpression(this.a, this.b);

  final Expression a;
  final Expression b;

  static Expression parse(TokenGetter tokens) {
    Expression a = PlusExpression.parse(tokens);
    if(tokens.peek is! SymbolToken || (tokens.peek as SymbolToken).symbol != ">=") {
      return a;
    }
    tokens.advance;
    Expression b = PlusExpression.parse(tokens);
    return GreaterEqualExpression(a, b);
  }

  void eval(GameManager game, Scope scope) {
    return a.eval(game, scope) >= b.eval(game, scope);
  }
}

class PlusExpression extends Expression {
  PlusExpression(this.a, this.b);

  final Expression a;
  final Expression b;

  static Expression parse(TokenGetter tokens) {
    Expression a = ViewExpression.parse(tokens);
    if(tokens.peek is! SymbolToken || (tokens.peek as SymbolToken).symbol != "+") {
      return a;
    }
    tokens.advance;
    Expression b = ViewExpression.parse(tokens);
    return PlusExpression(a, b);
  }

  void eval(GameManager game, Scope scope) {
    return a.eval(game, scope) + b.eval(game, scope);
  }
}

class ViewExpression extends Expression {
  ViewExpression(this.x, this.y);
  final Expression x;
  final Expression y;

  static Expression parse(TokenGetter tokens) {
    if(tokens.peek is! KeywordToken) return parseLiteral(tokens);
    KeywordToken token = tokens.peek;
    if(token.name != "view") return parseLiteral(tokens);
    tokens.advance;
    Expression a = parseLiteral(tokens);
    Expression b = parseLiteral(tokens);
    return ViewExpression(a, b);
  }

  int eval(GameManager game, Scope scope) => game.at(x.eval(game, scope), y.eval(game, scope))?.type ?? 0;
}

class TrueExpression extends Expression {
  bool eval(GameManager game, Scope scope) => true;
}

class FalseExpression extends Expression {
  bool eval(GameManager game, Scope scope) => false;
}

class IntegerExpression extends Expression {
  IntegerExpression(this.value);
  final int value;
  int eval(GameManager game, Scope scope) => value;
}

class IdentifierExpression extends Expression {
  IdentifierExpression(this.value);
  final String value;
  dynamic eval(GameManager game, Scope scope) => scope.getVar(value, "IE");
}

class MoneyExpression extends Expression {
  int eval(GameManager game, Scope scope) => game.money; 
}

// other things

class TokenGetter {
  TokenGetter(this._tokens);
  int index = 0;
  final List<Token> _tokens;
  Token get peek => _tokens[index];
  Token get peekAhead => _tokens[index+1];
  Token get advance => _tokens[index++];
}

class Scope {
  Scope([this.parent]);
  final Scope parent;
  Map<String, dynamic> _vars = {};
  void declare(String name, dynamic value) {
    if(_vars[name] != null) {
      print("Local variable $name redeclared.");
      exit(4);
    }
    _vars[name] = value;
  }

  void assign(String name, dynamic value) {
    if(_vars[name] != null) {
      _vars[name] = value;
      return;
    }
    if(parent == null) {
      print("Tried to assign $name, an undefined variable, to $value.");
      exit(4);
    }
    parent.assign(name, value);
  }

  dynamic _getVar(String name) {
    return parent?._getVar(name) ?? _vars[name];
  }

  dynamic getVar(String name, [String context = ""]) => _getVar(name) ?? (){
    print("Tried to get the value of $name, an undefined variable.");
    exit(4);
  }();
}