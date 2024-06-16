import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class QuizScreen extends StatefulWidget {
  final bool resetQuiz;
  QuizScreen({required this.resetQuiz});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  Timer? _timer;
  int _timeRemaining = 600; // 10 minutes in seconds
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      String data = await DefaultAssetBundle.of(context)
          .loadString("assets/quetions.json");
      setState(() {
        _questions = json.decode(data);
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (widget.resetQuiz) {
      await prefs.clear();
      setState(() {
        _currentQuestionIndex = 0;
        _score = 0;
        _timeRemaining = 600;
      });
    } else {
      setState(() {
        _currentQuestionIndex =
            prefs.getInt('currentQuestionIndex') ?? 0;
        _score = prefs.getInt('score') ?? 0;
        _timeRemaining =
            prefs.getInt('timeRemaining') ?? 600;
      });
    }
    _startTimer();
  }

  Future<void> _saveState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentQuestionIndex', _currentQuestionIndex);
    await prefs.setInt('score', _score);
    await prefs.setInt('timeRemaining', _timeRemaining);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        _saveState();
      } else {
        timer.cancel();
        if (_currentQuestionIndex < _questions.length - 1) {
          _goToNextQuestion();
        } else {
          _showScore();
        }
      }
    });
  }

  void _showScore() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Finished'),
          content: Text('Your score is $_score/${_questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetQuiz();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pop();
  }

  void _answerQuestion(String? selectedOption) {
    if (selectedOption != null &&
        _questions[_currentQuestionIndex]['answer'] == selectedOption) {
      _score++;
    }
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _timer?.cancel();
      _showScore();
    }
    _saveState();
  }


  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _saveState();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Failed to load questions. Please try again later.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No questions available.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              Text(
                'Time remaining: ${(_timeRemaining / 60).floor()
                    .toString()
                    .padLeft(2, '0')}:${(_timeRemaining % 60)
                    .toString()
                    .padLeft(2, '0')}',
                style: TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: TextStyle(fontSize: 22, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                _questions[_currentQuestionIndex]['question'],
                style: TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ..._questions[_currentQuestionIndex]['options'].map((option) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity, // Make button take the full width
                      child: ElevatedButton(
                        onPressed: () => _answerQuestion(option),
                        child: Text(option),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                          minimumSize: Size(
                              double.infinity, 50), // Set fixed size
                        ),
                      ),
                    ),
                    SizedBox(height: 10,)
                  ],
                );
              }).toList(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _goToPreviousQuestion,
                    child: Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent, backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentQuestionIndex < _questions.length - 1) {
                        _goToNextQuestion();
                      } else {
                        _answerQuestion(null); // or you can handle this case accordingly
                      }
                    },
                    child: Text(_currentQuestionIndex < _questions.length - 1
                        ? 'Next'
                        : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent, backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

