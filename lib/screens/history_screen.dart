// lib/screens/history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Backend'den gelecek veriyi simüle eden geçici liste (Mock Data)
  final List<Map<String, dynamic>> _pastTasks = [
    {
      "containerName": "Cam Atık Konteyneri #4",
      "status": "DONE",
      "time": "10:15",
      "amountKg": 120,
      "skipReason": null,
    },
    {
      "containerName": "Plastik Atık Konteyneri #2",
      "status": "SKIPPED",
      "time": "09:45",
      "amountKg": null,
      "skipReason": "Araç park etmiş, ulaşılamadı.",
    },
    {
      "containerName": "Kağıt Atık Konteyneri #1",
      "status": "DONE",
      "time": "09:10",
      "amountKg": 85,
      "skipReason": null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Geçmiş Görevler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _pastTasks.length,
        itemBuilder: (context, index) {
          final task = _pastTasks[index];
          final isDone = task['status'] == 'DONE';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol taraftaki ikon
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDone
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      isDone ? Icons.check_circle : Icons.warning_rounded,
                      color: isDone ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Orta kısımdaki bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['containerName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task['time'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Duruma göre kg veya sebep gösterme
                        if (isDone)
                          Text(
                            'Toplanan: ${task['amountKg']} kg',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Sebep: ${task['skipReason']}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Sağ üstteki durum etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isDone ? 'Toplandı' : 'Atlandı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
