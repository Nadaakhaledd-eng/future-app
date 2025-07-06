import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:future_app/widgets/my_button.dart';
import 'package:future_app/screens/welcome_screen.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChildrenScreen extends StatefulWidget {
  static const String screenRoute = 'children_screen';
  const ChildrenScreen({Key? key}) : super(key: key);

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  List<Map<String, dynamic>> _childrenList = [];
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchAllChildrenForCurrentUser();
  }

  Future<void> _fetchAllChildrenForCurrentUser() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No user is currently logged in";
      });
      return;
    }

    final String userId = _currentUser!.uid;
    final String? userEmail = _currentUser.email;

    print("Current user: ${_currentUser.email}, UID: ${_currentUser?.uid}");

    try {
      // First try to find children by parentId
      DataSnapshot parentIdSnapshot = await _databaseReference
          .child('children')
          .orderByChild('parentId')
          .equalTo(userId)
          .get();

      print(
          "Children by parentId: ${parentIdSnapshot.exists}, Value: ${parentIdSnapshot.value}");

      DataSnapshot parentEmailSnapshot = await _databaseReference
          .child('children')
          .orderByChild('parentEmail')
          .equalTo(userEmail)
          .get();

      print(
          "Children by parentEmail: ${parentEmailSnapshot.exists}, Value: ${parentEmailSnapshot.value}");

      List<Map<String, dynamic>> foundChildren =
          _processChildrenSnapshot(parentIdSnapshot);
      print("Found children after parentId query: ${foundChildren.length}");

      List<Map<String, dynamic>> emailChildren =
          _processChildrenSnapshot(parentEmailSnapshot);
      foundChildren.addAll(emailChildren);
      print("Found children after parentEmail query: ${foundChildren.length}");

      // If still no children found, get all children and filter manually
      if (foundChildren.isEmpty) {
        final DataSnapshot childrenSnapshot =
            await _databaseReference.child('children').get();

        if (childrenSnapshot.exists && childrenSnapshot.value != null) {
          final Map<dynamic, dynamic> allChildren =
              childrenSnapshot.value as Map<dynamic, dynamic>;

          allChildren.forEach((childId, childData) {
            if (childData is Map<dynamic, dynamic>) {
              final Map<String, dynamic> convertedChildData =
                  _convertToStringDynamicMap(childData);
              convertedChildData['childId'] = childId.toString();

              bool isRelated = false;

              if (convertedChildData.containsKey('parentId') &&
                  convertedChildData['parentId'] == userId) {
                isRelated = true;
              } else if (userEmail != null &&
                  convertedChildData.containsKey('parentEmail') &&
                  convertedChildData['parentEmail'] == userEmail) {
                isRelated = true;
              } else if (childId.toString() == userId) {
                isRelated = true;
              }

              if (isRelated) {
                foundChildren.add(convertedChildData);
              }
            }
          });
        }
      }

      setState(() {
        _childrenList = foundChildren;
        _isLoading = false;
        _lastUpdated = DateTime.now();
        if (foundChildren.isEmpty) {
          _errorMessage = "No children found associated with your account";
        }
      });
    } catch (error) {
      print("Error fetching children data: $error");
      setState(() {
        _isLoading = false;
        _errorMessage = "Error fetching data: ${error.toString()}";
      });
    }
  }

  List<Map<String, dynamic>> _processChildrenSnapshot(DataSnapshot snapshot) {
    List<Map<String, dynamic>> children = [];

    if (snapshot.exists && snapshot.value != null) {
      final dynamic snapshotValue = snapshot.value;

      if (snapshotValue is Map<dynamic, dynamic>) {
        snapshotValue.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final Map<String, dynamic> childData =
                _convertToStringDynamicMap(value);
            childData['childId'] = key.toString();
            children.add(childData);
          }
        });
      }
    }

    return children;
  }

  Map<String, dynamic> _convertToStringDynamicMap(
      Map<dynamic, dynamic> dynamicMap) {
    Map<String, dynamic> stringMap = {};
    dynamicMap.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        stringMap[key.toString()] = _convertToStringDynamicMap(value);
      } else {
        stringMap[key.toString()] = value;
      }
    });
    return stringMap;
  }

  Future<void> _refreshChildrenData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchAllChildrenForCurrentUser();
  }

  void _showChildDataInDialog(Map<String, dynamic> childData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with child's name
              Center(
                child: Text(
                  '${childData['name'] ?? 'Child'} Information',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Content in a scrollable container
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection('Basic Information', [
                        InfoRow('Name', childData['name'] ?? 'N/A'),
                        InfoRow('ID', childData['id'] ?? 'N/A'),
                        InfoRow(
                            'Parent Email', childData['parentEmail'] ?? 'N/A'),
                        InfoRow(
                          'Last Updated',
                          childData.containsKey('last_updated')
                              ? DateFormat('dd/MM/yyyy hh:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      childData['last_updated'] as int))
                              : 'N/A',
                        ),
                      ]),
                      if (childData.containsKey('performance') &&
                          childData['performance'] != null)
                        _buildInfoSection('Performance', [
                          InfoRow('Score', childData['performance'].toString()),
                        ]),
                      if (childData.containsKey('exams') &&
                          childData['exams'] != null)
                        _buildInfoSection('Exams', [
                          InfoRow('Schedule', childData['exams'].toString()),
                        ]),
                      if (childData.containsKey('comments') &&
                          childData['comments'] != null)
                        _buildInfoSection('Teacher Comments', [
                          InfoRow('Notes', childData['comments'].toString()),
                        ]),
                      if (childData.containsKey('questions') &&
                          childData['questions'] != null)
                        _buildQuestionsSection(childData['questions']),
                      if (childData.containsKey('skills'))
                        _buildSkillsSection(childData['skills']),
                      if (childData.containsKey('progressData'))
                        _buildProgressSection(childData['progressData']),
                      if (childData.containsKey('studyTime') &&
                          childData['studyTime'] != null)
                        _buildStudyTimeSection(childData['studyTime']),
                    ],
                  ),
                ),
              ),
              // Close button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsSection(dynamic questions) {
    List<InfoRow> rows = [];

    if (questions is Map) {
      questions.forEach((key, value) {
        rows.add(InfoRow(key.toString(), value.toString()));
      });
    } else if (questions is String && questions.isNotEmpty) {
      rows.add(InfoRow('Questions', questions));
    }

    return _buildInfoSection('Questions', rows);
  }

  // Build Skills Section - Handle both text and numeric data
  Widget _buildSkillsSection(dynamic skills) {
    if (skills == null) {
      return const SizedBox.shrink();
    }

    List<InfoRow> skillRows = [];
    List<SkillData> skillDataList = [];
    bool hasNumericData = false;

    if (skills is Map) {
      skills.forEach((key, value) {
        String skillName = key.toString();
        String skillValue = value.toString();

        // Add to info rows for text display
        skillRows.add(InfoRow(skillName, skillValue));

        // Try to parse as number for charts
        double? numValue = _tryParseNumber(skillValue);
        if (numValue != null) {
          skillDataList.add(SkillData(skillName, numValue));
          hasNumericData = true;
        }
      });
    } else if (skills is String && skills.isNotEmpty) {
      // Handle old string format
      skillRows.add(InfoRow('Skills', skills));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show text section
        _buildInfoSection('Skills', skillRows),

        // Show chart only if we have numeric data
        if (hasNumericData) ...[
          const SizedBox(height: 20),
          _buildSkillsChart(skillDataList),
        ],
      ],
    );
  }

  // Build Study Time Section - Handle both text and numeric data
  Widget _buildStudyTimeSection(dynamic studyTime) {
    if (studyTime == null) {
      return const SizedBox.shrink();
    }

    List<InfoRow> studyTimeRows = [];
    List<ProgressData> studyTimeDataList = [];
    bool hasNumericData = false;

    if (studyTime is Map) {
      studyTime.forEach((key, value) {
        String studyKey = key.toString();
        String studyValue = value.toString();

        // Add to info rows for text display
        studyTimeRows.add(InfoRow(studyKey, studyValue));

        // Try to parse as number for charts
        double? numValue = _tryParseNumber(studyValue);
        if (numValue != null) {
          studyTimeDataList.add(ProgressData(studyKey, numValue));
          hasNumericData = true;
        }
      });
    } else if (studyTime is String && studyTime.isNotEmpty) {
      // Handle old string format
      studyTimeRows.add(InfoRow('Study Time', studyTime));
    }

    // Sort study time data by date if possible
    if (hasNumericData) {
      studyTimeDataList.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a.date);
          DateTime dateB = DateTime.parse(b.date);
          return dateA.compareTo(dateB);
        } catch (e) {
          return a.date.compareTo(b.date);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show text section
        _buildInfoSection('Study Time', studyTimeRows),

        // Show chart only if we have numeric data
        if (hasNumericData) ...[
          const SizedBox(height: 20),
          _buildStudyTimeChart(studyTimeDataList),
        ],
      ],
    );
  }

