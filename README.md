# flutter_pikafish
The Flutter plugin for PIKAFISH (base on Stockfish), A well-known Chinese chess open source engine.

# Usages 

iOS project must have IPHONEOS_DEPLOYMENT_TARGET >=11.0.

Add dependency 

Update dependencies section inside pubspec.yaml:

``` yaml
  flutter_pikafish: ^<last-version>
```

Init engine

``` dart
import 'package:pikafish_engine/pikafish_engine.dart';

// create a new instance
final pikafish = Pikafish();

// state is a ValueListenable<PikafishState>
print(pikafish.state.value); # PikafishState.starting

// the engine takes a few moment to start
await Future.delayed(...)
print(pikafish.state.value); # PikafishState.ready
```

UCI command 

Waits until the state is ready before sending commands.

``` dart
pikafish.stdin = 'isready';
pikafish.stdin = 'go movetime 3000';
pikafish.stdin = 'go infinite';
pikafish.stdin = 'stop';
```

Engine output is directed to a Stream<String>, add a listener to process results.

``` dart
pikafish.stdout.listen((line) {
  // do something useful
  print(line);
});
```

Dispose / Hot reload 

There are two active isolates when Pikafish engine is running.
That interferes with Flutter's hot reload feature so you need to dispose it before attempting to reload.

``` dart
// sends the UCI quit command
pikafish.stdin = 'quit';

// or even easier...
pikafish.dispose();
```

Note: only one instance can be created at a time.
The factory method Pikafish() will return null if it was called when an existing instance is active.


## Refer the implementation

https://github.com/ArjanAswal/stockfish
