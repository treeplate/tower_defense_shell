abstract class Token {
  Token(this.line, this.column);
  final int line;
  final int column;
  String get description;
  String toString() => '$description at $line:$column';
}
class KeywordToken extends Token {
  KeywordToken(int line, int column, this.name) : super(line, column);
  final String name;
  String get description => 'keyword $name';
}
class IntegerToken extends Token {
  IntegerToken(int line, int column, this.value) : super(line, column);
  final int value;
  String get description => 'integer $value';
}
class SymbolToken extends Token {
  SymbolToken(int line, int column, this.symbol) : super(line, column);
  final String symbol;
  String get description => 'symbol $symbol';
}
class EofToken extends Token {
  EofToken(int line, int column) : super(line, column);
  String get description => 'end of file';
}

class SyntaxError implements Exception {
  SyntaxError(this.message);
  final String message;
  String toString() => message;
}

enum _Category { eof, newline, space, digit, letter, symbol, symbolSequence, other }

_Category _category(int rune) {
  if (rune < 0)
    return _Category.eof;
  if (rune == 0x0A)
    return _Category.newline;
  if (rune < 0x20)
    return _Category.other; // control characters
  if (rune == 0x20)
    return _Category.space;
  if (rune < 0x28)
    return _Category.symbolSequence;
  if (rune < 0x2A)
    return _Category.symbol; // (, )
  if (rune < 0x30)
    return _Category.symbolSequence;
  if (rune < 0x3A)
    return _Category.digit;
  if (rune < 0x41)
    return _Category.symbolSequence;
  if (rune < 0x5B)
    return _Category.letter;
  if (rune < 0x5C)
    return _Category.symbol; // [
  if (rune < 0x5D)
    return _Category.symbolSequence;
  if (rune < 0x5E)
    return _Category.symbol; // ]
  if (rune < 0x61)
    return _Category.symbolSequence;
  if (rune < 0x7B)
    return _Category.letter;
  if (rune < 0x7C)
    return _Category.symbol; // {
  if (rune < 0x7D)
    return _Category.symbolSequence;
  if (rune < 0x7E)
    return _Category.symbol; // }
  if (rune < 0x7F)
    return _Category.symbolSequence;
  return _Category.other;
}

enum _State { top, keyword, integer, symbolSequence }

Iterable<Token> tokenize(String input) sync* {
  _State state = _State.top;
  StringBuffer buffer;
  int line = 1;
  int column = 0;
  for (int c in _runesWithEnd(input)) {
    column += 1;
    switch (state) {
      case _State.top:
        switch (_category(c)) {
          case _Category.eof:
            break;
          case _Category.newline:
            line += 1;
            column = 0;
            break;
          case _Category.space:
            break;
          case _Category.digit:
            buffer = StringBuffer();
            state = _State.integer;
            break;
          case _Category.letter:
            buffer = StringBuffer();
            state = _State.keyword;
            break;
          case _Category.symbol:
            yield SymbolToken(line, column, String.fromCharCode(c));
            break;
          case _Category.symbolSequence:
            buffer = StringBuffer();
            state = _State.symbolSequence;
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}"');
        }
        break;
      case _State.integer:
        switch (_category(c)) {
          case _Category.eof:
            yield IntegerToken(line, column, int.parse(buffer.toString()));
            buffer = null;
            break;
          case _Category.newline:
            yield IntegerToken(line, column, int.parse(buffer.toString()));
            buffer = null;
            state = _State.top;
            line += 1;
            column = 0;
            break;
          case _Category.space:
            yield IntegerToken(line, column, int.parse(buffer.toString()));
            buffer = null;
            state = _State.top;
            break;
          case _Category.digit:
            break;
          case _Category.symbol:
            yield IntegerToken(line, column, int.parse(buffer.toString()));
            buffer = null;
            yield SymbolToken(line, column, String.fromCharCode(c));
            state = _State.top;
            break;
          case _Category.symbolSequence:
            yield IntegerToken(line, column, int.parse(buffer.toString()));
            buffer = null;
            buffer = StringBuffer();
            state = _State.symbolSequence;
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}" in integer');
        }
        break;
      case _State.keyword:
        switch (_category(c)) {
          case _Category.eof:
            yield KeywordToken(line, column, buffer.toString());
            buffer = null;
            break;
          case _Category.newline:
            yield KeywordToken(line, column, buffer.toString());
            buffer = null;
            state = _State.top;
            line += 1;
            column = 0;
            break;
          case _Category.space:
            yield KeywordToken(line, column, buffer.toString());
            buffer = null;
            state = _State.top;
            break;
          case _Category.digit:
          case _Category.letter:
            break;
          case _Category.symbol:
            yield KeywordToken(line, column, buffer.toString());
            buffer = null;
            yield SymbolToken(line, column, String.fromCharCode(c));
            state = _State.top;
            break;
          case _Category.symbolSequence:
            yield IntegerToken(line, column, int.parse(buffer.toString()));
            buffer = null;
            buffer = StringBuffer();
            state = _State.symbolSequence;
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}" in keyword');
        }
        break;
      case _State.symbolSequence:
        switch (_category(c)) {
          case _Category.eof:
            yield SymbolToken(line, column, buffer.toString());
            buffer = null;
            break;
          case _Category.newline:
            yield SymbolToken(line, column, buffer.toString());
            buffer = null;
            state = _State.top;
            line += 1;
            column = 0;
            break;
          case _Category.space:
            yield SymbolToken(line, column, buffer.toString());
            buffer = null;
            state = _State.top;
            break;
          case _Category.digit:
            yield SymbolToken(line, column, buffer.toString());
            buffer = null;
            buffer = StringBuffer();
            state = _State.integer;
            break;
          case _Category.letter:
            yield SymbolToken(line, column, buffer.toString());
            buffer = null;
            buffer = StringBuffer();
            state = _State.keyword;
            break;
          case _Category.symbol:
            yield SymbolToken(line, column, buffer.toString());
            buffer = null;
            yield SymbolToken(line, column, String.fromCharCode(c));
            state = _State.top;
            break;
          case _Category.symbolSequence:
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}" in keyword');
        }
        break;
    }
    buffer?.write(String.fromCharCode(c));
  }
  yield EofToken(line, column);
}

void _error(int line, int column, String message) {
  throw SyntaxError('$line:$column: $message');
}

Iterable<int> _runesWithEnd(String input) sync* {
  yield* input.runes;
  yield -1;
}