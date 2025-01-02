import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/notification_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'drugs_doctor.dart';
import 'lab_tests_doctor.dart';
import 'med_history_doctor.dart';
import 'med_notes_doctor.dart';
import 'treatments_doctor.dart';
import 'diabetes_doctor.dart';
import 'chat_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'pressure_doctor.dart';


const storage = FlutterSecureStorage();


class PatientViewPage extends StatefulWidget {
    final String patientId;
  const PatientViewPage({Key? key, required this.patientId}) : super(key: key);
  @override
  
  _PatientViewPageState createState() => _PatientViewPageState();
}


class _PatientViewPageState extends State<PatientViewPage> {
String username = 'Loading..'; 
String gender = 'Unknown';
String bloodType = 'Unknown'; 
int age = 0; 
String phoneNumber = 'N/A'; 
String lastDonationDate = 'N/A'; 
String? base64Image ='';
String idNumber ='';
String email ='';
String location ='';
String userid ='';
bool isallawod= false;
var doctorId ='';
List<String> chronicDiseases = []; 
List<String> allergies = []; 
bool isLoading = true; 
Map<String, bool> sectionExpanded = {
    'personalInfo': false,
    'medicalInfo': false,
  };

  List<DateTime> donationDates = [
    
  ];
   bool showAllDonations = false;



  @override
  void initState() {
    super.initState();
    getDoctorId();
    isPatientAssignedToDoctor();
    fetchUserInfo();
    _loadDonationDates();
  }



  // Toggle function to expand/collapse sections
  void toggleSection(String sectionKey) {
    setState(() {
      sectionExpanded[sectionKey] = !sectionExpanded[sectionKey]!;
    });
  }


Future<void> getDoctorId() async {
   doctorId = (await storage.read(key: 'userid'))!;
}



Future<void>  isPatientAssignedToDoctor() async {
  String patientId = widget.patientId;
  try {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/doctorsusers/relations/patient/$patientId'));
    if (response.statusCode == 200) {
      List<dynamic> relations = json.decode(response.body);
                print(doctorId);

      for (var relation in relations) {
        print(relation['doctorId']['_id']);

        if (relation['doctorId']['_id'] == doctorId) {
          isallawod = true; 
          
        }
      }
     // isallawod = false;
    } else {
      throw Exception('field ');
    }
  } catch (error) {
    print("Error fetching relations: $error");
    isallawod = false; 
  }
}



Future<void> fetchUserInfo() async {
  isPatientAssignedToDoctor();
  final String  userid =  widget.patientId;
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userid'), 
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        username = data['username'] ?? 'Unknown';
        gender = data['medicalCard']?['publicData']?['gender'] ?? 'Unknown';
        bloodType = data['medicalCard']?['publicData']?['bloodType'] ?? 'Unknown';
        age = data['medicalCard']?['publicData']?['age'] ?? 0;
        phoneNumber = data['medicalCard']?['publicData']?['phoneNumber'] ?? 'N/A';


 idNumber =data['medicalCard']?['publicData']?['idNumber'] ?? 'Unknown';
 email =data['email']?? 'Unknown';
 location =data['location']?? 'Unknown';
userid ==data['_id'];
        lastDonationDate =
            data['medicalCard']?['publicData']?['lastBloodDonationDate'] ?? 'N/A';
        chronicDiseases = List<String>.from(
          data['medicalCard']?['publicData']?['chronicConditions'] ?? [],
        );
        allergies = List<String>.from(
          data['medicalCard']?['publicData']?['allergies'] ?? [],
        );
        base64Image=data['medicalCard']?['publicData']?['image'] ?? 'Unknown';
        isLoading = false; 
      });
    } else {
      _showMessage('Failed to load user information');
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    _showMessage('Error: $e');
    setState(() {
      isLoading = false;
    });
  }
}
 void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }




Widget buildPatientInfo() {
  return Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xff613089),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
           _buildUserAvatar(),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
