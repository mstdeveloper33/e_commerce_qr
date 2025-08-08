import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/barcode_provider.dart';
import '../models/barcode_result.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında debug bilgisi yazdır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BarcodeProvider>();
      provider.debugPrintHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text(
          'Tarama Geçmişi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () {
              _showClearHistoryDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<BarcodeProvider>(
        builder: (context, provider, child) {
          print('🔄 Geçmiş ekranı yenilendi - Kayıt sayısı: ${provider.scanHistory.length}');
          
          if (provider.scanHistory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz Barkod Taranmadı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Barkod taramaya başladığınızda\ngeçmiş burada görünecek',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.scanHistory.length,
            itemBuilder: (context, index) {
              final barcode = provider.scanHistory[index];
              print('📋 Geçmiş öğesi ${index + 1}: ${barcode.code}');
              return _buildHistoryItem(barcode, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BarcodeResult barcode, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: barcode.isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: barcode.isSuccess ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  barcode.isSuccess ? 'Başarılı' : 'Başarısız',
                  style: TextStyle(
                    color: barcode.isSuccess ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getFormatColor(barcode.format).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  barcode.format,
                  style: TextStyle(
                    color: _getFormatColor(barcode.format),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                barcode.isSuccess ? Icons.check_circle : Icons.error,
                color: barcode.isSuccess ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            barcode.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          if (!barcode.isSuccess && barcode.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                barcode.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(barcode.timestamp),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFormatColor(String format) {
    switch (format.toUpperCase()) {
      case 'EAN_13':
        return Colors.green;
      case 'EAN_8':
        return Colors.blue;
      case 'CODE_128':
        return Colors.orange;
      case 'CODE_39':
        return Colors.purple;
      case 'QR_CODE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Geçmişi Temizle',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tüm tarama geçmişini silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              await context.read<BarcodeProvider>().clearScanHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geçmiş temizlendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Temizle',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 