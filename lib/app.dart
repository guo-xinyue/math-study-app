import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MathStudyApp());
}

class MathStudyApp extends StatelessWidget {
  const MathStudyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '算数勉強アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MathQuizScreen(),
    );
  }
}

// 問題を記録するクラス
class Question {
  final int num1;
  final int num2;
  final String operator;
  final int correctAnswer;

  Question({
    required this.num1,
    required this.num2,
    required this.operator,
    required this.correctAnswer,
  });
}

// 難易度
enum Difficulty {
  medium,  // 中
  high,    // 高
}

class MathQuizScreen extends StatefulWidget {
  const MathQuizScreen({Key? key}) : super(key: key);

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends State<MathQuizScreen> {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  
  int _num1 = 0;
  int _num2 = 0;
  String _operator = '+';
  int _correctAnswer = 0;
  int _score = 0;
  int _totalQuestions = 0;
  Color _textFieldColor = Colors.white;
  bool _isAnswered = false;
  
  // 難易度
  Difficulty _difficulty = Difficulty.medium;
  
  // 間違った問題を記録するリスト
  List<Question> _incorrectQuestions = [];
  
  // 復習モード関連
  bool _isReviewMode = false;
  int _reviewIndex = 0;
  int _reviewScore = 0;
  List<Question> _reviewIncorrectQuestions = [];
  
  // ゲームモード（true: 時間制限、false: 問題数制限）
  bool _isTimeMode = true;
  
  // タイマー関連
  Timer? _timer;
  int _remainingSeconds = 60;
  int _selectedTimeLimit = 60;
  
  // 問題数制限関連
  int _questionLimit = 30;
  
  // 所要時間計測
  Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  
  bool _isGameActive = false;
  bool _isGameFinished = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
    _answerController.addListener(_onAnswerChanged);
  }