Row(
  children: [
    Text(
      username,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
          ),
        ],
      ),
    ),
    const Spacer(),
    IconButton(
      icon: const Icon(
        Icons.chat,
        color: Color.fromARGB(255, 248, 247, 249),
        size: 30,
      ),
      onPressed: () async {
        final String id = widget.patientId;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverId: id,
              name: username,
            ),
          ),
        );
      },
    ),
  ],
),

                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.person, size: 20, color: Colors.white70),
                        ),
                        TextSpan(text: '  Age: $age | Gender: $gender'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.bloodtype, size: 20, color: Colors.white70),
                        ),
                        TextSpan(text: '  Blood Type: $bloodType'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}





  // Widget for personal information box
Widget buildPersonalInfoBox() {
  return GestureDetector(
    onTap: () => toggleSection('personalInfo'),
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
     
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xff613089)),
              const SizedBox(width: 10),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff613089),
                ),
              ),
              const Spacer(),
              Icon(
                sectionExpanded['personalInfo']!
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                color: const Color(0xff613089),
              ),
            ],
          ),
          const SizedBox(height: 15),

          if (sectionExpanded['personalInfo']!) ...[
            _buildInfoRow(Icons.badge, 'ID Number', idNumber),
            _buildInfoRow(Icons.email, 'Email', email),
            _buildInfoRow(Icons.location_on, 'Location', location),
            _buildInfoRow(Icons.phone, 'Phone', phoneNumber),
          ],
        ],
      ),
    ),
  );
}



Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xff613089)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}



Image buildImageFromBase64(String? base64Image) {
  try {
    if (base64Image == null || base64Image.isEmpty) {
      return Image.asset('assets/images/default_person.jpg'); 
    }

    final bytes = base64Decode(base64Image);
    print("Decoded bytes length: ${bytes.length}");

    return Image.memory(bytes);
  } catch (e) {
  
    print("Error decoding image: $e");
    return Image.asset('assets/images/default_person.jpg');
  }
}






Widget _buildUserAvatar() {
  ImageProvider backgroundImage;
  try {
    backgroundImage = buildImageFromBase64(base64Image).image;
  } catch (e) {
    backgroundImage = const AssetImage('assets/images/default_person.jpg');
  }
  return CircleAvatar(
    radius: 42,
    backgroundColor: Colors.white,
    backgroundImage: backgroundImage,
  );
}




  // Widget for public information box
 Widget buildPublicInfoBox() {
  return GestureDetector(
    onTap: () => toggleSection('medicalInfo'),
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xff613089)),
              const SizedBox(width: 10),
              const Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff613089),
                ),
              ),
              const Spacer(),
              Icon(
                sectionExpanded['medicalInfo']!
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                color: const Color(0xff613089),
              ),
            ],
          ),
          const SizedBox(height: 15),

        
          if (sectionExpanded['medicalInfo']!) ...[
           _buildInfoRow(Icons.healing, 'Chronic Diseases', chronicDiseases.join(', ')),
           _buildInfoRow(Icons.warning_amber_rounded, 'Allergies', allergies.join(', ')),
                   _buildDonationHistory(donationDates),
          ],
        ],
      ),
    ),
  );
}
Future<void> _loadDonationDates() async {
   final userid =widget.patientId;

    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/users/$userid/blood-donations'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);

    // Check if the 'donationDates' key exists and is a list
    if (data.containsKey('donationDates') && data['donationDates'] is List) {
      final List<dynamic> dates = data['donationDates'];

      setState(() {
        // Extract and parse the 'lastBloodDonationDate' for each donation object
        donationDates = dates
            .map((e) => DateTime.parse(e['lastBloodDonationDate'] ?? '')) // Ensure the date string is valid
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid data format for donation dates')));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load donation dates')));
  }
}

  Widget _buildDonationHistory(List<DateTime> donationDates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Blood Donation History:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        donationDates.isEmpty
            ? const Text('No donation records available.')
            : Column(
                children: [
                  _buildDonationRow(donationDates.last, isLatest: true),
                  if (showAllDonations)
                    ...donationDates
                        .take(donationDates.length - 1)
                        .map((date) => _buildDonationRow(date))
                        .toList(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showAllDonations = !showAllDonations;
                      });
                    },
                    child: Text(
                      showAllDonations ? 'Show Less' : 'Show All',
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                      
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildDonationRow(DateTime date, {bool isLatest = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLatest ? const Color(0xFFE9D9FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xff613089)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Donation Date: ${formatDate(date)}'),
              Text(
                'Days since last donation: ${_daysSinceLastDonation(date)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }


  String formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  int _daysSinceLastDonation(DateTime date) {
    final now = DateTime.now();
    return now.difference(date).inDays;
  }





  Widget buildSquareButton({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xff613089)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



// Widget to build square buttons for services using an image instead of icon
Widget buildSquareButtonWithImage({
  required String imagePath, 
  required String label,
  required Function() onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover, 
            color: const Color(0xff613089),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}




/////////////////////////////////

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF2F5FF),
     appBar: kIsWeb ?
     AppBar(
              backgroundColor: const Color(0xFFF2F5FF),
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Patient Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff613089),
                  letterSpacing: 1.5,
                ),
              ),
              automaticallyImplyLeading: false,
            )
          : AppBar(
      backgroundColor: const Color(0xFFF2F5FF),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF613089)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Patient Information',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff613089),
          letterSpacing: 1.5,
        ),
      ),
    ),
    body: kIsWeb
        ? Center( 
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75, 
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildPatientInfo(),
                    const SizedBox(height: 10),
                    buildPersonalInfoBox(),
                    const SizedBox(height: 10),
                    buildPublicInfoBox(),
                    const SizedBox(height: 20),
                    _buildPermissionOrContent(),
                  ],
                ),
              ),
            ),
          )
        : SizedBox(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildPatientInfo(),
                  const SizedBox(height: 10),
                  buildPersonalInfoBox(),
                  const SizedBox(height: 10),
                  buildPublicInfoBox(),
                  const SizedBox(height: 20),
                  _buildPermissionOrContent(),
                ],
              ),
            ),
          ),
  );
}



