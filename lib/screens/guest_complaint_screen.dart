// lib/screens/guest_complaint_screen.dart
import 'package:flutter/material.dart';
import '../services/complaint_service.dart';

class GuestComplaintScreen extends StatefulWidget {
  const GuestComplaintScreen({super.key});

  @override
  State<GuestComplaintScreen> createState() => _GuestComplaintScreenState();
}

class _GuestComplaintScreenState extends State<GuestComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final ComplaintService _complaintService = ComplaintService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  void _submitComplaint() async {
    // Tüm alanlar dolduruldu mu kontrolü
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await _complaintService.sendComplaint(
        "Misafir",
        _emailController.text.trim(),
        _subjectController.text.trim(),
        _messageController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildiriminiz başarıyla iletildi.'),
              backgroundColor: Colors.green,
            ),
          );
          _emailController.clear();
          _subjectController.clear();
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gönderim başarısız. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet & Öneri Bildirimi',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bize Ulaşın',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Daha temiz bir çevre için görüşleriniz bizim için çok değerli.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // 1. E-POSTA
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-Posta Adresiniz',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'E-posta alanı zorunludur.';
                  if (!value.contains('@'))
                    return 'Geçerli bir e-posta adresi giriniz.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. KONU
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Konu',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Lütfen bir konu başlığı giriniz.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. MESAJ
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Mesajınız',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Mesaj alanı boş bırakılamaz.';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Gönder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
