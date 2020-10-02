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

class EofToken extends Token {
  EofToken() : super(-1, -1);
  String get description => 'end-of-file';
}

class SyntaxError implements Exception {
  SyntaxError(this.message);
  final String message;
  String toString() => message;
}

enum _State { top, keyword, integer }

Iterable<Token> tokenize(String input) sync* {
  _State state = _State.top;
  int start;
  int index = 0;
  int line = 1;
  int column = 0;
  for (int c in _runesWithEnd(input)) {
    column += 1;
    switch (state) {
      case _State.top:
        switch (c) {
          case -1:
            break;
          case 0x20:
            break;
          case 0x0A:
            line += 1;
            column = 0;
            break;
          case 0x30:
          case 0x31:
          case 0x32:
          case 0x33:
          case 0x34:
          case 0x35:
          case 0x36:
          case 0x37:
          case 0x38:
          case 0x39:
            start = index;
            state = _State.integer;
            break;
          case 0x41:
          case 0x42:
          case 0x43:
          case 0x44:
          case 0x45:
          case 0x46:
          case 0x47:
          case 0x48:
          case 0x49:
          case 0x4a:
          case 0x4b:
          case 0x4c:
          case 0x4d:
          case 0x4e:
          case 0x4f:
          case 0x50:
          case 0x51:
          case 0x52:
          case 0x53:
          case 0x54:
          case 0x55:
          case 0x56:
          case 0x57:
          case 0x58:
          case 0x59:
          case 0x5a:
          case 0x61:
          case 0x62:
          case 0x63:
          case 0x64:
          case 0x65:
          case 0x66:
          case 0x67:
          case 0x68:
          case 0x69:
          case 0x6a:
          case 0x6b:
          case 0x6c:
          case 0x6d:
          case 0x6e:
          case 0x6f:
          case 0x70:
          case 0x71:
          case 0x72:
          case 0x73:
          case 0x74:
          case 0x75:
          case 0x76:
          case 0x77:
          case 0x78:
          case 0x79:
          case 0x7a:
            start = index;
            state = _State.keyword;
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}"');
        }
        break;
      case _State.integer:
        switch (c) {
          case -1:
            yield IntegerToken(line, column, int.parse(input.substring(start, index)));
            break;
          case 0x20:
            yield IntegerToken(line, column, int.parse(input.substring(start, index)));
            state = _State.top;
            break;
          case 0x0A:
            yield IntegerToken(line, column, int.parse(input.substring(start, index)));
            state = _State.top;
            line += 1;
            column = 0;
            break;
          case 0x30:
          case 0x31:
          case 0x32:
          case 0x33:
          case 0x34:
          case 0x35:
          case 0x36:
          case 0x37:
          case 0x38:
          case 0x39:
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}" in integer');
        }
        break;
      case _State.keyword:
        switch (c) {
          case -1:
            yield KeywordToken(line, column, input.substring(start, index));
            break;
          case 0x20:
            yield KeywordToken(line, column, input.substring(start, index));
            state = _State.top;
            break;
          case 0x0A:
            yield KeywordToken(line, column, input.substring(start, index));
            state = _State.top;
            line += 1;
            column = 0;
            break;
          case 0x41:
          case 0x42:
          case 0x43:
          case 0x44:
          case 0x45:
          case 0x46:
          case 0x47:
          case 0x48:
          case 0x49:
          case 0x4a:
          case 0x4b:
          case 0x4c:
          case 0x4d:
          case 0x4e:
          case 0x4f:
          case 0x50:
          case 0x51:
          case 0x52:
          case 0x53:
          case 0x54:
          case 0x55:
          case 0x56:
          case 0x57:
          case 0x58:
          case 0x59:
          case 0x5a:
          case 0x61:
          case 0x62:
          case 0x63:
          case 0x64:
          case 0x65:
          case 0x66:
          case 0x67:
          case 0x68:
          case 0x69:
          case 0x6a:
          case 0x6b:
          case 0x6c:
          case 0x6d:
          case 0x6e:
          case 0x6f:
          case 0x70:
          case 0x71:
          case 0x72:
          case 0x73:
          case 0x74:
          case 0x75:
          case 0x76:
          case 0x77:
          case 0x78:
          case 0x79:
          case 0x7a:
            break;
          default: _error(line, column, 'unexpected character "${String.fromCharCode(c)}" in keyword');
        }
        break;
    }
    index += 1;
  }
}

void _error(int line, int column, String message) {
  throw SyntaxError('$line:$column: $message');
}

Iterable<int> _runesWithEnd(String input) sync* {
  yield* input.runes;
  yield -1;
}