Widget _buildPermissionOrContent() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: isallawod
        ? LayoutBuilder(
            builder: (context, constraints) {
              double crossAxisSpacing = constraints.maxWidth > 600 ? 90 : 20; 
              double mainAxisSpacing = constraints.maxWidth > 600 ? 90 : 20; 
              return GridView.count(
                crossAxisCount: kIsWeb ? 4 : 2, 
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                children: [
                  buildSquareButton(
                    icon: FontAwesomeIcons.capsules,
                    label: 'Drugs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MedicineListPage(patientId:widget.patientId,)),
                      );
                    },
                  ),
                  buildSquareButton(
                    icon: Icons.bloodtype,
                    label: 'Diabetes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DiabetesControlPage(patientId:widget.patientId)),
                      );
                    },
                  ),
                   buildSquareButton(
                              icon: Icons.monitor_heart,
                    label: 'Blood pressure',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BloodPressureControlPage(patientId:widget.patientId)),
                      );
                    },
                  ),
                  buildSquareButton(
                    icon: Icons.science,
                    label: 'Lab Tests',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LabTestsPage(patientId: widget.patientId)),
                      );
                    },
                  ),
                  buildSquareButton(
                    icon: Icons.note_alt,
                    label: 'Medical Notes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MedicalNotesPage(patientId: widget.patientId)),
                      );
                    },
                  ),
                  buildSquareButton(
                    icon: Icons.fact_check,
                    label: 'Medical History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MedicalHistoryPage(patientId: widget.patientId)),
                      );
                    },
                  ),
                  buildSquareButton(
                    icon: Icons.medication,
                    label: 'Treatment Plans',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TreatmentPlansPage(patientId: widget.patientId)),
                      );
                    },
                  ),
                ],
              );
            },
          )
        : Center(
            child: SizedBox(
              width: 200, 
              height: 110,  
              child: buildSquareButtonWithImage(
                imagePath: 'assets/images/permission_request.png',
                label: 'Request permission',
                onTap: () => _showRequestPermissionModal(context, widget.patientId),
              ),
            ),
          ),
  );
}



