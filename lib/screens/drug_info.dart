import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class DrugDetails {
  final String drugName; 
  final String use;
  final String dose;
  final String time;
  final String notes;

  DrugDetails({
    required this.drugName,
    required this.use,
    required this.dose,
    required this.time,
    required this.notes,
  });

  factory DrugDetails.fromJson(Map<String, dynamic> json, String drugName) {
    return DrugDetails(
      drugName: drugName,
      use: json['Use'] ?? "Not specified",
      dose: json['Dose'] ?? "Not specified",
      time: json['Time'] ?? "Not specified",
      notes: json['Notes'] ?? "Not specified",
    );
  }
}

class DrugInfoPage extends StatefulWidget {
  const DrugInfoPage({Key? key}) : super(key: key);

  @override
  _DrugInfoPageState createState() => _DrugInfoPageState();
}

class _DrugInfoPageState extends State<DrugInfoPage> {
  bool isScanButtonVisible = true;  // Controls the visibility of the scan button

  // Function to fetch drug details from the API
  Future<DrugDetails?> fetchDrugDetails(String barcode) async {
    const String apiUrl = '${ApiConstants.baseUrl}/drugs/barcodeUse'; // Replace with your API endpoint

    try {
      final response = await http.get(Uri.parse('$apiUrl?barcode=$barcode'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['drug'] != null && data['drug']['details'] != null && data['drug']['details'].isNotEmpty) {
          final String drugName = data['drug']['Drugname'] ?? "Unknown Drug";
          // Extract the first detail from the "details" array
          return DrugDetails.fromJson(data['drug']['details'][0], drugName);
        } else {
          throw Exception("No details found for this drug.");
        }
      } else if (response.statusCode == 404) {
        throw Exception("Drug not found.");
      } else {
        throw Exception("Failed to fetch drug details.");
      }
    } catch (e) {
      print('Error fetching drug details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         backgroundColor: Colors.white,
         elevation: 0,
         centerTitle: true,
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(fontWeight: FontWeight.bold,
        color: Color(0xff613089),
            letterSpacing: 1.5),
        ),
      
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Scanner Area
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade50,
                          Colors.purple.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // When the barcode image is clicked, trigger the scanner
                      String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
                        "#ff6666", // Color for the scan line
                        "Cancel", // Cancel button text
                        true, // Show flash icon
                        ScanMode.BARCODE, // Scan mode (can also be QR_CODE)
                      );

                      if (barcodeScanResult != "-1") {
                        DrugDetails? drugDetails = await fetchDrugDetails(barcodeScanResult);

                        if (drugDetails != null) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return DrugDetailsDialog(drugDetails: drugDetails);
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to fetch drug details.')),
                          );
                        }
                      }

                      // Hide the scan button after clicking the barcode image
                      setState(() {
                        isScanButtonVisible = false;
                      });
                    },
                    child: Image.asset(
                      'assets/images/barcode.png', // The path to your image
                      width: 150,
                      height: 150,
                      color: Colors.purple.shade300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instruction Text
            const Center(
              child: Text(
                "Scan any drug barcode to view details.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 20),

          
           
          ],
        ),
      ),
    );
  }
}

class DrugDetailsDialog extends StatelessWidget {
  final DrugDetails drugDetails;

  const DrugDetailsDialog({required this.drugDetails, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
const SizedBox(height: 10),
            // Drug Name
            _buildDetailRow('Drug Name', drugDetails.drugName),
            const SizedBox(height: 10),

            // Use section
            _buildDetailRow('Use', drugDetails.use,isMultiline: true),
            const SizedBox(height: 20),

            // Dose section
            _buildDetailRow('Dose', drugDetails.dose, isMultiline: true),
            const SizedBox(height: 10),

            // Time section
            _buildDetailRow('Time', drugDetails.time, isMultiline: true),
            const SizedBox(height: 10),

            // Notes section
            _buildDetailRow('Notes', drugDetails.notes, isMultiline: true),
            const SizedBox(height: 20),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff613089),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xff2a2a2a),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: isMultiline
              ? Container(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
