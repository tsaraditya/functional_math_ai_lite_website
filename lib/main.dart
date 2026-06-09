import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';
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

// 👑 GLOBAL STATE NAVIGATION ROUTER LIST - Updated to include Chat!
final List<Widget> _screens = [
  const SyllabusScreen(),
  const QuizScreen(),
  const ChatBotScreen(), // 🌟 Added chatbot screen instance inside the global router
];

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'AI Chat',
          ), // 🌟 Interactive Chat selector tab
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
              padding: const EdgeInsets.all(16.0),
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
      final random = Random();
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
      "commercial real estate leasing, apparel inventory lines, and clinic patient data tracking",
      "maritime cargo networks, audio theatre engineering, and personal wealth investment blueprints",
    ];
    final String freshContextSeed =
        scenarios[Random().nextInt(scenarios.length)];

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
                  "You are an official UK Functional Skills Mathematics Level 1 exam writer. Return a valid json object containing a single root key named 'questions' which maps directly to an array of exactly 17 objects. Each question object must contain exactly these keys: 'id' (int), 'topic' (string), 'question' (string), and 'answer' (string). CRITICAL: Use only single quotes (') inside the text values; never use unescaped double quotes (\") which destroy JSON encoding structural arrays. Settings seed context backdrop environment: $freshContextSeed.",
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server Error: Unable to complete cloud request."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network Pipeline Disruption. Check internet access."),
        ),
      );
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
      htmlContent.writeln("<html><body>");
      htmlContent.writeln(
        "<h1 style='color:#4A148C;font-family:Arial;'>Functional Maths Level 1 - Professional Examination</h1>",
      );
      htmlContent.writeln(
        "<p style='font-size:12px;color:#555;'>On-Demand Assessment Matrix</p><hr/>",
      );

      for (var q in _aiGeneratedExamQuestions) {
        htmlContent.writeln(
          "<p style='font-family:Arial;font-size:14px;'><b>Q${q['id']}. [${q['topic'] ?? 'Maths'}]</b></p>",
        );
        htmlContent.writeln(
          "<p style='font-family:Arial;font-size:14px;margin-left:15px;'>${q['question'] ?? ''}</p>",
        );
        if (includeAnswersOnly) {
          htmlContent.writeln(
            "<p style='font-family:Arial;font-size:14px;color:green;margin-left:15px;'><b>Correct Answer Matrix:</b> ${q['answer'] ?? ''}</p>",
          );
        } else {
          htmlContent.writeln(
            "<p style='font-family:Arial;font-size:14px;margin-left:15px;'>Answer Specification: _______________________</p>",
          );
        }
        htmlContent.writeln("<br/>");
      }
      htmlContent.writeln("</body></html>");

      // 🌐 WEB ROUTINE DETECTOR: Bypasses Android paths to drop files cleanly via the browser engine
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

      // 📱 NATIVE PHONE DETECTOR: Runs the traditional cache sandbox save if compiled onto an Android device
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$filename');
      await file.writeAsString(htmlContent.toString());

      setState(() {
        _exportStatusMessage = "Launching system share pipeline...";
      });

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/msword')],
        text: includeAnswersOnly
            ? 'Functional Math AI Generated Answers'
            : 'Functional Math AI Generated Exam Paper',
      );

      setState(() {
        _exportStatusMessage = "Document transferred to system engine.";
      });
    } catch (e) {
      setState(() {
        _exportStatusMessage = "Export routine broken.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export execution pipeline error: $e")),
      );
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
                  "You are an experienced, professional Functional Skills classroom mathematics teacher. Your task is to provide an encouraging, highly direct hint to help a struggling student break down a word problem.\n\nCRITICAL TEACHING GUIDELINES:\n1. Break down the scenario into its raw operational steps (e.g., 'First, find the total combined cost by adding the two item amounts together, then divide that result by...').\n2. Use the exact figures, unrounded data variables, and values present in the question to guide your steps. Do not change, round, or alter any numbers unless it is explicitly an estimation question.\n3. DO NOT state or reveal the final calculation outcome or solution string anywhere in your response output.",
            },
            {
              "role": "user",
              "content":
                  "I am stuck on this problem: '${_currentQuestion!['question']}'. Help me understand how to map the operational sequence out step-by-step.",
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
      // Catch context loop
    } finally {
      setState(() {
        _isLoadingHint = false;
      });
    }
  }

  void _showSecurityAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "API Compilation Key Missing. Inject valid token via --dart-define.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
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
                            label: const Text(
                              "Word (Qs Only)",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _exportToWord(true),
                            icon: const Icon(
                              Icons.assignment_turned_in,
                              size: 16,
                            ),
                            label: const Text(
                              "Word (With Ans)",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
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
                        "Command the Cloud AI system to completely write, sequence, and structure a custom 17-question verification test module.",
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateAIExam,
                      icon: const Icon(Icons.cyclone),
                      label: const Text("Generate 17 New Questions & Answers"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

// 🌟 LIVE AI CHATBOT INTERACTIVE TUTORIAL WIDGET
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

    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "API compilation Key Missing. Inject variable token via --dart-define.",
          ),
        ),
      );
      return;
    }

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
              "You are an expert UK Functional Skills Mathematics Level 1 classroom teacher. Your job is to guide students kindly through mathematical processes. Never give the answer immediately; instead, break calculation steps down, prompt the user with questions, explain practical real-world math logic (Area, Money, Fractions, Scale), and keep explanations incredibly clear and accessible.",
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
      } else {
        setState(() {
          _messages.add({
            "role": "assistant",
            "content":
                "Sorry, I hit an internal transmission error. Please try asking again.",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content":
              "Network disruption encountered. Check internet configurations.",
        });
      });
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
              padding: const EdgeInsets.all(16),
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
                "AI Tutor is typing operational sequence...",
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
                      hintText:
                          'Ask a math question (e.g., How do I find a mean average?)...',
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
