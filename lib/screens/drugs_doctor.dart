import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const storage = FlutterSecureStorage();

class MedicineListPage extends StatefulWidget {
  final String patientId;
  const MedicineListPage({Key? key, required this.patientId}) : super(key: key);
  @override
  _MedicineListPageState createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  String? userId;
  List<Map<String, dynamic>> drugs = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final TextEditingController _drugNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String? _selectedDrugType;
  bool _isTemporary = false;
  //bool _isActive = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    userId =widget.patientId;
    if (userId != null) {
      _fetchDrugs();
    }
  }

  Future<void> _fetchDrugs() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/getUserDrugs'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> fetchedDrugs = data['drugs'];

        List<Map<String, dynamic>> drugDetailsList = [];

        for (var drug in fetchedDrugs) {
          final drugId = drug['drug'];

          final drugDetailsResponse = await http.get(
            Uri.parse('${ApiConstants.baseUrl}/drugs/$drugId'),
          );

          if (drugDetailsResponse.statusCode == 200) {
            final drugData = jsonDecode(drugDetailsResponse.body);

            final drugDetails = drugData['drug']['details'];

            final details = drugDetails.isNotEmpty ? drugDetails[0] : null;

            var endDateStr = drug['usageEndDate'];
          final startDateStr = drug['usageStartDate'];
          DateTime? startDate = startDateStr != null
              ? DateTime.tryParse(startDateStr)
              : null;

           endDateStr = drug['usageEndDate'];
          DateTime? endDate = endDateStr != null
              ? DateTime.tryParse(endDateStr)
              : null;
            bool isExpired = false;

            if (endDateStr != null) {
              endDate = DateTime.tryParse(endDateStr);
              if (endDate != null) {
                isExpired = endDate.isBefore(DateTime.now());
              }
            }

            drugDetailsList.add({
              'name': drugData['drug']['Drugname'] ?? 'Unknown',
              'barcode': drugData['Barcode'] ?? 'Unknown',
              'use': details?['Use'] ?? 'No use information',
              'dose': details?['Dose'] ?? 'No dose information',
              'time': details?['Time'] ?? 'No timing information',
              'notes': details?['Notes'] ?? 'No additional notes',
              'isPermanent': drug['isPermanent'],
              'startDate': startDate,
              'endDate': endDate,
            
              'isExpired': isExpired,
            });
          } else {
            _showMessage('Failed to fetch drug details for ID $drugId');
          }
        }

        setState(() {
          drugs = drugDetailsList;
        });
      } else {
        _showMessage('Failed to fetch drugs: ${response.body}');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }


  Future<void> _selectDateTime(BuildContext context,
      TextEditingController controller, bool isStartDate) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date',
              style: TextStyle(color: Color(0xff613089))),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _selectedDate ?? DateTime.now(),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;

                        if (isStartDate) {
                          controller.text =
                              "${selectedDay.toLocal()}".split(' ')[0];
                        } else {
                          controller.text =
                              "${selectedDay.toLocal()}".split(' ')[0];
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color(0xffb41391),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xff613089),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle:
                          TextStyle(color: Color(0xff613089), fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _addDrug(String drugName, bool isTemporary, String? startDate,
      String? endDate) async {
    try {
      final requestBody = {
        'drugName': drugName,
        'isPermanent': !isTemporary,
        'usageStartDate': isTemporary ? startDate : null,
        'usageEndDate': isTemporary ? endDate : null,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/adddrugs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        _showMessage('Drug added successfully');
        _fetchDrugs(); 
      } else {
        _showMessage('Failed to add drug: ${response.body}');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }


  Future<void> _deleteDrug(String drugName) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/deletedrugs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'drugName': drugName}),
      );
      if (response.statusCode == 200) {
        _showMessage('deleted successfully $drugName');
        _fetchDrugs();
      } else {
        _showMessage('Failed to delete drug: ${response.body}');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }


  void _showAddDrugDialog() {
    _drugNameController.clear();
    _startDateController.clear();
    _endDateController.clear();

    _selectedDrugType = 'Permanent';
    _isTemporary = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;

            double dialogWidth = width > 600 ? 400 : width * 0.85;
            double dialogHeight = height > 600 ? 420 : height * 40;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              backgroundColor: Colors.white,
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Color(0xff613089),
                            size: 40,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Add a New Drug',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff613089),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _drugNameController,
                        decoration: InputDecoration(
                          labelText: 'Drug name',
                          labelStyle: const TextStyle(color: Color(0xff613089)),
                          prefixIcon: const Icon(FontAwesomeIcons.capsules,
                              color: Color(0xff613089)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 12.0),
                          filled: true,
                          fillColor: const Color(0xFFF3F3F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                                color: Color(0xff613089), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                                color: Color(0xff613089), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.grey, width: 1.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedDrugType,
                        items: ['Permanent', 'Temporary']
                            .map((type) => DropdownMenuItem(
                                value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDrugType = value!;
                            _isTemporary = _selectedDrugType == 'Temporary';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Drug Type',
                          labelStyle: const TextStyle(color: Color(0xff613089)),
                          prefixIcon: const Icon(Icons.category,
                              color: Color(0xff613089)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 12.0),
                          filled: true,
                          fillColor: const Color(0xFFF3F3F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                                color: Color(0xff613089), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                                color: Color(0xff613089), width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      if (_isTemporary)
                        Column(
                          children: [
                            TextFormField(
                              controller: _startDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                labelStyle:
                                    const TextStyle(color: Color(0xff613089)),
                                prefixIcon: const Icon(Icons.calendar_today,
                                    color: Color(0xff613089)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 12.0),
                                filled: true,
                                fillColor: const Color(0xFFF3F3F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff613089), width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff613089), width: 2.0),
                                ),
                              ),
                              onTap: () async {
                                await _selectDateTime(
                                    context, _startDateController, true);
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _endDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                labelStyle:
                                    const TextStyle(color: Color(0xff613089)),
                                prefixIcon: const Icon(Icons.calendar_today,
                                    color: Color(0xff613089)),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 12.0),
                                filled: true,
                                fillColor: const Color(0xFFF3F3F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff613089), width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xff613089), width: 2.0),
                                ),
                              ),
                              onTap: () async {
                                await _selectDateTime(
                                    context, _endDateController, false);
                              },
                            ),
                          ],
                        ),

                      const SizedBox(height: 16.0),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _drugNameController.clear();
                              _startDateController.clear();
                              _endDateController.clear();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xff613089),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_drugNameController.text.isNotEmpty) {
                                _addDrug(
                                    _drugNameController.text,
                                    _isTemporary,
                                    _startDateController.text,
                                    _endDateController.text);
                                _drugNameController.clear();
                                _startDateController.clear();
                                _endDateController.clear();
                                Navigator.pop(context);
                              } else {
                                _showMessage('Please enter a drug name');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff613089),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                            ),
                            child: const Text(
                              'Add Drug',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDrugDetailsDialog(Map<String, dynamic> drug) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            drug['name'] ?? 'Unknown Drug',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff613089),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.description, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Use: ${drug['use']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.medication, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Dose: ${drug['dose']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Time: ${drug['time']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.note, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Notes: ${drug['notes']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xff613089),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


Widget buildSearchSection() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFF6A4C9C), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6A4C9C), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    _fetchDrugs();
                    return const Iterable<String>.empty();
                  }
                  return drugs.map((drug) => drug['name'] as String).where(
                      (name) => name
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selectedDrug) {
                  setState(() {
                    searchController.text = selectedDrug;
                    drugs = drugs
                        .where((drug) =>
                            drug['name']!.toLowerCase() ==
                            selectedDrug.toLowerCase())
                        .toList();
                  });
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController controller,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  searchController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search for drugs...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


//////////////////////////////



@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF2F5FF),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF2F5FF),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Patient Medicines',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff613089),
          letterSpacing: 1.5,
        ),
      ),
      automaticallyImplyLeading: !kIsWeb,
      leading: kIsWeb
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF613089)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: kIsWeb ? 900 : double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildSearchSection(),

              const SizedBox(height: 16),

              drugs.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: drugs.length,
                        itemBuilder: (context, index) {
                          final drug = drugs[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Color(0xff613089),
                                    child: Icon(
                                     FontAwesomeIcons.capsules,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drug['name'] ?? 'Unknown Drug',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff613089),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Dose: ${drug['dose']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (drug['startDate'] != null)
                                          Text(
                                            'Start Date: ${DateFormat('dd/MM/yyyy').format(drug['startDate'])}',
                                            style: const TextStyle(
                                                fontSize: 14, color: Colors.black87),
                                          ),
                                        if (drug['endDate'] != null)
                                          GestureDetector(
                                            onTap: () => _editDrugEndDate(drug, index),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'End Date: ${DateFormat('dd/MM/yyyy').format(drug['endDate'])}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.edit, color: Color(0xff613089), size: 16),
                                              ],
                                            ),
                                          ),
                                        if (drug['endDate'] == null && drug['startDate'] == null)
                                          const Text(
                                            'Its a permanent drug.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        const SizedBox(height: 8),
                                        if (drug['endDate'] != null && drug['startDate'] != null)
                                          const Text(
                                            'Tap on the end date to change it.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          drug['isExpired'] ? 'Expired' : 'Active',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: drug['isExpired']
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info,
                                          color: Color(0xff613089),
                                        ),
                                        onPressed: () =>
                                            _showDrugDetailsDialog(drug),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Color(0xff613089),
                                        ),
                                        onPressed: () =>
                                            _deleteDrug(drug['name'] ?? ''),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        'No medicines available.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddDrugDialog,
      backgroundColor: const Color(0xff613089),
      child: const Icon(Icons.add),
    ),
  );
}





