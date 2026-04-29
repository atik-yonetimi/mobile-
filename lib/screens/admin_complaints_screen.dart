// lib/screens/admin_complaints_screen.dart
import 'package:flutter/material.dart';
import '../services/complaint_service.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final ComplaintService _complaintService = ComplaintService();
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    final data = await _complaintService.getComplaints();
    setState(() {
      _complaints = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteComplaint(int id) async {
    final success = await _complaintService.deleteComplaint(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şikayet silindi.'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchComplaints(); // Listeyi yenile
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silme işlemi başarısız.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şikayeti Sil'),
        content: const Text(
          'Bu mesajı okundu olarak işaretleyip silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComplaint(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Evet, Sil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gelen Şikayetler',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _complaints.isEmpty
          ? const Center(
              child: Text(
                'Harika! Hiç şikayet yok.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _complaints.length,
              itemBuilder: (context, index) {
                final complaint = _complaints[index];

                // 🚨 TARİH FORMATLAMA EKLENDİ 🚨
                String dateText = '';
                if (complaint['createdAt'] != null) {
                  DateTime dt = DateTime.parse(
                    complaint['createdAt'],
                  ).toLocal();
                  dateText =
                      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                complaint['subject'] ?? 'Konu Yok',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(complaint['id']),
                            ),
                          ],
                        ),
                        // 🚨 TARİH EKRANA BASILIYOR 🚨
                        if (dateText.isNotEmpty) ...[
                          Text(
                            dateText,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const Divider(),
                        Text(
                          complaint['message'] ?? 'Mesaj içeriği yok.',
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              complaint['guestEmail'] ?? 'Gizli',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
