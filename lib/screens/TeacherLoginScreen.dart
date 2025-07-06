import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:future_app/screens/welcome_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ====================== Teacher Login Screen ======================
class TeacherLoginScreen extends StatefulWidget {
  static const String screenRoute = 'TeacherLoginScreen';
  const TeacherLoginScreen({Key? key}) : super(key: key);

  @override
  _TeacherLoginScreenState createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _stayLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('teacher_saved_email');
    final stayLoggedIn = prefs.getBool('teacher_stay_logged_in') ?? false;

    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _stayLoggedIn = stayLoggedIn;
      });
    }
  }

  bool _isValidTeacherEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9_.+-]+@school\.com$');
    return regex.hasMatch(email);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!_isValidTeacherEmail(email)) {
      _showError(
          'You are not authorized as a teacher!\nOnly @school.com emails allowed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // التصحيح: signInWithEmailAndPassword بدلاً من simInWithEmailAndPassword
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Save credentials if "Stay logged in" is checked
        final prefs = await SharedPreferences.getInstance();
        if (_stayLoggedIn) {
          // التصحيح: _stayLoggedIn بدلاً من .stayloggedIn
          await prefs.setString('teacher_saved_email', email);
          await prefs.setBool('teacher_stay_logged_in', true);
        } else {
          // التصحيح: استخدام نفس اسم المفتاح
          await prefs.remove('teacher_saved_email');
          await prefs.remove('teacher_stay_logged_in');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SelectChildScreen(
              teacherId: userCredential.user!.uid,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e.code);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Function to handle password reset for teachers
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (!_isValidTeacherEmail(email)) {
      _showError('Only @school.com emails allowed for teachers');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset Sent'),
          content: Text(
            'A password reset link has been sent to $email.\n'
            'Please check your inbox and follow the instructions.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No teacher account found with this email';
          break;
        default:
          errorMessage = 'Error sending reset email: ${e.message}';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An unexpected error occurred');
    }
  }

  void _handleAuthError(String code) {
    String message;
    switch (code) {
      case 'invalid-email':
        message = 'Invalid email format';
        break;
      case 'user-not-found':
        message = 'This email is not registered as a teacher';
        break;
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      default:
        message = 'Authentication error';
    }
    _showError(message);
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text("Teacher Sign in"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20), // إضافة مسافة من الأعلى
              Column(
                children: [
                  Container(
                    height: 270,
                    child: Image.asset('images/teacher.png'),
                  ),
                  Text(
                    'Welcome, Our Wonderful Teacher🎉',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo,
                    ),
                  ),
                  Text(
                    'Please Signin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: _passwordInputDecoration('Password'),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 10),
              // Row for "Stay logged in" and "Forgot password" - FIXED
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _stayLoggedIn,
                          onChanged: (value) {
                            setState(() {
                              _stayLoggedIn = value!;
                            });
                          },
                          activeColor: Colors.blue[700],
                        ),
                        Flexible(
                          child: const Text(
                            'Stay logged in',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20), // إضافة مسافة من الأسفل
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    );
  }

  InputDecoration _passwordInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }
}

// ====================== Select Child Screen ======================
class SelectChildScreen extends StatefulWidget {
  final String teacherId;
  const SelectChildScreen({Key? key, required this.teacherId})
      : super(key: key);

  @override
  _SelectChildScreenState createState() => _SelectChildScreenState();
}

class _SelectChildScreenState extends State<SelectChildScreen> {
  final _dbRef = FirebaseDatabase.instance.ref('children');
  bool _isLoading = true;
  List<MapEntry<String, Map<dynamic, dynamic>>> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _dbRef.get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _children = data.entries
              .map((entry) => MapEntry(
                  entry.key.toString(), entry.value as Map<dynamic, dynamic>))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No children found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToChildScreen(
      String childKey, Map<dynamic, dynamic> childData) {
    if (childData['questions'] != null) {
      childData['questions'] = Map<String, String>.from(childData['questions']);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditChildScreen(
          childId: childKey,
          childData: childData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Child'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? const Center(child: Text('No children available'))
              : ListView.builder(
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final childKey = _children[index].key;
                    final childData = _children[index].value;

                    //specific color for each child
                    final colorIndex = index % 5;
                    Color textColor;

                    switch (colorIndex) {
                      case 0:
                        textColor = Colors.blue[800]!;
                        break;
                      case 1:
                        textColor = Colors.purple[800]!;
                        break;
                      case 2:
                        textColor = Colors.teal[800]!;
                        break;
                      case 3:
                        textColor = Colors.orange[800]!;
                        break;
                      case 4:
                        textColor = Colors.red[800]!;
                        break;
                      default:
                        textColor = Colors.black;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          childData['name']?.toString() ?? 'Unnamed Child',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        onTap: () =>
                            _navigateToChildScreen(childKey, childData),
                      ),
                    );
                  },
                ),
    );
  }
}

// ====================== Edit Child Screen ======================
class EditChildScreen extends StatefulWidget {
  final String childId;
  final Map<dynamic, dynamic> childData;

  const EditChildScreen({
    Key? key,
    required this.childId,
    required this.childData,
  }) : super(key: key);

  @override
  _EditChildScreenState createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  final _dbRef = FirebaseDatabase.instance.ref('children');

  // Controllers for Questions
  late Map<String, TextEditingController> _questionControllers = {};
  int _questionCounter = 1;
  final TextEditingController _newQuestionController = TextEditingController();

  // Controllers for Skills
  late Map<String, TextEditingController> _skillsControllers = {};
  int _skillsCounter = 1;
  final TextEditingController _newSkillController = TextEditingController();

  // Controllers for Progress Data
  late Map<String, TextEditingController> _progressDataControllers = {};
  int _progressDataCounter = 1;
  final TextEditingController _newProgressDataController =
      TextEditingController();

  // Basic field controllers
  late TextEditingController _nameController;
  late TextEditingController _performanceController;
  late TextEditingController _commentsController;
  late TextEditingController _examsController;

  // Delete functions
  void _deleteQuestion(String key) async {
    final shouldDelete = await _showDeleteConfirmation('question');
    if (shouldDelete == true) {
      setState(() {
        _questionControllers.remove(key);
      });
      _showSuccessMessage('Question deleted successfully🎉');
    }
  }

  void _deleteSkill(String key) async {
    final shouldDelete = await _showDeleteConfirmation('skill');
    if (shouldDelete == true) {
      setState(() {
        _skillsControllers.remove(key);
      });
      _showSuccessMessage('Skill deleted successfully🎉');
    }
  }

  void _deleteProgressData(String key) async {
    final shouldDelete = await _showDeleteConfirmation('progress data');
    if (shouldDelete == true) {
      setState(() {
        _progressDataControllers.remove(key);
      });
      _showSuccessMessage('Progress data deleted successfully🎉');
    }
  }

  // Helper function for delete confirmation
  Future<bool?> _showDeleteConfirmation(String itemType) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you really want to delete this $itemType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Helper function for success messages
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message - DO NOT FORGET TO PRESS SAVE'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Add new items functions
  void _addNewQuestion() {
    String newQuestion = _newQuestionController.text.trim();
    if (newQuestion.isEmpty) return;

    String newKey = 'q${_questionCounter++}';
    setState(() {
      _questionControllers[newKey] = TextEditingController(text: newQuestion);
    });
    _newQuestionController.clear();
    _showAddSuccessMessage('Question');
  }

  void _addNewSkill() {
    String newSkill = _newSkillController.text.trim();
    if (newSkill.isEmpty) return;

    String newKey = 's${_skillsCounter++}';
    setState(() {
      _skillsControllers[newKey] = TextEditingController(text: newSkill);
    });
    _newSkillController.clear();
    _showAddSuccessMessage('Skill');
  }

  void _addNewProgressData() {
    String newProgressData = _newProgressDataController.text.trim();
    if (newProgressData.isEmpty) return;

    String newKey = 'p${_progressDataCounter++}';
    setState(() {
      _progressDataControllers[newKey] =
          TextEditingController(text: newProgressData);
    });
    _newProgressDataController.clear();
    _showAddSuccessMessage('Progress data');
  }

  // Helper function for add success messages
  void _showAddSuccessMessage(String itemType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemType added successfully 🎉'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _updateChild() async {
    try {
      // Check for duplicate questions
      Map<String, String> questionValues = {};
      List<String> duplicates = [];

      _questionControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          String normalizedText = controller.text.trim().toLowerCase();

          if (questionValues.containsValue(normalizedText)) {
            duplicates.add(controller.text);
          } else {
            questionValues[key] = normalizedText;
          }
        }
      });

      if (duplicates.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Duplicate questions found: ${duplicates.join(", ")}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Prepare data for Firebase
      Map<String, dynamic> updatedQuestions = {};
      _questionControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          updatedQuestions[key] = controller.text;
        }
      });

      Map<String, dynamic> updatedSkills = {};
      _skillsControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          updatedSkills[key] = controller.text;
        }
      });

      Map<String, dynamic> updatedProgressData = {};
      _progressDataControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          updatedProgressData[key] = controller.text;
        }
      });

      await _dbRef.child(widget.childId).update({
        'name': _nameController.text,
        'exams': _examsController.text,
        'comments': _commentsController.text,
        'performance': _performanceController.text,
        'skills': updatedSkills.isEmpty ? null : updatedSkills,
        'progressData':
            updatedProgressData.isEmpty ? null : updatedProgressData,
        'questions': updatedQuestions.isEmpty ? null : updatedQuestions,
        'last_updated': ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated successfully 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Duplicate check functions
  bool _isQuestionDuplicate(String currentKey, String questionText) {
    return _isDuplicate(_questionControllers, currentKey, questionText);
  }

  bool _isSkillDuplicate(String currentKey, String skillText) {
    return _isDuplicate(_skillsControllers, currentKey, skillText);
  }

  bool _isProgressDataDuplicate(String currentKey, String progressText) {
    return _isDuplicate(_progressDataControllers, currentKey, progressText);
  }

  bool _isDuplicate(Map<String, TextEditingController> controllers,
      String currentKey, String text) {
    if (text.isEmpty) return false;
    for (var entry in controllers.entries) {
      String key = entry.key;
      String controllerText = entry.value.text.trim().toLowerCase();
      if (key != currentKey && controllerText == text.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize basic controllers
    _nameController =
        TextEditingController(text: widget.childData['name']?.toString() ?? '');
    _performanceController = TextEditingController(
        text: widget.childData['performance']?.toString() ?? '');
    _commentsController = TextEditingController(
        text: widget.childData['comments']?.toString() ?? '');
    _examsController = TextEditingController(
        text: widget.childData['exams']?.toString() ?? '');

    // Initialize Questions controllers
    final questions =
        widget.childData['questions'] as Map<dynamic, dynamic>? ?? {};
    _questionControllers = {};
    questions.forEach((key, value) {
      final String stringKey = key.toString();
      _questionControllers[stringKey] =
          TextEditingController(text: value.toString());
      final keyNumber = int.tryParse(stringKey.substring(1)) ?? 0;
      if (keyNumber >= _questionCounter) {
        _questionCounter = keyNumber + 1;
      }
    });

    // Initialize Skills controllers - Handle both old string format and new map format
    final skillsData = widget.childData['skills'];
    _skillsControllers = {};
    if (skillsData is String && skillsData.isNotEmpty) {
      // Convert old string format to new map format
      _skillsControllers['s1'] = TextEditingController(text: skillsData);
      _skillsCounter = 2;
    } else if (skillsData is Map<dynamic, dynamic>) {
      // Use new map format
      skillsData.forEach((key, value) {
        final String stringKey = key.toString();
        _skillsControllers[stringKey] =
            TextEditingController(text: value.toString());
        final keyNumber = int.tryParse(stringKey.substring(1)) ?? 0;
        if (keyNumber >= _skillsCounter) {
          _skillsCounter = keyNumber + 1;
        }
      });
    }

    // Initialize Progress Data controllers - Handle both old string format and new map format
    final progressDataData = widget.childData['progressData'];
    _progressDataControllers = {};
    if (progressDataData is String && progressDataData.isNotEmpty) {
      // Convert old string format to new map format
      _progressDataControllers['p1'] =
          TextEditingController(text: progressDataData);
      _progressDataCounter = 2;
    } else if (progressDataData is Map<dynamic, dynamic>) {
      // Use new map format
      progressDataData.forEach((key, value) {
        final String stringKey = key.toString();
        _progressDataControllers[stringKey] =
            TextEditingController(text: value.toString());
        final keyNumber = int.tryParse(stringKey.substring(1)) ?? 0;
        if (keyNumber >= _progressDataCounter) {
          _progressDataCounter = keyNumber + 1;
        }
      });
    }
  }

  // Widget builders for dynamic lists
  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Questions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newQuestionController,
                decoration: const InputDecoration(
                  labelText: 'New Question',
                  hintText: 'Type a new question here',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addNewQuestion,
              tooltip: 'Add question',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildDynamicList(_questionControllers, 'Question', _deleteQuestion,
            _isQuestionDuplicate),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newSkillController,
                decoration: const InputDecoration(
                  labelText: 'New Skill',
                  hintText: 'Type a new skill here',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addNewSkill,
              tooltip: 'Add skill',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildDynamicList(
            _skillsControllers, 'Skill', _deleteSkill, _isSkillDuplicate),
      ],
    );
  }

  Widget _buildProgressDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progress Data:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newProgressDataController,
                decoration: const InputDecoration(
                  labelText: 'New Progress Data',
                  hintText: 'Type new progress data here',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addNewProgressData,
              tooltip: 'Add progress data',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildDynamicList(_progressDataControllers, 'Progress Data',
            _deleteProgressData, _isProgressDataDuplicate),
      ],
    );
  }

  Widget _buildDynamicList(
    Map<String, TextEditingController> controllers,
    String itemType,
    Function(String) deleteFunction,
    bool Function(String, String) duplicateCheck,
  ) {
    if (controllers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No ${itemType.toLowerCase()}s yet. Tap the + button to add a ${itemType.toLowerCase()}.',
          style: const TextStyle(color: Colors.blueGrey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controllers.length,
      itemBuilder: (context, index) {
        final key = controllers.keys.elementAt(index);
        final controller = controllers[key]!;
        final isEmpty = controller.text.isEmpty;
        final isDuplicate = duplicateCheck(key, controller.text);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey(key),
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: '$itemType ${key.substring(1)}',
                    border: const OutlineInputBorder(),
                    errorText: isEmpty
                        ? 'Please fill this ${itemType.toLowerCase()}'
                        : isDuplicate
                            ? 'This ${itemType.toLowerCase()} already exists'
                            : null,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  maxLines: 2,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteFunction(key),
                tooltip: 'Delete ${itemType.toLowerCase()}',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text("Edit Child Data"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, WelcomeScreen.screenRoute),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _performanceController,
                decoration: const InputDecoration(labelText: 'Performance'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _examsController,
                decoration: const InputDecoration(labelText: 'Exams'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentsController,
                decoration: const InputDecoration(labelText: 'Comments'),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              _buildSkillsSection(),
              const SizedBox(height: 30),
              _buildProgressDataSection(),
              const SizedBox(height: 30),
              _buildQuestionsSection(),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: _updateChild,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
