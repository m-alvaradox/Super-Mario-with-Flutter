import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(MyApp());

class Character extends StatelessWidget {
  final String direction;
  final String imageUrl;
  final double size;

  const Character({
    super.key,
    required this.direction,
    required this.imageUrl,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == "right") {
      return Container(
        width: size,
        height: size,
        child: Image.network(imageUrl),
      );
    } else {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: Container(
          width: size,
          height: size,
          child: Image.network(imageUrl),
        ),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Mario Bross Pro'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Variables para la posición de Mario
  static double mariox = 0.0;
  static double marioy = 1.0;
  double time = 120;
  double height = 0;
  double initialPos = marioy;
  String direction = "right";
  String directionEnemy = "left";
  int lives = 6;
  int score = 0;
  int tiempo = 120;
  bool isGameOver = false;
  String mushroomg =
      "https://cdn.pixabay.com/photo/2023/07/15/02/15/mushroom-8127948_1280.png";
  String mushroomb = "https://i.ibb.co/XkW54LdQ/hongo-bad.png";

  // Variables para la posición de los hongos
  double mushroomX = 1.5;
  //malo
  double hostileMushroomX = -1.5;

  // Variables para la posición de las balas
  double bullet1X = -1.5;
  double bullet2X = 1.5;

  // Variables para la posición del enemigo Goomba
  // Goomba ahora aparece en una posición horizontal aleatoria entre -0.9 y 0.9
  double enemyX = 0.9;

  // Lista de llamas disparadas por el Goomba
  List<Map<String, dynamic>> flames = [];

  // Variables para los tamaños de los personajes
  final double marioWidth = 0.1;
  final double mushroomWidth = 0.08;
  final double bulletWidth = 0.06;
  final double enemyWidth = 0.1;
  final double flameWidth = 0.05;
  double coinX = 0.5;
  double coinY = 0.5;
  final double coinWidth = 0.05;

  late Timer bullet1Timer;
  late Timer bullet2Timer;
  late Timer collisionTimer;
  late Timer enemyFireTimer;
  late Timer flameMovementTimer;
  late Timer hostileMushroomTimer;
  late Timer gameTimer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    // Timer de tiempo
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameOver) {
        setState(() {
          tiempo--;
          if (tiempo <= 0) {
            gameOver();
          }
        });
      }
    });

    // Iniciar temporizador para el movimiento del hongo
    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      setState(() {
        mushroomX -= 0.01;
        // Reinicia la posición del hongo cuando sale de la pantalla
        if (mushroomX < -1.5) {
          mushroomX = 1.5;
        }
      });
    });

    // Iniciar temporizador para el movimiento del nuevo hongo malo
    hostileMushroomTimer = Timer.periodic(const Duration(milliseconds: 20), (
      timer,
    ) {
      if (!isGameOver) {
        setState(() {
          hostileMushroomX +=
              0.01; // Lo movemos más rápido de izquierda a derecha
          if (hostileMushroomX > 1.5) {
            hostileMushroomX =
                -1.5; // Reinicia su posición al salir de la pantalla
          }
        });
      }
    });

    // Iniciar temporizador para el movimiento de la primera bala
    bullet1Timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!isGameOver) {
        setState(() {
          bullet1X += 0.02;
          // Reinicia la posición de la bala 1 cuando sale de la pantalla
          if (bullet1X > 1.5) {
            bullet1X = -1.5;
          }
        });
      }
    });

    // Iniciar temporizador para el movimiento de la segunda bala
    bullet2Timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!isGameOver) {
        setState(() {
          bullet2X -= 0.02;
          // Reinicia la posición de la bala 2 cuando sale de la pantalla
          if (bullet2X < -1.5) {
            bullet2X = 1.5;
          }
        });
      }
    });

    // Iniciar temporizador para que el Enemigo dispare llamas
    enemyFireTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!isGameOver) {
        setState(() {
          // Elige una de las dos posiciones posibles: 0.9 o -0.9
          enemyX = _random.nextBool() ? 0.9 : -0.9;

          if (enemyX == -0.9) {
            flames.add({'x': enemyX, 'direction': 'right'});
            directionEnemy = "right";
          } else {
            flames.add({'x': enemyX, 'direction': 'left'});
            directionEnemy = "left";
          }
        });
      }
    });

    // Iniciar temporizador para el movimiento de las llamas
    flameMovementTimer = Timer.periodic(const Duration(milliseconds: 20), (
      timer,
    ) {
      if (!isGameOver) {
        setState(() {
          for (int i = 0; i < flames.length; i++) {
            if (flames[i]['direction'] == 'right') {
              flames[i]['x'] += 0.02;
            } else {
              flames[i]['x'] -= 0.02;
            }
          }
          flames.removeWhere((flame) => flame['x'] > 1.5 || flame['x'] < -1.5);
        });
      }
    });

    // Temporizador para la detección de colisiones
    collisionTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!isGameOver) {
        if (checkMushroomCollision()) {
          addLife();
        }
        // Las balas han vuelto a sus posiciones originales
        if (checkBulletCollision(bullet1X, -0.7)) {
          loseLife();
        }
        if (checkBulletCollision(bullet2X, -0.3)) {
          loseLife();
        }
        // Colisión de Goomba
        if (checkGoombaCollision()) {
          loseLife();
        }
        // La colisión de Flame ahora usa la posición y = 0.9
        if (checkFlameCollision()) {
          loseLife();
        }
        // Colisión con el nuevo hongo malo
        if (checkHostileMushroomCollision()) {
          loseLife();
        }
        if (checkCoinCollision()) {
          collectCoin();
        }
      }
    });
  }

  @override
  void dispose() {
    bullet1Timer.cancel();
    bullet2Timer.cancel();
    collisionTimer.cancel();
    enemyFireTimer.cancel();
    flameMovementTimer.cancel();
    hostileMushroomTimer.cancel();
    gameTimer.cancel();
    super.dispose();
  }

  void cancelAllTimers() {
    bullet1Timer.cancel();
    bullet2Timer.cancel();
    collisionTimer.cancel();
    enemyFireTimer.cancel();
    flameMovementTimer.cancel();
    hostileMushroomTimer.cancel();
    gameTimer.cancel();
  }

  bool checkCoinCollision() {
    if ((mariox - marioWidth / 2) < (coinX + coinWidth / 2) &&
        (mariox + marioWidth / 2) > (coinX - coinWidth / 2) &&
        (marioy) < (coinY + coinWidth / 2) &&
        (marioy + 0.1) > (coinY - coinWidth / 2)) {
      return true;
    }
    return false;
  }

  bool checkMushroomCollision() {
    final double mushroomScreenX = mushroomX;
    final double mushroomScreenY = 0.9;
    final double marioScreenX = mariox;
    final double marioScreenY = marioy;

    if ((marioScreenX - marioWidth / 2) <
            (mushroomScreenX + mushroomWidth / 2) &&
        (marioScreenX + marioWidth / 2) >
            (mushroomScreenX - mushroomWidth / 2) &&
        (marioScreenY - 0.1) < (mushroomScreenY + 0.1) &&
        (marioScreenY + 0.1) > (mushroomScreenY - 0.1)) {
      return true;
    }
    return false;
  }

  bool checkBulletCollision(double bulletX, double bulletY) {
    final double bulletScreenX = bulletX;
    final double bulletScreenY = bulletY;
    final double marioScreenX = mariox;
    final double marioScreenY = marioy;

    if ((marioScreenX - marioWidth / 2) < (bulletScreenX + bulletWidth / 2) &&
        (marioScreenX + marioWidth / 2) > (bulletScreenX - bulletWidth / 2) &&
        (marioScreenY - 0.1) < (bulletScreenY + 0.1) &&
        (marioScreenY + 0.1) > (bulletScreenY - 0.1)) {
      return true;
    }
    return false;
  }

  bool checkGoombaCollision() {
    final double goombaScreenX = enemyX;
    final double goombaScreenY = 0.9; // Posición y del Goomba
    final double marioScreenX = mariox;
    final double marioScreenY = marioy;

    if ((marioScreenX - marioWidth / 2) < (goombaScreenX + enemyWidth / 2) &&
        (marioScreenX + marioWidth / 2) > (goombaScreenX - enemyWidth / 2) &&
        (marioScreenY - 0.1) < (goombaScreenY + 0.1) &&
        (marioScreenY + 0.1) > (goombaScreenY - 0.1)) {
      return true;
    }
    return false;
  }

  bool checkHostileMushroomCollision() {
    final double mushroomScreenX = hostileMushroomX;
    final double mushroomScreenY = 0.9;
    final double marioScreenX = mariox;
    final double marioScreenY = marioy;

    if ((marioScreenX - marioWidth / 2) <
            (mushroomScreenX + mushroomWidth / 2) &&
        (marioScreenX + marioWidth / 2) >
            (mushroomScreenX - mushroomWidth / 2) &&
        (marioScreenY - 0.1) < (mushroomScreenY + 0.1) &&
        (marioScreenY + 0.1) > (mushroomScreenY - 0.1)) {
      setState(() {
        hostileMushroomX = -1.5; // Reset the position on collision
      });
      return true;
    }
    return false;
  }

  bool checkFlameCollision() {
    final double marioScreenX = mariox;
    final double marioScreenY = marioy;
    bool collisionDetected = false;

    // Usar un bucle for para eliminar de forma segura el elemento mientras se itera
    for (int i = 0; i < flames.length; i++) {
      var flame = flames[i];
      final double flameScreenY = 0.9;
      if ((marioScreenX - marioWidth / 2) < (flame['x'] + flameWidth / 2) &&
          (marioScreenX + marioWidth / 2) > (flame['x'] - flameWidth / 2) &&
          (marioScreenY - 0.1) < (flameScreenY + 0.1) &&
          (marioScreenY + 0.1) > (flameScreenY - 0.1)) {
        // Colisión detectada, eliminar la llama y marcar para la pérdida de vida
        setState(() {
          flames.removeAt(i);
        });
        collisionDetected = true;
        break;
      }
    }
    return collisionDetected;
  }

  void addLife() {
    setState(() {
      lives++;
      print("Vidas de Mario: $lives");
      // Reiniciar posición del hongo para evitar colisiones múltiples
      mushroomX = 1.5;
    });
  }

  void loseLife() {
    setState(() {
      lives--;
      print("Vidas de Mario: $lives");
      bullet1X = -1.5;
      bullet2X = 1.5;
      if (lives <= 0) {
        gameOver();
      }
    });
  }

  void gameOver() {
    setState(() {
      isGameOver = true;
    });
    cancelAllTimers();
  }

  void collectCoin() {
    setState(() {
      score++;
      print("Puntaje logrado: $score");
      resetCoinPosition(); // Reubicar la moneda en una nueva posición
    });

    if (score >= 10) {
      winGame();
    }
  }

  void winGame() {
    setState(() {
      isGameOver = true;
    });
    cancelAllTimers();
  }

  void resetCoinPosition() {
    setState(() {
      coinX = -0.9 + (_random.nextDouble() * (0.9 - (-0.9)));
      coinY = -0.9 + (_random.nextDouble() * (0.9 - (-0.9)));
    });
  }

  void preJump() {
    time = 0;
    initialPos = marioy;
  }

  void jump() {
    preJump();
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isGameOver) {
        time += 0.05;
        height = -4.9 * time * time + 5 * time;

        if (initialPos - height > 1) {
          setState(() {
            marioy = 1;
            timer.cancel();
          });
        } else {
          setState(() {
            marioy = initialPos - height;
          });
        }
      }
    });
  }

  void walkL() {
    if (!isGameOver) {
      direction = "left";
      setState(() {
        mariox -= 0.02;
      });
    }
  }

  void walkR() {
    if (!isGameOver) {
      direction = "right";
      setState(() {
        mariox += 0.02;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver && score >= 10) {
      // add
      return Scaffold(
        body: Center(
          child: Container(
            color: Colors.yellow,
            child: const Center(
              child: Text(
                "Ganaste :)",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    } // anadio

    if (isGameOver && (lives <= 0 || tiempo <= 0)) {
      return Scaffold(
        body: Center(
          child: Container(
            color: Colors.blue,
            child: const Center(
              child: Text(
                "Perdiste :(",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "VIDAS: $lives",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
                Text(
                  "PUNTOS: $score",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
                Text(
                  "TIEMPO: $tiempo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Arial',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Fondo (Cielo)
                Container(color: Colors.blue),

                // Bala 1 (vuelve a su posición original)
                AnimatedContainer(
                  alignment: Alignment(bullet1X, -0.7),
                  duration: const Duration(milliseconds: 0),
                  child: Bullet(direction: "left"),
                ),

                // Bala 2 (vuelve a su posición original)
                AnimatedContainer(
                  alignment: Alignment(bullet2X, -0.3),
                  duration: const Duration(milliseconds: 0),
                  child: Bullet(direction: "right"),
                ),

                // Enemigo
                AnimatedContainer(
                  alignment: Alignment(enemyX, 1.0),
                  duration: const Duration(milliseconds: 0),
                  child: Character(
                    direction: directionEnemy,
                    imageUrl: "https://i.ibb.co/gQ0kf0G/show.png",
                    size: 50,
                  ),
                ),

                // Llamas disparadas por el Enemigo
                // Ahora usan la posición y = 0.9 para la animación
                ...flames.map(
                  (flame) => AnimatedContainer(
                    alignment: Alignment(flame['x'], 0.9),
                    duration: const Duration(milliseconds: 0),
                    child: Flame(direction: flame['direction']),
                  ),
                ),

                // Nuevo hongo malo
                AnimatedContainer(
                  alignment: Alignment(hostileMushroomX, 1.0),
                  duration: const Duration(milliseconds: 0),
                  child: Mushroom(imagen: mushroomb),
                ),

                // Hongo
                AnimatedContainer(
                  alignment: Alignment(mushroomX, 1.0),
                  duration: const Duration(milliseconds: 0),
                  child: Mushroom(imagen: mushroomg),
                ),

                AnimatedContainer(
                  alignment: Alignment(coinX, coinY),
                  duration: const Duration(milliseconds: 0),
                  child: const Coin(),
                ),

                // Mario
                AnimatedContainer(
                  alignment: Alignment(mariox, marioy),
                  duration: const Duration(milliseconds: 0),
                  child: Character(
                    direction: direction,
                    imageUrl:
                        "https://cdn.pixabay.com/photo/2021/02/11/15/40/mario-6005703_960_720.png",
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 10, color: Colors.green),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.brown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: walkL,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.brown[300],
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  GestureDetector(
                    onTap: jump,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.brown[300],
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ),
                  GestureDetector(
                    onTap: walkR,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.brown[300],
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Mario extends StatelessWidget {
  final direction;
  const Mario({super.key, this.direction});

  @override
  Widget build(BuildContext context) {
    if (direction == "right") {
      return Container(
        width: 50,
        height: 50,
        child: Image.network(
          "https://cdn.pixabay.com/photo/2021/02/11/15/40/mario-6005703_960_720.png",
        ),
      );
    } else {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: Container(
          width: 50,
          height: 50,
          child: Image.network(
            "https://cdn.pixabay.com/photo/2021/02/11/15/40/mario-6005703_960_720.png",
          ),
        ),
      );
    }
  }
}

class Enemy extends StatelessWidget {
  final direction;
  const Enemy({super.key, this.direction});

  @override
  Widget build(BuildContext context) {
    if (direction == "right") {
      return Container(
        width: 50,
        height: 50,
        child: Image.network("https://i.ibb.co/gQ0kf0G/show.png"),
      );
    } else {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: Container(
          width: 50,
          height: 50,
          child: Image.network("https://i.ibb.co/gQ0kf0G/show.png"),
        ),
      );
    }
  }
}

class Mushroom extends StatelessWidget {
  final imagen;
  const Mushroom({super.key, this.imagen});

  @override
  Widget build(BuildContext context) {
    return Container(width: 40, height: 40, child: Image.network(imagen));
  }
}

class Bullet extends StatelessWidget {
  final direction;
  const Bullet({super.key, this.direction});

  @override
  Widget build(BuildContext context) {
    if (direction == "left") {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: Container(
          width: 30,
          height: 30,
          child: Image.network("https://i.ibb.co/VYyWcg2n/bullet.png"),
        ),
      );
    } else {
      return Container(
        width: 30,
        height: 30,
        child: Image.network("https://i.ibb.co/VYyWcg2n/bullet.png"),
      );
    }
  }
}

class Flame extends StatelessWidget {
  final direction;
  const Flame({super.key, this.direction});

  @override
  Widget build(BuildContext context) {
    if (direction == "left") {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: Container(
          width: 25,
          height: 25,
          child: Image.network("https://i.ibb.co/ccnKWtrv/flame.png"),
        ),
      );
    } else {
      return Container(
        width: 25,
        height: 25,
        child: Image.network("https://i.ibb.co/ccnKWtrv/flame.png"),
      );
    }
  }
}

class Coin extends StatelessWidget {
  const Coin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      child: Image.network("https://i.ibb.co/k2sHhMBR/coin2.png"),
    );
  }
}
