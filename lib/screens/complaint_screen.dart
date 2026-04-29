// lib/screens/complaint_screen.dart
import 'package:flutter/material.dart';
import '../services/complaint_service.dart';

class ComplaintScreen extends StatefulWidget {
  final String guestName;
  const ComplaintScreen({super.key, required this.guestName});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  void _submitComplaint() async {
    // 1. Basit validasyon: Alanlar boşsa işlem yapma
    if (_emailController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 🚨 KRİTİK GÜNCELLEME: widget.guestName artık servise gönderiliyor!
    // Böylece veritabanındaki "guest_name" sütunu boş kalmayacak.
    bool isSuccess = await ComplaintService().sendComplaint(
      widget.guestName, // Login ekranından gelen isim (Örn: berke)
      _emailController.text.trim(),
      _subjectController.text.trim(),
      _messageController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (isSuccess) {
        // Başarılı popup'ını göster
        showDialog(
          context: context,
          barrierDismissible: false, // Kullanıcı dışarı tıklayıp kapatamasın
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            content: const Text(
              'Geri bildiriminiz başarıyla iletildi. Yöneticilerimiz en kısa sürede inceleyecektir. Teşekkür ederiz!',
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialogu kapat
                    Navigator.pop(
                      context,
                    ); // Şikayet ekranından çık, girişe dön
                  },
                  child: const Text(
                    'Tamam',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Hata durumunda uyarı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sunucu hatası! İsim bilgisi veya bağlantı sorunu olabilir.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet & Öneri',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Merhaba ${widget.guestName},',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Görüşlerinizi bizimle paylaşın. Size geri dönüş yapabilmemiz için e-posta adresinizi girmeyi unutmayın.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // E-POSTA
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-Posta Adresiniz',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // KONU
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Konu',
                prefixIcon: const Icon(Icons.subject),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MESAJ
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Mesajınız',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.message),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // GÖNDER BUTONU
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Gönder',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
