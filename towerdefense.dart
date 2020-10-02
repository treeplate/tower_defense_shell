import 'dart:math' as math;

abstract class Entity {
  void tick(int x, int y, GameManager game);
  int get speed;
  int get pathCost;
}

class Tower extends Entity {
  static int range = 1; // Chebyshev distance
  void tick(int x, int y, GameManager game) {
    int minx = math.max(x - range, 0);
    int maxx = math.min(x + range + 1, game.width);
    int miny = math.max(y - range, 0);
    int maxy = math.min(y + range + 1, game.height);
    for (y = miny; y < maxy; y += 1) {
      for (x = minx; x < maxx; x += 1) {
        Entity target = game.at(x, y);
        if (target is Enemy) {
          game.fireAt(x, y);
          break;
        }
      }
    }
  }
  int get speed => 0;
  int get pathCost => 10;
}

class Enemy extends Entity {
  void tick(int x, int y, GameManager game) { }
  int get speed => 1;
  int get pathCost => 1;
}

class _MovePlan {
  _MovePlan(this.entity, this.from, this.to);
  final Entity entity;
  final int from;
  final int to;
}

class GameManager {
  GameManager(this.width, int height) : _grid = List<Entity>(width * height) {
    if (_grid[0] == null) {
      _grid[0] = Enemy();
    }
    _recomputeCosts();
  }

  final int width;
  int get height => _grid.length ~/ width;
  final List<Entity> _grid;
  List<int> _costs;

  void _recomputeCosts() {
    _costs = List<int>.filled(_grid.length, 0);
    _costs[_costs.length - 1] = 1;
    final List<int> pending = <int>[_grid.length - 1];
    while (pending.isNotEmpty) {
      pending.sort((int a, int b) => _costs[a] - _costs[b]);
      int index = pending.removeAt(0);
      int next = _costs[index] + 1;
      void consider(int newIndex) {
        if (_costs[newIndex] == 0) {
          int adjust = 0;
          if (_grid[newIndex] != null)
            adjust = _grid[newIndex].pathCost;
          _costs[newIndex] = next + adjust;
          pending.add(newIndex);
        } else {
          assert(_costs[newIndex] <= next);
        }
      }
      if (index % width > 0) // else left edge
        consider(index - 1);
      if ((index + 1) % width > 0) // else right edge
        consider(index + 1);
      if (index >= width) // else top edge
        consider(index - width);
      if (index < _grid.length - width) // else bottom edge
        consider(index + width);
    }
  }

  // enemies path toward goal, moving one step orthogonally.
  // towers each shoot an enemy with Chebyshev distance of one.
  void tick() {
    for (int index = 0; index < _grid.length; index += 1) {
      _grid[index]?.tick(index % width, index ~/ width, this);
    }
    Set<_MovePlan> pending = <_MovePlan>{};
    for (int index = 0; index < _grid.length; index += 1) {
      Entity entity = _grid[index];
      if (entity != null && entity.speed > 0) {
        int local = _costs[index];
        int target;
        if (index < _grid.length - width) { // else bottom edge
          if (_costs[index + width] < local) {
            target = index + width;
            local = _costs[index + width];
          }
        }
        if (index % width > 0) { // else left edge
          if (_costs[index - 1] < local) {
            target = index - 1;
            local = _costs[index - 1];
          }
        }
        if ((index + 1) % width > 0) { // else right edge
          if (_costs[index + 1] < local) {
            target = index + 1;
            local = _costs[index + 1];
          }
        }
        if (index >= width) { // else top edge
          if (_costs[index - width] < local) {
            target = index - width;
            local = _costs[index - width];
          }
        }
        print('from $index to $target ($local)');
        if (target != null) {
          pending.add(_MovePlan(entity, index, target));
        }
      }
    }
    while (pending.isNotEmpty) {
      Set<_MovePlan> failures = <_MovePlan>{};
      for (_MovePlan plan in pending) {
        if (_grid[plan.to] == null) {
          _grid[plan.from] = null;
          _grid[plan.to] = plan.entity;
        } else {
          failures.add(plan);
        }
      }
      if (failures.length == pending.length) {
        print('got stuck');
        break;
      }
      pending = failures;      
    }
  }

  Entity at(int x, int y) {
    return _grid[y * width + x];
  }

  void fireAt(int x, int y) {
    _grid[y * width + x] = null;
  }

  // if money > 9 and position at x, y clear, place tower x, y and decrease money by 10
  void tower(int x, int y) {
    if (_money > 9 && _grid[y * width + x] == null) {
      _grid[y * width + x] = Tower();
      _money -= 10;
      _recomputeCosts();
    }
  }

  // print what is at x,y
  void view(int x, int y) {
    print(_grid[y * width + x]);
  }

  // return money
  int get money => _money;
  int _money = 10000;

  void debug() {
    StringBuffer buffer = StringBuffer();
    for (int y = 0; y < height; y += 1) {
      for (int x = 0; x < width; x += 1) {
        Entity entity = _grid[y * width + x];
        if (entity is Enemy) {
          buffer.write('  E  ');
        } else if (entity is Tower) {
          buffer.write('  T  ');
        } else if (entity == null) {
          buffer.write(' ${_costs[y * width + x].toString().padLeft(3, '0')} ');
        } else {
          buffer.write('?');
        }
      }
      buffer.write('\n');
    }
    print(buffer);
  }
}