// دالة _buildInfoSection المفقودة
  Widget _buildInfoSection(String title, List<InfoRow> rows) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        ...rows.map((row) => _buildInfoRow(row.label, row.value)).toList(),
      ],
    );
  }

//_____________________________________________________________________
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

//_____________________________________________________________________________________
  Widget _buildStudyTimeChart(List<ProgressData> studyTimeDataList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: const Text(
            'Study Time Over Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        Container(
          height: 300,
          padding: const EdgeInsets.only(top: 16),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: 100,
              interval: 10, // كل 10 وحدات
            ),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries>[
              LineSeries<ProgressData, String>(
                dataSource: studyTimeDataList,
                xValueMapper: (ProgressData data, _) => data.date,
                yValueMapper: (ProgressData data, _) => data.value,
                name: 'Study Time',
                markerSettings: const MarkerSettings(isVisible: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Skills Chart Widget
  Widget _buildSkillsChart(List<SkillData> skillDataList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: const Text(
            'Skills Chart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        Container(
          height: 300,
          padding: const EdgeInsets.only(top: 16),
          child: SfCircularChart(
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
            ),
            series: <CircularSeries>[
              PieSeries<SkillData, String>(
                dataSource: skillDataList,
                xValueMapper: (SkillData data, _) => data.name,
                yValueMapper: (SkillData data, _) => data.value,
                dataLabelMapper: (SkillData data, _) =>
                    '${data.name}: ${data.value.toStringAsFixed(1)}',
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

//**************************************************************************** */

  double? _tryParseNumber(String value) {
    try {
      value = value.trim();

      RegExp numberRegex = RegExp(r':\s*(\d+(?:\.\d+)?)');
      Match? match = numberRegex.firstMatch(value);

      if (match != null) {
        return double.tryParse(match.group(1)!);
      }

      RegExp generalNumberRegex = RegExp(r'(\d+(?:\.\d+)?)');
      Match? generalMatch = generalNumberRegex.firstMatch(value);

      if (generalMatch != null) {
        return double.tryParse(generalMatch.group(1)!);
      }

      return double.tryParse(value);
    } catch (e) {
      print("Error parsing number from '$value': $e");
      return null;
    }
  }

  Widget _buildProgressSection(dynamic progressData) {
    if (progressData == null) {
      return const SizedBox.shrink();
    }

    List<InfoRow> progressRows = [];
    List<ProgressData> progressDataList = [];
    bool hasNumericData = false;

    if (progressData is Map) {
      progressData.forEach((key, value) {
        String progressKey = key.toString();
        String progressValue = value.toString();

        progressRows.add(InfoRow(progressKey, progressValue));

        double? numValue = _tryParseNumber(progressValue);
        if (numValue != null) {
          progressDataList.add(ProgressData(progressKey, numValue));
          hasNumericData = true;
          print("Found progress data: $progressKey = $numValue");
        } else {
          print("Could not parse: $progressKey = $progressValue");
        }
      });
    } else if (progressData is String && progressData.isNotEmpty) {
      progressRows.add(InfoRow('Progress Data', progressData));
    }

    if (hasNumericData) {
      progressDataList.sort((a, b) {
        try {
          RegExp dateRegex = RegExp(r'p(\d+)');
          Match? matchA = dateRegex.firstMatch(a.date);
          Match? matchB = dateRegex.firstMatch(b.date);

          if (matchA != null && matchB != null) {
            int numA = int.parse(matchA.group(1)!);
            int numB = int.parse(matchB.group(1)!);
            return numA.compareTo(numB);
          }

          return a.date.compareTo(b.date);
        } catch (e) {
          return a.date.compareTo(b.date);
        }
      });
    }

    print("Progress data list length: ${progressDataList.length}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection('Progress Data', progressRows),
        if (hasNumericData) ...[
          const SizedBox(height: 20),
          _buildProgressChart(progressDataList),
        ] else ...[
          const SizedBox(height: 10),
          const Text(
            'No numeric data available for chart',
            style: TextStyle(color: Colors.orange, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressChart(List<ProgressData> progressDataList) {
    if (progressDataList.isEmpty) {
      return const Center(
        child: Text(
          'No data to display',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: const Text(
            'Student Progress Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              title: AxisTitle(
                text: 'Time Period',
                textStyle: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 14,
                ),
              ),
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: 100,
              interval: 10,
              title: AxisTitle(
                text: 'Progress (%)',
                textStyle: TextStyle(
                  color: Colors.green.shade500,
                  fontSize: 14,
                ),
              ),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              format: 'point.x: point.y%',
            ),
            series: <CartesianSeries>[
              LineSeries<ProgressData, String>(
                dataSource: progressDataList,
                xValueMapper: (ProgressData data, _) => data.date,
                yValueMapper: (ProgressData data, _) => data.value,
                name: 'Progress',
                color: Colors.deepPurple,
                width: 3,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  shape: DataMarkerType.circle,
                  borderWidth: 2,
                  borderColor: Colors.deepOrange,
                ),
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.top,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(
        context, WelcomeScreen.screenRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Children Information'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshChildrenData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _childrenList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      MyButton(
                        color: Colors.deepPurple,
                        title: 'Refresh',
                        onPressed: _refreshChildrenData,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Last updated: ${DateFormat('dd/MM/yyyy hh:mm a').format(_lastUpdated!)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _childrenList.length,
                        itemBuilder: (context, index) {
                          final child = _childrenList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                child: Text(
                                  (child['name'] ?? 'Child')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                child['name'] ?? 'Unknown Child',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (child.containsKey('id'))
                                    Text('ID: ${child['id']}'),
                                  if (child.containsKey('parentEmail'))
                                    Text('Parent: ${child['parentEmail']}'),
                                  if (child.containsKey('last_updated'))
                                    Text(
                                      'Updated: ${DateFormat('dd/MM/yyyy').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                          child['last_updated'] as int,
                                        ),
                                      )}',
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showChildDataInDialog(child),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// Helper classes for chart data
class SkillData {
  final String name;
  final double value;

  SkillData(this.name, this.value);
}

class ProgressData {
  final String date;
  final double value;

  ProgressData(this.date, this.value);
}

class InfoRow {
  final String label;
  final String value;

  InfoRow(this.label, this.value);
}