void _editDrugEndDate(Map<String, dynamic> drug, int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select End Date', style: TextStyle(color: Color(0xff613089))),
        content: SizedBox(
          width: 300,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: drug['endDate'] ?? DateTime.now(),
                  selectedDayPredicate: (day) {
                    return isSameDay(day, drug['endDate']);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      drug['endDate'] = selectedDay;
                      drug['isExpired'] = selectedDay.isBefore(DateTime.now());
                    });
                    _updateDrugInDatabase(widget.patientId, drug['name'], selectedDay);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xffb41391),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xff613089),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(color: Color(0xff613089), fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



Future<void> _updateDrugInDatabase(String userId, String drugName, DateTime newEndDate) async {
  final url = '${ApiConstants.baseUrl}/users/$userId/updateDrugEndDate'; 
print('innnnnnnnnnnnnnn');
  try {
    final formattedDate = '${newEndDate.year}-${newEndDate.month.toString().padLeft(2, '0')}-${newEndDate.day.toString().padLeft(2, '0')}';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'drugName': drugName,
        'newEndDate': formattedDate,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Drug end date updated successfully: ${responseData['message']}');
    } else {
      final responseData = json.decode(response.body);
      print('Error: ${responseData['message']}');
    }
  } catch (error) {
    print('Error: $error');
  }
}


}
