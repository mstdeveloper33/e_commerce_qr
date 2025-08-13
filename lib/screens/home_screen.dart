import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/barcode_provider.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MobileScannerController? _scannerController;
  bool _hasPermission = false;
  bool _isStockEntryMode = false;
  
  // Stok ve fiyat input kontrolcüleri
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _scannerController = MobileScannerController(
        formats: const [BarcodeFormat.ean13],
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void dispose() {
    try {
      _scannerController?.dispose();
    } catch (e) {
      print('Scanner dispose hatası: $e');
    }
    _stokController.dispose();
    _fiyatController.dispose();
    super.dispose();
  }

  void _showStokFiyatDialog(String barkod, String format) {
    _stokController.clear();
    _fiyatController.clear();
    
    // Dialog açılırken kamerayı durdur
    try {
      _scannerController?.stop();
    } catch (e) {
      print('Kamera durdurma hatası (dialog): $e');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Validation kontrolleri
            final stokText = _stokController.text;
            final fiyatText = _fiyatController.text;
            final stok = int.tryParse(stokText) ?? 0;
            final fiyat = double.tryParse(fiyatText) ?? 0.0;
            final isValid = stok >= 1 && fiyat > 0;
            
            return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'Stok ve Fiyat Bilgisi',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Barkod: $barkod',
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() {}), // Validation için rebuild
                decoration: InputDecoration(
                  labelText: 'Stok Miktarı (En az 1)',
                  labelStyle: TextStyle(
                    color: stok < 1 && stokText.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: stok < 1 && stokText.isNotEmpty ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: stok < 1 && stokText.isNotEmpty ? Colors.red : Colors.blue,
                    ),
                  ),
                  errorText: stok < 1 && stokText.isNotEmpty ? 'Stok adedi en az 1 olmalı' : null,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fiyatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() {}), // Validation için rebuild
                decoration: InputDecoration(
                  labelText: 'Fiyat (₺) - Zorunlu',
                  labelStyle: TextStyle(
                    color: fiyat <= 0 && fiyatText.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: fiyat <= 0 && fiyatText.isNotEmpty ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: fiyat <= 0 && fiyatText.isNotEmpty ? Colors.red : Colors.blue,
                    ),
                  ),
                  errorText: fiyat <= 0 && fiyatText.isNotEmpty ? 'Fiyat 0\'dan büyük olmalı' : null,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Dialog kapandıktan sonra kamerayı tekrar başlat
                try {
                  _scannerController?.start();
                } catch (e) {
                  print('Kamera başlatma hatası (iptal): $e');
                }
              },
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isValid ? () {
                final stok = int.tryParse(_stokController.text) ?? 0;
                final fiyat = double.tryParse(_fiyatController.text) ?? 0.0;
                
                Navigator.of(context).pop();
                
                // Provider'dan stok ve fiyat ile barkod gönder
                final provider = Provider.of<BarcodeProvider>(context, listen: false);
                provider.scanAndSendBarcodeWithDetails(barkod, format, stok, fiyat);
                
                // Dialog kapandıktan sonra kamerayı tekrar başlat
                try {
                  _scannerController?.start();
                } catch (e) {
                  print('Kamera başlatma hatası (kaydet): $e');
                }
              } : null, // Geçerli değilse buton pasif
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? Colors.blue : Colors.grey,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                'Kaydet',
                style: TextStyle(
                  color: isValid ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text(
          'E-Ticaret Barkod Tarayıcı',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () async {
              try {
                _scannerController?.stop();
              } catch (e) {
                print('Kamera durdurma hatası (history): $e');
              }
              
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              
              try {
                _scannerController?.start();
              } catch (e) {
                print('Kamera başlatma hatası (history): $e');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              try {
                _scannerController?.stop();
              } catch (e) {
                print('Kamera durdurma hatası (settings): $e');
              }
              
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              
              try {
                _scannerController?.start();
              } catch (e) {
                print('Kamera başlatma hatası (settings): $e');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kamera alanı
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _hasPermission && _scannerController != null
                    ? MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final barcode = barcodes.first;
                            if (barcode.rawValue != null) {
                              final provider = Provider.of<BarcodeProvider>(context, listen: false);
                              
                              // Çift okumayı engelle
                              if (provider.isScanning || provider.isLoading) return;
                              
                              // Stok modu aktifse dialog aç, değilse direkt gönder
                              if (_isStockEntryMode) {
                                _showStokFiyatDialog(
                                  barcode.rawValue!,
                                  barcode.format.name,
                                );
                              } else {
                                provider.scanAndSendBarcode(
                                  barcode.rawValue!,
                                  barcode.format.name,
                                );
                              }
                            }
                          }
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Kamera İzni Gerekli',
                                style: TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          
          // UI bilgileri
          Expanded(
            flex: 3,
            child: Consumer<BarcodeProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // Stok modu bilgisi
                    if (_isStockEntryMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent, width: 1.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.inventory_2, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stok kaydı modu aktif: Barkodu okuttuktan sonra stok ve fiyat girin',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // API durumu
                    if (provider.apiSettings?.apiUrl.isNotEmpty == true)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'API Bağlantısı Aktif',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    provider.apiSettings?.apiUrl ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Test Modu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Ayarlar sayfasından API URL\'ini girin',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Hata mesajı
                    if (provider.lastError.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.lastError,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              onPressed: provider.clearError,
                            ),
                          ],
                        ),
                      ),

                    // Son taranan barkod
                    if (provider.lastScannedBarcode.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Son Taranan Barkod:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.lastScannedBarcode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Yükleme göstergesi
                    if (provider.isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.apiSettings?.apiUrl.isNotEmpty == true
                                    ? 'Barkod API\'ye gönderiliyor...'
                                    : 'Barkod test modunda kaydediliyor...',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isStockEntryMode = !_isStockEntryMode;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isStockEntryMode
                  ? 'Stok kaydı modu aktif. Barkodu okuttuktan sonra stok ve fiyat girin.'
                  : 'Normal tarama moduna geçildi.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: _isStockEntryMode ? Colors.blueAccent : const Color(0xFF3D3D3D),
        label: Row(
          children: const [
            Icon(Icons.inventory_2, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Stok Kaydı',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}