final TextEditingController _deadlineController = TextEditingController();
String _selectedPriority = ''; 
final TextEditingController _reasonController = TextEditingController();
   

 void _showRequestPermissionModal(BuildContext context, String patientId) {
  //const storage = FlutterSecureStorage();
  //final token =  storage.read(key: 'token');

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xff613089)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Center(
              child: Text(
                'Request Permission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff613089),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reason Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason for Request:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController, 
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for request...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 12.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Deadline Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deadline:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectDeadline(context, _deadlineController);
                    },
                    child: Text(
                      _deadlineController.text.isEmpty
                          ? 'Select Deadline'
                          : _deadlineController.text,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Priority Section
          Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Priority:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          // High Priority ChoiceChip
          ChoiceChip(
            label: const Text('High'),
            selected: _selectedPriority == 'High',
            selectedColor: const Color(0xff613089), 
            onSelected: (selected) {
              setState(() {
                _selectedPriority = selected ? 'High' : '';
              });
            },
          ),
          const SizedBox(width: 10),
          // Medium Priority ChoiceChip
          ChoiceChip(
            label: const Text('Medium'),
            selected: _selectedPriority == 'Medium',
            selectedColor: const Color(0xff613089), 
            onSelected: (selected) {
              setState(() {
      
                _selectedPriority = selected ? 'Medium' : ''; 
                debugPrint('Selected Priority: $_selectedPriority');
              });
            },
          ),
          const SizedBox(width: 10),
          // Low Priority ChoiceChip
          ChoiceChip(
            label: const Text('Low'),
            selected: _selectedPriority == 'Low',
            selectedColor: const Color(0xff613089), // Color when selected
            onSelected: (selected) {
              setState(() {
                // Update _selectedPriority directly
                _selectedPriority = selected ? 'Low' : ''; 
                debugPrint('Selected Priority: $_selectedPriority');
              });
            },
          ),
        ],
      ),
    ],
  ),
),


            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_deadlineController.text.isEmpty || _selectedPriority.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all required fields")),
                  );
                  return;
                }

                final response = await _submitRequestPermission(
                  _deadlineController.text,
                  _selectedPriority,
                  _reasonController.text,
                  patientId,
                );

                setState(() {
                  _reasonController.clear();
                  _deadlineController.clear();
                  _selectedPriority = '';
                });

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xff613089),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Request',
                style: TextStyle(
                  fontSize: 16,
                
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



Future<void> _requestPermission(String patientId) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/permission/request'),
      body: jsonEncode({
        'doctorId': doctorId,
        'patientId': patientId,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      _showMessage('Permission request sent successfully.');
    } else {
      _showMessage('Failed to send permission request.');
    }
  } catch (e) {
    _showMessage('Error: $e');
  }
}




Future<void> _submitRequestPermission(
  String deadline,
  String selectedPriority,
  String reason,
  String patientId,
) async {

  try {
    final name = await storage.read(key: 'username');
    if (name == null) throw Exception('Username not found in storage');
    _sendNotification( patientId,"MediCardia" , "$name : sent a permstion request");

    await addpermissionToDB(deadline, selectedPriority, reason, patientId,name);

    print('Permission request submitted successfully');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request submitted successfully!")),
    );
  } catch (error) {
    print('Error submitting request: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error submitting request: $error")),
    );
  }
}


Future<void> _selectDeadline(BuildContext context , TextEditingController controller) async {
    DateTime selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xff613089),
            hintColor: const Color(0xffb41391),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    ) ?? DateTime.now();

    TimeOfDay selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xff613089),
            hintColor: const Color(0xffb41391),
            timePickerTheme: const TimePickerThemeData(
              dialHandColor: Color(0xff613089),
              dialTextColor: Colors.black,
              backgroundColor: Colors.white,
              dayPeriodTextColor: Color(0xff613089),
            ),
          ),
          child: child!,
        );
      },
    ) ?? TimeOfDay.now();

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (mounted) {
      controller.text =
          "${selectedDateTime.toLocal().toString().split(' ')[0]}, ${selectedTime.format(context)}";
    }
}



void _sendNotification(String receiverId, String title, String message) async {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users/$receiverId');
  final DataSnapshot snapshot = await usersRef.get();

  if (snapshot.exists) {
    final String? fcmToken = snapshot.child('fcmToken').value as String?;

    if (fcmToken != null) {
      try {
        await sendNotifications(
          fcmToken: fcmToken,
          title: title,
          body: message,
          userId: receiverId,
          type: 'request',
        );
        print('Notification sent successfully');
      } catch (error) {
        print('Error sending notification: $error');
      }
    } else {
      print('FCM token not found for the user.');
    }
  } else {
    print('User not found in the database.');
  }
}


