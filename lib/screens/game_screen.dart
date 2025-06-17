import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Dino variables
  double dinoY = 1; // Dino starts on the ground
  double dinoSize = 50;
  bool isJumping = false;

  // Obstacle variables
  double obstacleX = 1.2;
  double obstacleHeight = 60; // Increased cactus height
  double obstacleWidth = 30;

  // Game state
  bool gameHasStarted = false;
  int score = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _updateHighScore() async {
    if (score > highScore) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      double jumpHeight = -0.7;  // Higher jump to clear cactus
      double gravity = 0.01;     // Smooth gravity
      int jumpSpeed = 15;        // Slower jump for smoothness

      // Jump animation with height limit
      Timer.periodic(Duration(milliseconds: jumpSpeed), (timer) {
        jumpHeight += gravity;
        setState(() {
          dinoY += jumpHeight;
          if (dinoY < 0.3) dinoY = 0.3; // Limit jump height for smoother landing
        });

        // Stop jumping when back to ground
        if (dinoY >= 1) {
          isJumping = false;
          dinoY = 1; // Reset to ground level
          timer.cancel();
        }
      });
    }
  }

  void startGame() {
    gameHasStarted = true;
    score = 0;
    obstacleX = 1.2;

    // Game loop
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        obstacleX -= 0.01;
      });

      // Reset obstacle and increase score
      if (obstacleX < -1.2) {
        obstacleX = 1.2;
        score += 1;
      }

      // Check collision
      if (detectCollision()) {
        timer.cancel();
        _updateHighScore();
        _showGameOverDialog();
      }
    });
  }

  bool detectCollision() {
    // Adjusted collision detection for smoother gameplay
    if (obstacleX < 0.2 && obstacleX > -0.2 && dinoY > 0.7) {
      return true;
    }
    return false;
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over", style: TextStyle(color: Colors.deepPurpleAccent)),
        content: Text("Your score: $score", style: const TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                gameHasStarted = false;
                dinoY = 1; // Reset to ground level
                obstacleX = 1.2; // Reset obstacle
              });
            },
            child: const Text("Play Again", style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30), // Gap between top and score display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Colors.deepPurpleAccent, Colors.black],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "High Score: $highScore",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Score: $score",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (gameHasStarted) {
                        jump();
                      } else {
                        startGame();
                      }
                    },
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment(0, dinoY),
                          child: Container(
                            height: dinoSize,
                            width: dinoSize,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/dino.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(obstacleX, 1),
                          child: Container(
                            height: obstacleHeight,
                            width: obstacleWidth,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/cactus.png'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ground base line
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 5,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                gameHasStarted ? "Tap to Jump!" : "Tap to Start!",
                style: const TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
