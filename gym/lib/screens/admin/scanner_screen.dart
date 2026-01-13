import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isProcessing = true;
        setState(() {});

        try {
          String code = barcode.rawValue!;
          Map<String, dynamic> payload = {};

          // 1. Try Parsing as strict JSON
          try {
            final data = jsonDecode(code);
            if (data is Map<String, dynamic>) {
              payload = data;
            }
          } catch (_) {
            // Not valid JSON, proceed to other methods
          }

          // 2. If payload empty, try Regex for loose format (e.g. {key:value})
          if (payload.isEmpty) {
            final idMatch = RegExp(
              r'(member_id|trainer_id|id)\s*:\s*(\d+)',
            ).firstMatch(code);
            final tsMatch = RegExp(r'timestamp\s*:\s*(\d+)').firstMatch(code);

            if (idMatch != null) {
              payload['trainer_id'] = int.parse(idMatch.group(2)!);
            }
            if (tsMatch != null) {
              payload['timestamp'] = int.parse(tsMatch.group(1)!);
            }
          }

          // 3. Fallback: Treat as Static ID if still empty
          if (payload.isEmpty) {
            String cleanCode = code
                .trim()
                .replaceAll('"', '')
                .replaceAll("'", "");
            final id = int.tryParse(cleanCode);
            if (id != null) {
              payload = {
                'trainer_id': id,
                // Timestamp injection occurs below if missing
              };
            }
          }

          // Validation & Normalization
          if (!payload.containsKey('trainer_id')) {
            // Check if we captured 'member_id' in strict JSON parse but didn't map it
            if (payload.containsKey('member_id')) {
              payload['trainer_id'] = payload['member_id'];
            } else {
              throw Exception("Invalid Format: Missing ID. Scanned: '$code'");
            }
          }

          // Inject timestamp if missing (for static QRs or malformed timestamps)
          if (!payload.containsKey('timestamp')) {
            payload['timestamp'] =
                DateTime.now().millisecondsSinceEpoch ~/ 1000;
          }

          // Backend compatibility: Ensure trainer_id is present (mapped from member_id if needed)
          // (Already handled above)

          // Fetch member details first
          final int memberId = payload['trainer_id'];
          final memberResponse = await _apiService.get(
            '/management/members/$memberId',
          );
          final memberData = memberResponse.data['data'];

          if (mounted) {
            _showVerificationDialog(memberData, payload);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
            // Re-enable scanning after delay if failed
            await Future.delayed(const Duration(seconds: 2));
            _isProcessing = false;
            setState(() {});
          }
        }
        break; // Process only first valid code
      }
    }
  }

  Future<void> _showVerificationDialog(
    Map<String, dynamic> member,
    Map<String, dynamic> payload,
  ) async {
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Picture
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    (member['profile_picture'] != null &&
                        member['profile_picture'].toString().isNotEmpty)
                    ? NetworkImage(
                        '${AppConstants.baseUrl}${member['profile_picture']}',
                      )
                    : null,
                child:
                    (member['profile_picture'] == null ||
                        member['profile_picture'].toString().isEmpty)
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Name & Email
            Text(
              member['name'] ?? 'Unknown Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              member['email'] ?? 'No Email',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 25),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn(
                    "Status",
                    member['membership_status'] ?? 'N/A',
                    (member['membership_status'] == 'active')
                        ? Colors.green
                        : Colors.red,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildInfoColumn(
                    "Package",
                    member['package'] != null
                        ? member['package']['name']
                        : 'None',
                    Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Confirm & Mark",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (confirm == true) {
      if (mounted) _submitAttendance(payload);
    } else {
      // Clean up if cancelled
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _submitAttendance(Map<String, dynamic> payload) async {
    try {
      await _apiService.post('/management/scan', data: payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance Marked Successfully!')),
        );
        Navigator.pop(context); // Go back after success
      }
    } on DioException catch (e) {
      String errorMessage = 'Error marking attendance';
      if (e.response != null) {
        if (e.response?.statusCode == 409) {
          errorMessage = 'Attendance already marked for today!';
        } else if (e.response?.data != null &&
            e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error']; // Use backend error message
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
        );
        // Reset processing state to allow retry or new scan
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