Future<void> addpermissionToDB(String deadline, selectedPriority, String text ,String patientId, String name) async {
  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('Permission').push();
    print('Permission added to Firebase Realtime Database successfully.');

    await ref.set({
      'doctorid': await storage.read(key: 'userid'),
      'userId': patientId,
      'selectedPriority': selectedPriority,
      'body': text,
      'deadline':deadline,
      'name':name,
    });

    print('Permission added to Firebase Realtime Database successfully.');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error adding permission: $error')),
);

    print('Error adding notification to Firebase: $error');
  }
}



}










/*
         final TextEditingController _deadlineController = TextEditingController();
        String _selectedPriority = ''; // Variable to store the selected priority.
TextEditingController _reasonController = TextEditingController();


 void _showRequestPermissionModal(BuildContext context, String patientId) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xff613089)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Center(
              child: Text(
                'Request Permission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff613089),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reason Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason for Request:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController, // ربط controller بـ TextField

                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for request...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 12.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Deadline Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deadline:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectDeadline(context);
                    },
                    child: Text(
                      _deadlineController.text.isEmpty
                          ? 'Select Deadline'
                          : _deadlineController.text,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Priority Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Priority:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                    ChoiceChip(
            label: const Text('High'),
            selected: _selectedPriority == 'High',
                        selectedColor: const Color(0xff613089), // Color whe

            onSelected: (selected) {
              setState(() {
                _selectedPriority = selected ? 'High' : '';
              });
            },
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: const Text('Medium'),
            selected: _selectedPriority == 'Medium',
            selectedColor: const Color(0xff613089), // Color whe
            onSelected: (selected) {
              setState(() {
                _selectedPriority = selected ? 'Medium' : '';
              });
            },
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: const Text('Low'),
            selected: _selectedPriority == 'Low',
                        selectedColor: const Color(0xff613089), // Color whe

            onSelected: (selected) {
              setState(() {
                _selectedPriority = selected ? 'Low' : '';
              });
            },
          ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            ElevatedButton(
              onPressed: () async {
                // Validation for required fields
                if (_deadlineController.text.isEmpty ||
                    _selectedPriority.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all required fields")),
                  );
                  return;
                }

                // Call API to submit the request
                final response = await _submitRequestPermission(
                  _deadlineController.text,
                  _selectedPriority,
                  _reasonController.text,
                  patientId
                );

                // Handle the response
                if (response != null && response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request submitted successfully!")),
                  );
                  Navigator.of(context).pop(); // Close the modal
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to submit request")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xff613089),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


_submitRequestPermission(String deadline, selectedPriority, String text ,String patientId) {
String name = storage.read(key: 'username') as String;

         _sendNotification( patientId,"MediCardia" , "$name : sent a permstion request");
addpermissionToDB(deadline,selectedPriority,text,patientId);
}

void setState(Null Function() param0) {
}

Future<void> _selectDeadline(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  
  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      final DateTime combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _deadlineController.text = DateFormat('yyyy-MM-dd HH:mm').format(combined);
    }
  }
}

void _sendNotification(String receiverId, String title, String message) async {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users/$receiverId');
  final DataSnapshot snapshot = await usersRef.get();

  if (snapshot.exists) {
    final String? fcmToken = snapshot.child('fcmToken').value as String?;

    if (fcmToken != null) {
      try {
        await sendNotifications(
          fcmToken: fcmToken,
          title: title,
          body: message,
          userId: receiverId,
        );
        print('Notification sent successfully');
      } catch (error) {
        print('Error sending notification: $error');
      }
    } else {
      print('FCM token not found for the user.');
    }
  } else {
    print('User not found in the database.');
  }
}
Future<void> addpermissionToDB(String deadline, selectedPriority, String text ,String patientId) async {
  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('permission').push();

    await ref.set({
      'doctorid': await storage.read(key: 'userid'),
      'userId': patientId,
      'selectedPriority': selectedPriority,
      'body': text,
      'deadline':deadline,
    });

    print('Notification added to Firebase Realtime Database successfully.');
  } catch (error) {
    print('Error adding notification to Firebase: $error');
  }
}
*/