  void _startGameWithTime(int timeLimit) {
    setState(() {
      _isTimeMode = true;
      _selectedTimeLimit = timeLimit;
      _score = 0;
      _totalQuestions = 0;
      _remainingSeconds = timeLimit;
      _isGameActive = true;
      _isGameFinished = false;
      _incorrectQuestions.clear();
      _isReviewMode = false;
      _elapsedSeconds = 0;
      _generateQuestion();
      _answerController.clear();
    });
    
    // カウントダウンタイマー
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _endGame();
        }
      });
    });
    
    // 所要時間計測開始
    _stopwatch.reset();
    _stopwatch.start();
    _startElapsedTimer();
  }

  void _startGameWithQuestions(int questionLimit) {
    setState(() {
      _isTimeMode = false;
      _questionLimit = questionLimit;
      _score = 0;
      _totalQuestions = 0;
      _isGameActive = true;
      _isGameFinished = false;
      _incorrectQuestions.clear();
      _isReviewMode = false;
      _elapsedSeconds = 0;
      _generateQuestion();
      _answerController.clear();
    });
    
    // 所要時間計測開始
    _stopwatch.reset();
    _stopwatch.start();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = _stopwatch.elapsed.inSeconds;
        });
      }
    });
  }

  void _startReviewMode() {
    setState(() {
      _isReviewMode = true;
      _reviewIndex = 0;
      _reviewScore = 0;
      _reviewIncorrectQuestions.clear();
      _isGameFinished = false;
      _isGameActive = true;
      _elapsedSeconds = 0;
      _loadReviewQuestion();
      _answerController.clear();
    });
    
    // 復習モードでも所要時間計測
    _stopwatch.reset();
    _stopwatch.start();
    _startElapsedTimer();
  }

  void _loadReviewQuestion() {
    if (_reviewIndex < _incorrectQuestions.length) {
      final question = _incorrectQuestions[_reviewIndex];
      setState(() {
        _num1 = question.num1;
        _num2 = question.num2;
        _operator = question.operator;
        _correctAnswer = question.correctAnswer;
        _isAnswered = false;
      });
    } else {
      _endReviewMode();
    }
  }

  void _endReviewMode() {
    _stopwatch.stop();
    _elapsedTimer?.cancel();
    setState(() {
      _isGameActive = false;
      _isGameFinished = true;
      _incorrectQuestions = List.from(_reviewIncorrectQuestions);
    });
  }

  void _endGame() {
    _timer?.cancel();
    _stopwatch.stop();
    _elapsedTimer?.cancel();
    setState(() {
      _isGameActive = false;
      _isGameFinished = true;
    });
  }

  void _generateQuestion() {
    if (_difficulty == Difficulty.medium) {
      _generateMediumQuestion();
    } else {
      _generateHighQuestion();
    }
    
    _isAnswered = false;
  }

  // 中難易度の問題生成（従来通り）
  void _generateMediumQuestion() {
    final operators = ['+', '-', '×', '÷'];
    _operator = operators[_random.nextInt(operators.length)];
    
    switch (_operator) {
      case '+':
        _num1 = _random.nextInt(50) + 1;
        _num2 = _random.nextInt(50) + 1;
        _correctAnswer = _num1 + _num2;
        break;
      case '-':
        _num1 = _random.nextInt(50) + 1;
        _num2 = _random.nextInt(_num1) + 1;
        _correctAnswer = _num1 - _num2;
        break;
      case '×':
        _num1 = _random.nextInt(12) + 1;
        _num2 = _random.nextInt(12) + 1;
        _correctAnswer = _num1 * _num2;
        break;
      case '÷':
        _num2 = _random.nextInt(12) + 1;
        _correctAnswer = _random.nextInt(12) + 1;
        _num1 = _num2 * _correctAnswer;
        break;
    }
  }

  // 高難易度の問題生成
  void _generateHighQuestion() {
    final operators = ['+', '-', '×', '÷'];
    _operator = operators[_random.nextInt(operators.length)];
    
    switch (_operator) {
      case '+':
        // 繰り上げが必要な問題のみ、1桁+1桁は不要
        do {
          // 少なくとも1つは2桁にする
          if (_random.nextBool()) {
            _num1 = _random.nextInt(90) + 10; // 10-99
            _num2 = _random.nextInt(90) + 10; // 10-99
          } else {
            _num1 = _random.nextInt(50) + 10; // 10-59
            _num2 = _random.nextInt(50) + 10; // 10-59
          }
          _correctAnswer = _num1 + _num2;
          
          // 繰り上げが必要かチェック（一の位の和が10以上）
          int onesDigit1 = _num1 % 10;
          int onesDigit2 = _num2 % 10;
          bool hasCarry = (onesDigit1 + onesDigit2) >= 10;
          
          if (hasCarry) break;
        } while (true);
        break;
        
      case '-':
        // 繰り下げが必要な問題のみ、結果が0でない
        do {
          _num1 = _random.nextInt(90) + 10; // 10-99
          _num2 = _random.nextInt(_num1 - 1) + 1; // 1から_num1-1まで
          _correctAnswer = _num1 - _num2;
          
          // 繰り下げが必要かチェック（一の位の引き算で借りが必要）
          int onesDigit1 = _num1 % 10;
          int onesDigit2 = _num2 % 10;
          bool hasBorrow = onesDigit1 < onesDigit2;
          
          if (hasBorrow && _correctAnswer > 0) break;
        } while (true);
        break;
        
      case '×':
        // 1×は不要、2×は20%程度
        do {
          _num1 = _random.nextInt(12) + 1;
          _num2 = _random.nextInt(12) + 1;
          
          // 1×は除外
          if (_num1 == 1 || _num2 == 1) continue;
          
          // 2×は20%の確率で許可
          if ((_num1 == 2 || _num2 == 2) && _random.nextInt(100) >= 20) continue;
          
          break;
        } while (true);
        _correctAnswer = _num1 * _num2;
        break;
        
      case '÷':
        // 割り算は中難易度と同じ
        _num2 = _random.nextInt(12) + 1;
        _correctAnswer = _random.nextInt(12) + 1;
        _num1 = _num2 * _correctAnswer;
        break;
    }
  }

  void _onAnswerChanged() {
    if (_isAnswered || !_isGameActive) return;
    
    final userAnswer = int.tryParse(_answerController.text);
    
    if (userAnswer == null) {
      setState(() {
        _textFieldColor = Colors.white;
      });
      return;
    }

    final correctAnswerLength = _correctAnswer.toString().length;
    final userAnswerLength = _answerController.text.length;
    
    if (userAnswerLength >= correctAnswerLength) {
      _checkAnswer(userAnswer);
    }
  }

  void _checkAnswer(int userAnswer) {
    if (_isAnswered || !_isGameActive) return;
    
    setState(() {
      _isAnswered = true;
      
      if (userAnswer == _correctAnswer) {
        // 正解
        if (_isReviewMode) {
          _reviewScore++;
        } else {
          _score++;
          _totalQuestions++;
        }
        _textFieldColor = Colors.green.shade100;
      } else {
        // 不正解
        if (_isReviewMode) {
          _reviewIncorrectQuestions.add(Question(
            num1: _num1,
            num2: _num2,
            operator: _operator,
            correctAnswer: _correctAnswer,
          ));
        } else {
          _totalQuestions++;
          _incorrectQuestions.add(Question(
            num1: _num1,
            num2: _num2,
            operator: _operator,
            correctAnswer: _correctAnswer,
          ));
        }
        _textFieldColor = Colors.red.shade100;
      }
    });
    
    // 問題数モードで規定数に到達したか確認
    if (!_isReviewMode && !_isTimeMode && _totalQuestions >= _questionLimit) {
      // 0.3秒後にゲーム終了
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _endGame();
        }
      });
    } else {
      // 0.3秒後に次の問題へ
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isGameActive) {
          if (_isReviewMode) {
            _nextReviewQuestion();
          } else {
            _nextQuestion();
          }
        }
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _generateQuestion();
      _answerController.clear();
      _textFieldColor = Colors.white;
    });
  }

  void _nextReviewQuestion() {
    setState(() {
      _reviewIndex++;
      _answerController.clear();
      _textFieldColor = Colors.white;
    });
    
    Future.microtask(() {
      if (mounted) {
        _loadReviewQuestion();
      }
    });
  }

  // 数字ボタンが押されたときの処理
  void _onNumberPressed(String number) {
    if (!_isGameActive || _isAnswered) return;
    
    setState(() {
      _answerController.text += number;
      // カーソルを最後に移動
      _answerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _answerController.text.length),
      );
    });
  }

  // 消去ボタンが押されたときの処理
  void _onDeletePressed() {
    if (!_isGameActive || _isAnswered) return;
    
    setState(() {
      if (_answerController.text.isNotEmpty) {
        _answerController.text = _answerController.text.substring(
          0,
          _answerController.text.length - 1,
        );
        _answerController.selection = TextSelection.fromPosition(
          TextPosition(offset: _answerController.text.length),
        );
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReviewMode ? '算数勉強アプリ - 復習モード' : '算数勉強アプリ'),
      ),
      body: GestureDetector(
        onTap: () {
          // タップしてもフォーカスしない（数字ボタンを使うため）
        },
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isGameFinished 
                  ? _buildResultScreen()
                  : _isGameActive
                      ? _buildGameScreen()
                      : _buildStartScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calculate, size: 100, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          '算数勉強アプリ',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'モードを選んで挑戦しよう！',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // 難易度選択
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '難易度: ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 100, // 1.5倍の横幅（元の約60-70pxの1.5倍）
              child: ChoiceChip(
                label: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    '中',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: _difficulty == Difficulty.medium,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _difficulty = Difficulty.medium;
                    });
                  }
                },
                selectedColor: Colors.blue.shade200,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100, // 1.5倍の横幅（元の約60-70pxの1.5倍）
              child: ChoiceChip(
                label: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    '高',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: _difficulty == Difficulty.high,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _difficulty = Difficulty.high;
                    });
                  }
                },
                selectedColor: Colors.orange.shade200,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // 2列レイアウト
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左列：時間チャレンジ
            Column(
              children: [
                const Text(
                  '⏱️ 時間チャレンジ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _startGameWithTime(30),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Column(
                      children: [
                        Text('30秒', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('スピード勝負', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _startGameWithTime(60),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Column(
                      children: [
                        Text('1分', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('スタンダード', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _startGameWithTime(120),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.green,
                    ),
                    child: const Column(
                      children: [
                        Text('2分', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('じっくり挑戦', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 40),
            
            // 右列：問題数チャレンジ
            Column(
              children: [
                const Text(
                  '📝 問題数チャレンジ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _startGameWithQuestions(30),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Column(
                      children: [
                        Text('30問', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('ライト', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _startGameWithQuestions(60),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.teal,
                    ),
                    child: const Column(
                      children: [
                        Text('60問', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('ノーマル', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => _startGameWithQuestions(100),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.red,
                    ),
                    child: const Column(
                      children: [
                        Text('100問', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('ハード', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 数字キーパッドを作成
  Widget _buildNumberKeypad() {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = min(screenWidth * 0.2, 80.0);
    
    return Column(
      children: [
        // 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton('1', buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('2', buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('3', buttonSize),
          ],
        ),
        const SizedBox(height: 8),
        // 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton('4', buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('5', buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('6', buttonSize),
          ],
        ),
        const SizedBox(height: 8),
        // 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberButton('7', buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('8', buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('9', buttonSize),
          ],
        ),
        const SizedBox(height: 8),
        // 消去, 0
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDeleteButton(buttonSize),
            const SizedBox(width: 8),
            _buildNumberButton('0', buttonSize),
            SizedBox(width: buttonSize + 8), // 右側を空ける
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.blue.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          number,
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: _onDeletePressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.red.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(
          Icons.backspace_outlined,
          size: size * 0.4,
          color: Colors.red.shade900,
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    if (_isReviewMode) {
      return _buildReviewScreen();
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 画面サイズに応じてフォントサイズを計算
    final questionFontSize = min(screenWidth * 0.1, 60.0);
    final inputWidth = min(screenWidth * 0.6, 300.0);
    final inputFontSize = min(screenWidth * 0.08, 40.0);
    
    return SizedBox(
      width: min(screenWidth * 0.95, 1000),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // スコア表示
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // 時間表示（時間モードの場合は残り時間、問題数モードの場合は所要時間）
              if (_isTimeMode)
                Card(
                  color: _remainingSeconds <= 10 ? Colors.red.shade50 : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text('残り時間', style: TextStyle(fontSize: 12)),
                        Text(
                          '$_remainingSeconds秒',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds <= 10 ? Colors.red : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: Colors.cyan.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text('所要時間', style: TextStyle(fontSize: 12)),
                        Text(
                          _formatTime(_elapsedSeconds),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // 正解数
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text('正解数', style: TextStyle(fontSize: 12)),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 問題数
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(_isTimeMode ? '問題数' : '進捗', style: const TextStyle(fontSize: 12)),
                      Text(
                        _isTimeMode ? '$_totalQuestions' : '$_totalQuestions / $_questionLimit',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 正答率
              if (_totalQuestions > 0)
                Card(
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text('正答率', style: TextStyle(fontSize: 12)),
                        Text(
                          '${(_score / _totalQuestions * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.03),
          
          // 問題表示
          Card(
            elevation: 4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Text(
                '$_num1 $_operator $_num2 = ?',
                style: TextStyle(
                  fontSize: questionFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          // 答え入力欄（読み取り専用）
          SizedBox(
            width: inputWidth,
            child: TextField(
              controller: _answerController,
              focusNode: _focusNode,
              readOnly: true, // 読み取り専用にしてキーボードを表示させない
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: inputFontSize),
              decoration: InputDecoration(
                hintText: '答え',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: _textFieldColor,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.015,
                ),
              ),
            ),
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          // 数字キーパッド
          _buildNumberKeypad(),
        ],
      ),
    );
  }

  Widget _buildReviewScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 画面サイズに応じてフォントサイズを計算
    final questionFontSize = min(screenWidth * 0.1, 60.0);
    final inputWidth = min(screenWidth * 0.6, 300.0);
    final inputFontSize = min(screenWidth * 0.08, 40.0);
    
    return SizedBox(
      width: min(screenWidth * 0.95, 1000),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text('復習問題', style: TextStyle(fontSize: 12)),
                      Text(
                        '${_reviewIndex + 1} / ${_incorrectQuestions.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text('正解数', style: TextStyle(fontSize: 12)),
                      Text(
                        '$_reviewScore',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                color: Colors.cyan.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text('所要時間', style: TextStyle(fontSize: 12)),
                      Text(
                        _formatTime(_elapsedSeconds),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.03),
          
          Card(
            elevation: 4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Text(
                '$_num1 $_operator $_num2 = ?',
                style: TextStyle(
                  fontSize: questionFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          SizedBox(
            width: inputWidth,
            child: TextField(
              controller: _answerController,
              focusNode: _focusNode,
              readOnly: true,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: inputFontSize),
              decoration: InputDecoration(
                hintText: '答え',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: _textFieldColor,
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.015,
                ),
              ),
            ),
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          // 数字キーパッド
          _buildNumberKeypad(),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    if (_isReviewMode) {
      return _buildReviewResultScreen();
    }
    
    String modeText = _isTimeMode 
        ? (_selectedTimeLimit == 30 ? '30秒' : _selectedTimeLimit == 60 ? '1分' : '2分') 
        : '${_questionLimit}問';
    String modeType = _isTimeMode ? '時間チャレンジ' : '問題数チャレンジ';
    String difficultyText = _difficulty == Difficulty.medium ? '中' : '高';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
        const SizedBox(height: 24),
        const Text(
          '結果発表！',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '$modeText $modeType（難易度: $difficultyText）',
          style: const TextStyle(fontSize: 20, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  '所要時間: ${_formatTime(_elapsedSeconds)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyan),
                ),
                const SizedBox(height: 16),
                Text(
                  '正解数: $_score問',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 16),
                Text(
                  '問題数: $_totalQuestions問',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                if (_totalQuestions > 0)
                  Text(
                    '正答率: ${(_score / _totalQuestions * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                const SizedBox(height: 16),
                if (_incorrectQuestions.isNotEmpty)
                  Text(
                    '間違えた問題: ${_incorrectQuestions.length}問',
                    style: const TextStyle(fontSize: 20, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        if (_incorrectQuestions.isNotEmpty)
          SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: _startReviewMode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                '間違えた問題を復習する',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: 280,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isGameFinished = false;
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text(
              'もう一度挑戦',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewResultScreen() {
    final totalReviewQuestions = _reviewScore + _reviewIncorrectQuestions.length;
    final isAllCorrect = _reviewIncorrectQuestions.isEmpty;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isAllCorrect ? Icons.emoji_events : Icons.check_circle,
          size: 100,
          color: isAllCorrect ? Colors.amber : Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          isAllCorrect ? '復習完璧！🎉' : '復習完了！',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        Card(
          color: isAllCorrect ? Colors.amber.shade50 : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  '所要時間: ${_formatTime(_elapsedSeconds)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyan),
                ),
                const SizedBox(height: 16),
                Text(
                  '復習問題数: $totalReviewQuestions問',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  '正解数: $_reviewScore問',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 16),
                if (totalReviewQuestions > 0)
                  Text(
                    '正答率: ${(_reviewScore / totalReviewQuestions * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isAllCorrect ? Colors.green : Colors.blue,
                    ),
                  ),
                if (!isAllCorrect) ...[
                  const SizedBox(height: 16),
                  Text(
                    'まだ間違えた問題: ${_incorrectQuestions.length}問',
                    style: const TextStyle(fontSize: 20, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        if (!isAllCorrect)
          SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: _startReviewMode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'もう一度復習する',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: 280,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isGameFinished = false;
                _isReviewMode = false;
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text(
              'メニューに戻る',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    _answerController.removeListener(_onAnswerChanged);
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
