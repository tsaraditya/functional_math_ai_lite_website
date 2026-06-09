import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math'
    as math; // 🌟 Aliased to handle advanced scientific math configurations
import 'dart:io' show Directory, File;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 🌐 Conditional styling imports to handle raw browser elements safely
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as web_html;

void main() {
  runApp(const MathAIApp());
}

class MathAIApp extends StatelessWidget {
  const MathAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Functional Math AI Lite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainAppScreen(),
    );
  }
}

// 👑 GLOBAL STATE NAVIGATION ROUTER LIST
final List<Widget> _screens = [
  const SyllabusScreen(),
  const QuizScreen(),
  const ChatBotScreen(),
];

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  // 🧮 Triggers a global overlay bottom drawer panel housing the scientific calculator setup
  void _openGlobalCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const ScientificCalculatorWidget();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // 🌟 Floating Action Button: Fixed globally over all tab viewpoints
      floatingActionButton: FloatingActionButton(
        onPressed: _openGlobalCalculator,
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        tooltip: 'Scientific Calculator',
        child: const Icon(Icons.calculate),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Syllabus'),
          NavigationDestination(
            icon: Icon(Icons.psychology),
            label: 'AI Tutor',
          ),
          NavigationDestination(icon: Icon(Icons.chat), label: 'AI Chat'),
        ],
      ),
    );
  }
}

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  Map<String, dynamic>? _syllabusData;

  @override
  void initState() {
    super.initState();
    _loadSyllabus();
  }

  Future<void> _loadSyllabus() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/scheme_of_learning.json',
      );
      final dynamic decodedData = json.decode(response);
      setState(() {
        _syllabusData = Map<String, dynamic>.from(decodedData);
      });
    } catch (e) {
      debugPrint("Syllabus Load Intercept: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Course Syllabus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _syllabusData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0,
              ), // Padding adjusted for FAB clearance
              itemCount: _syllabusData!['topics']?.length ?? 0,
              itemBuilder: (context, index) {
                final topic = _syllabusData!['topics'][index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text("${topic['chapter'] ?? ''}"),
                    ),
                    title: Text(
                      topic['title'] ?? 'Untitled Topic',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🎯 Outcomes:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(topic['plannedOutcomes'] ?? ''),
                            const SizedBox(height: 8),
                            const Text(
                              "✅ Learners Can:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(topic['learnerCan'] ?? ''),
                            const SizedBox(height: 8),
                            const Text(
                              "🛠️ Activities:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(topic['activities'] ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  Map<String, dynamic>? _currentQuestion;
  bool _showAnswer = false;

  bool _isLoadingHint = false;
  String? _aiHint;

  bool _isLoadingExam = false;
  List<dynamic> _aiGeneratedExamQuestions = [];
  List<bool> _revealedAnswersFlags = [];
  String _exportStatusMessage = "";

  final String _aiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _apiKey = const String.fromEnvironment('GROQ_API_KEY');
  final String _modelName = 'llama-3.3-70b-versatile';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/math_database.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        _questions = data;
        _pickRandomQuestion();
      });
    } catch (e) {
      debugPrint("Questions Database Load Intercept: $e");
    }
  }

  void _pickRandomQuestion() {
    if (_questions.isNotEmpty) {
      final random = math.Random();
      setState(() {
        _currentQuestion = Map<String, dynamic>.from(
          _questions[random.nextInt(_questions.length)],
        );
        _showAnswer = false;
        _aiHint = null;
      });
    }
  }

  Future<void> _generateAIExam() async {
    if (_apiKey.isEmpty) {
      _showSecurityAlert();
      return;
    }

    setState(() {
      _isLoadingExam = true;
      _aiGeneratedExamQuestions = [];
      _exportStatusMessage = "";
    });

    final List<String> scenarios = [
      "aerospace engineering, warehouse shipping automation, and catering logistics",
      "urban green roof agriculture, sports arena management, and construction surveying",
      "automotive diagnostics, local council park events, and smart micro-grid setups",
    ];
    final String freshContextSeed =
        scenarios[math.Random().nextInt(scenarios.length)];

    try {
      final response = await http.post(
        Uri.parse(_aiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _modelName,
          "messages": [
            {
              "role": "system",
              "content":
                  "You are an official UK Functional Skills Mathematics Level 1 exam writer. Return a valid json object containing a single root key named 'questions' which maps directly to an array of exactly 17 objects. Context seed: $freshContextSeed.",
            },
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.72,
          "max_tokens": 3600,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> rootObj = jsonDecode(response.body);
        final String rawContent = rootObj['choices'][0]['message']['content']
            .trim();
        final Map<String, dynamic> parsedJson = jsonDecode(rawContent);
        final List<dynamic> parsedList = parsedJson['questions'];

        setState(() {
          _aiGeneratedExamQuestions = parsedList;
          _revealedAnswersFlags = List<bool>.filled(parsedList.length, false);
        });
      }
    } catch (e) {
      // Intercept execution errors
    } finally {
      setState(() {
        _isLoadingExam = false;
      });
    }
  }

  Future<void> _exportToWord(bool includeAnswersOnly) async {
    if (_aiGeneratedExamQuestions.isEmpty) return;
    setState(() {
      _exportStatusMessage = "Compiling file architecture layer...";
    });

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = includeAnswersOnly
          ? "Exam_Answers_$timestamp.doc"
          : "Exam_Questions_$timestamp.doc";

      StringBuffer htmlContent = StringBuffer();
      htmlContent.writeln(
        "<html><body><h1 style='color:#4A148C;font-family:Arial;'>Functional Maths Level 1 - Examination</h1>",
      );
      for (var q in _aiGeneratedExamQuestions) {
        htmlContent.writeln(
          "<p><b>Q${q['id']}. [${q['topic'] ?? 'Maths'}]</b></p>",
        );
        htmlContent.writeln("<p>${q['question'] ?? ''}</p>");
        htmlContent.writeln(
          includeAnswersOnly
              ? "<p style='color:green;'><b>Answer:</b> ${q['answer'] ?? ''}</p><br/>"
              : "<p>Answer Specification: _______________________</p><br/>",
        );
      }
      htmlContent.writeln("</body></html>");

      if (kIsWeb) {
        final bytes = utf8.encode(htmlContent.toString());
        final blob = web_html.Blob([bytes], 'application/msword');
        final url = web_html.Url.createObjectUrlFromBlob(blob);
        web_html.AnchorElement(href: url)
          ..setAttribute("download", filename)
          ..click();
        web_html.Url.revokeObjectUrl(url);
        setState(() {
          _exportStatusMessage = "Document downloaded successfully.";
        });
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$filename');
      await file.writeAsString(htmlContent.toString());
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/msword'),
      ]);
    } catch (e) {
      setState(() {
        _exportStatusMessage = "Export routine broken.";
      });
    }
  }

  Future<void> _getAIHint() async {
    if (_apiKey.isEmpty) {
      _showSecurityAlert();
      return;
    }
    setState(() {
      _isLoadingHint = true;
      _aiHint = null;
    });
    try {
      final response = await http.post(
        Uri.parse(_aiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _modelName,
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a math teacher. Give a direct operational calculation hint for this question. Do not reveal the absolute solution answer.",
            },
            {
              "role": "user",
              "content": "Problem: '${_currentQuestion!['question']}'",
            },
          ],
          "temperature": 0.4,
          "max_tokens": 250,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiHint = data['choices'][0]['message']['content'];
        });
      }
    } catch (e) {
      /* Catch context error loops */
    } finally {
      setState(() {
        _isLoadingHint = false;
      });
    }
  }

  void _showSecurityAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("API compilation Key Missing.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: 90.0,
        ), // FAB clearance
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.blue.shade200, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "AI Dynamic Exam Studio",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingExam)
                      const Center(child: CircularProgressIndicator())
                    else if (_aiGeneratedExamQuestions.isNotEmpty) ...[
                      Text(
                        "Successfully compiled ${_aiGeneratedExamQuestions.length} custom tasks.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _exportToWord(false),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("Word (Qs Only)"),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _exportToWord(true),
                            icon: const Icon(
                              Icons.assignment_turned_in,
                              size: 16,
                            ),
                            label: const Text("Word (With Ans)"),
                          ),
                        ],
                      ),
                      if (_exportStatusMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _exportStatusMessage,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _aiGeneratedExamQuestions.length,
                        itemBuilder: (context, idx) {
                          final item = _aiGeneratedExamQuestions[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Q${item['id']}. [${item['topic'] ?? 'Maths'}]",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['question'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_revealedAnswersFlags[idx])
                                    Text(
                                      "Correct Answer: ${item['answer'] ?? ''}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 15,
                                      ),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _revealedAnswersFlags[idx] = true;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 16,
                                      ),
                                      label: const Text("Verify Answer"),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ] else
                      const Text(
                        "Command the Cloud AI system to completely write a custom 17-question test layout.",
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateAIExam,
                      icon: const Icon(Icons.cyclone),
                      label: const Text("Generate 17 New Questions & Answers"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Topic: ${_currentQuestion!['topic'] ?? ''}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _currentQuestion!['question'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (_isLoadingHint)
              const Center(child: CircularProgressIndicator())
            else if (_aiHint != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          "Tutor Hint",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_aiHint!, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _getAIHint,
                icon: const Icon(Icons.lightbulb),
                label: const Text("Ask AI for a Hint"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            const SizedBox(height: 30),
            if (_showAnswer)
              Text(
                "Answer: ${_currentQuestion!['answer'] ?? ''}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAnswer = true;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Reveal Answer",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickRandomQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Next Topic Question",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "content":
          "Hello! I am your Functional Skills Math AI Tutor. Ask me any math question, or paste a problem you're stuck on, and let's solve it step-by-step! 🧠",
    },
  ];

  bool _isAiTyping = false;
  final String _aiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _apiKey = const String.fromEnvironment('GROQ_API_KEY');
  final String _modelName = 'llama-3.3-70b-versatile';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage() async {
    final String userText = _messageController.text.trim();
    if (userText.isEmpty) return;

    if (_apiKey.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({"role": "user", "content": userText});
      _isAiTyping = true;
    });
    _scrollToBottom();

    try {
      List<Map<String, String>> conversationPayload = [
        {
          "role": "system",
          "content":
              "You are an expert UK Functional Skills Mathematics Level 1 classroom teacher. Never give raw answers immediately; break calculation steps down elegantly.",
        },
        ..._messages,
      ];

      final response = await http.post(
        Uri.parse(_aiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _modelName,
          "messages": conversationPayload,
          "temperature": 0.5,
          "max_tokens": 800,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String aiReply = data['choices'][0]['message']['content'].trim();
        setState(() {
          _messages.add({"role": "assistant", "content": aiReply});
        });
      }
    } catch (e) {
      /* Handler */
    } finally {
      setState(() {
        _isAiTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Math AI Chat Tutor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 80,
              ), // Clear space for global FAB
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isAiTyping)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "AI Tutor is typing...",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendChatMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask a math question...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _sendChatMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🧮 LIVE SCIENTIFIC CALCULATOR OVERLAY PANEL COMPONENT
class ScientificCalculatorWidget extends StatefulWidget {
  const ScientificCalculatorWidget({super.key});

  @override
  State<ScientificCalculatorWidget> createState() =>
      _ScientificCalculatorWidgetState();
}

class _ScientificCalculatorWidgetState
    extends State<ScientificCalculatorWidget> {
  String _display = "0";
  String _expression = "";

  void _onPressed(String value) {
    setState(() {
      if (value == "C") {
        _display = "0";
        _expression = "";
      } else if (value == "=") {
        _evaluateExpression();
      } else if (value == "√" ||
          value == "sin" ||
          value == "cos" ||
          value == "tan" ||
          value == "log" ||
          value == "ln") {
        _expression += "$value(";
        _display = _expression;
      } else {
        if (_display == "0") {
          _display = value;
          _expression = value;
        } else {
          _display += value;
          _expression += value;
        }
      }
    });
  }

  void _evaluateExpression() {
    try {
      String cleanExpr = _expression;
      // Basic expression cleaner using standard dart math parameters
      cleanExpr = cleanExpr.replaceAll("×", "*").replaceAll("÷", "/");

      // Basic token parser for single standard functions
      double result = 0.0;
      if (cleanExpr.contains("sin(")) {
        double val = double.parse(
          cleanExpr.substring(
            4,
            cleanExpr.length - (cleanExpr.endsWith(")") ? 1 : 0),
          ),
        );
        result = math.sin(val * (math.pi / 180)); // Convert to degrees
      } else if (cleanExpr.contains("cos(")) {
        double val = double.parse(
          cleanExpr.substring(
            4,
            cleanExpr.length - (cleanExpr.endsWith(")") ? 1 : 0),
          ),
        );
        result = math.cos(val * (math.pi / 180));
      } else if (cleanExpr.contains("tan(")) {
        double val = double.parse(
          cleanExpr.substring(
            4,
            cleanExpr.length - (cleanExpr.endsWith(")") ? 1 : 0),
          ),
        );
        result = math.tan(val * (math.pi / 180));
      } else if (cleanExpr.contains("√")) {
        double val = double.parse(
          cleanExpr.substring(
            2,
            cleanExpr.length - (cleanExpr.endsWith(")") ? 1 : 0),
          ),
        );
        result = math.sqrt(val);
      } else if (cleanExpr.contains("log(")) {
        double val = double.parse(
          cleanExpr.substring(
            4,
            cleanExpr.length - (cleanExpr.endsWith(")") ? 1 : 0),
          ),
        );
        result = math.log(val) / math.ln10;
      } else {
        // Fallback for simple operational calculations
        result = _evalSimple(cleanExpr);
      }

      _display = result.toStringAsFixed(result % 1 == 0 ? 0 : 4);
      _expression = _display;
    } catch (e) {
      _display = "Calculation Error";
    }
  }

  double _evalSimple(String expression) {
    // Basic dynamic parser fallback for (+, -, *, /) operations
    List<String> tokens;
    if (expression.contains('+')) {
      tokens = expression.split('+');
      return double.parse(tokens[0].trim()) + double.parse(tokens[1].trim());
    } else if (expression.contains('-')) {
      tokens = expression.split('-');
      return double.parse(tokens[0].trim()) - double.parse(tokens[1].trim());
    } else if (expression.contains('*')) {
      tokens = expression.split('*');
      return double.parse(tokens[0].trim()) * double.parse(tokens[1].trim());
    } else if (expression.contains('/')) {
      tokens = expression.split('/');
      return double.parse(tokens[0].trim()) / double.parse(tokens[1].trim());
    }
    return double.parse(expression);
  }

  Widget _buildButton(String text, {Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey.shade100,
            foregroundColor: textColor ?? Colors.blackde87,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _onPressed(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Scientific Utility Matrix",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _display,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 28,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildButton("sin", color: Colors.deepPurple.shade50),
              _buildButton("cos", color: Colors.deepPurple.shade50),
              _buildButton("tan", color: Colors.deepPurple.shade50),
              _buildButton("√", color: Colors.deepPurple.shade50),
            ],
          ),
          Row(
            children: [
              _buildButton("log", color: Colors.deepPurple.shade50),
              _buildButton("(", color: Colors.grey.shade200),
              _buildButton(")", color: Colors.grey.shade200),
              _buildButton(
                "C",
                color: Colors.red.shade100,
                textColor: Colors.red,
              ),
            ],
          ),
          Row(
            children: [
              _buildButton("7"),
              _buildButton("8"),
              _buildButton("9"),
              _buildButton("÷", color: Colors.orange.shade100),
            ],
          ),
          Row(
            children: [
              _buildButton("4"),
              _buildButton("5"),
              _buildButton("6"),
              _buildButton("×", color: Colors.orange.shade100),
            ],
          ),
          Row(
            children: [
              _buildButton("1"),
              _buildButton("2"),
              _buildButton("3"),
              _buildButton("-", color: Colors.orange.shade100),
            ],
          ),
          Row(
            children: [
              _buildButton("0"),
              _buildButton("."),
              _buildButton(
                "=",
                color: Colors.green.shade200,
                textColor: Colors.green.shade900,
              ),
              _buildButton("+", color: Colors.orange.shade100),
            ],
          ),
        ],
      ),
    );
  }
}
