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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  bool _hasPermission = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _scannerController = MobileScannerController(
        // Yalnızca EAN-13 okut
        formats: const [BarcodeFormat.ean13],
        // Normal hızda algılama (duplikasyon kontrolü Provider'da)
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_scannerController == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isActive) {
          _scannerController?.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _scannerController?.stop();
        break;
    }
  }

  void _pauseCamera() {
    _isActive = false;
    _scannerController?.stop();
  }

  void _resumeCamera() {
    _isActive = true;
    _scannerController?.start();
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
              _pauseCamera();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              _resumeCamera();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              _pauseCamera();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _resumeCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kamera alanı - Consumer dışında (rebuild'den korunuyor)
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
                              // Provider'dan isScanning kontrolü al (listen: false)
                              final provider = Provider.of<BarcodeProvider>(context, listen: false);
                              if (provider.isScanning || provider.isLoading) return;
                              
                              provider.scanAndSendBarcode(
                                barcode.rawValue!,
                                barcode.format.name,
                              );
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
          
          // UI bilgileri - Consumer içinde (sadece UI rebuild)
          Expanded(
            flex: 3,
            child: Consumer<BarcodeProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
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
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Test Modu',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
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
    );
  }
}