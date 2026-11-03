import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String gasWebappUrl =
    "https://script.google.com/a/macros/netra.co.id/s/AKfycbxViKkn5X_ecqivpp0Rnga3zmFwZ5YB-zjd8VNYUGVPUVxCw-YiKQwrBdE8GZ6717z4/exec";

void main() {
  runApp(const TMATApp());
}

class TMATApp extends StatelessWidget {
  const TMATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laporan Instalasi TMAT',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F9),
        fontFamily: 'sans-serif',
      ),
      initialRoute: '/form',
      routes: {
        '/form': (context) => const FormScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/success') {
          final data = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => SuccessScreen(reportData: data),
          );
        }
        return null;
      },
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  // Status Sinyal Jaringan
  bool _isOnline = true;

  // Antrean Laporan Offline (Bebas Error Generics)
  //final _pendingReports = >[];
  final List _pendingReports = [];
  DateTime _selectedDate = DateTime(2025, 10, 30);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 32);

  // Controller Form 1
  final TextEditingController _boxController =
      TextEditingController(text: "TMAT-008-009");
  final TextEditingController _starlinkController =
      TextEditingController(text: "KIT4M052431619N7");
  final TextEditingController _siteController =
      TextEditingController(text: "Blok KEP Blok 43-03");
  final TextEditingController _ptController =
      TextEditingController(text: "THINDO PLANTATIONS");

  // Mode GPS & Koordinat Form 2
  bool _isGpsAuto = true;
  bool _isFetchingGps = false;
  final TextEditingController _latController =
      TextEditingController(text: "1.91305572N");
  final TextEditingController _longController =
      TextEditingController(text: "100.80251737E");

  // Field Form 2 Lainnya
  final TextEditingController _form2PtController =
      TextEditingController(text: "PT.JATIM JAYA PERKASA");
  final TextEditingController _blokSiteController =
      TextEditingController(text: "C13R");
  final TextEditingController _panelNoController =
      TextEditingController(text: "177");
  final TextEditingController _boxNoController =
      TextEditingController(text: "TMAT-008-014");
  final TextEditingController _rainfallSnController =
      TextEditingController(text: "SEM404-204");
  final TextEditingController _waterLevelSnController =
      TextEditingController(text: "2608031");
  final TextEditingController _soilMoistureSnController =
      TextEditingController(text: "SEM225-024");
  final TextEditingController _starlinkKitSnController =
      TextEditingController(text: "M1FV00585135Q4Z");
  final TextEditingController _gsmNoController =
      TextEditingController(text: "081180118314");

  String _selectedKoneksi = "Starlink";
  bool _gsmChecked = true;

  // Controller Parameter Pengukuran
  final TextEditingController _panelBoxParamController =
      TextEditingController(text: "TMAT-008-002");
  final TextEditingController _soilMoistureController =
      TextEditingController(text: "45.2%");
  final TextEditingController _waterLevelController =
      TextEditingController(text: "120 cm");
  final TextEditingController _rainfallController =
      TextEditingController(text: "15 mm");

  final Map<int, bool> _uploadedPhotos = {};
  bool _isLoading = false;

  final _photoSlots = [
    {"num": "①", "label": "1 Foto Instalasi TMAT"},
    {"num": "②", "label": "2 Foto S/N Starlink"},
    {"num": "⊕", "label": "Foto S/N Soil Moisture"},
    {"num": "②", "label": "3 Foto S/N Starlink"},
    {"num": "③", "label": "Foto Soil Moisture"},
    {"num": "⊕", "label": "4 Foto S/N Metr Level"},
    {"num": "④", "label": "4 Foto S/N Rainfall"},
    {"num": "⑤", "label": "5"},
    {"num": "⑤", "label": "S/N Water Level"},
  ];

  @override
  void dispose() {
    _boxController.dispose();
    _starlinkController.dispose();
    _siteController.dispose();
    _ptController.dispose();
    _latController.dispose();
    _longController.dispose();
    _form2PtController.dispose();
    _blokSiteController.dispose();
    _panelNoController.dispose();
    _boxNoController.dispose();
    _rainfallSnController.dispose();
    _waterLevelSnController.dispose();
    _soilMoistureSnController.dispose();
    _starlinkKitSnController.dispose();
    _gsmNoController.dispose();
    _panelBoxParamController.dispose();
    _soilMoistureController.dispose();
    _waterLevelController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  Future<void> _ambilKoordinatGps() async {
    setState(() => _isFetchingGps = true);
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      _latController.text = "1.91305572N";
      _longController.text = "100.80251737E";
      _isFetchingGps = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Titik koordinat GPS berhasil diperbarui!"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pilihJam() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _simulasiPilihFoto(int index) {
    setState(() {
      _uploadedPhotos[index] = !(_uploadedPhotos[index] ?? false);
    });
    final status = _uploadedPhotos[index]! ? "dipilih" : "dibatalkan";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Slot ${_photoSlots[index]['label']} $status"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Map<String, dynamic> _buildPayload() {
    return {
      "tanggal":
          "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}",
      "jam":
          "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
      "nomor_box": _boxController.text,
      "sn_starlink": _starlinkController.text,
      "nama_site": _siteController.text,
      "nama_perusahaan": _ptController.text,
      "mode_gps": _isGpsAuto ? "Auto" : "Manual",
      "latitude": _latController.text,
      "longitude": _longController.text,
      "pt_perusahaan": _form2PtController.text,
      "blok_site": _blokSiteController.text,
      "panel_no": _panelNoController.text,
      "box_no": _boxNoController.text,
      "rainfall_sn": _rainfallSnController.text,
      "water_level_sn": _waterLevelSnController.text,
      "soil_moisture_sn": _soilMoistureSnController.text,
      "jenis_koneksi": _selectedKoneksi,
      "starlink_kit_sn":
          _selectedKoneksi == "Starlink" ? _starlinkKitSnController.text : "",
      "gsm_nomor": _selectedKoneksi == "GSM" ? _gsmNoController.text : "",
      "gsm_checked": _selectedKoneksi == "GSM" ? _gsmChecked : false,
      "param_panel_box": _panelBoxParamController.text,
      "param_soil_moisture": _soilMoistureController.text,
      "param_water_level": _waterLevelController.text,
      "param_rainfall": _rainfallController.text,
    };
  }

  Future<void> _sinkronisasiAntrean() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD97706),
          content: Text("Masih offline. Cari sinyal terlebih dahulu!"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    int successCount = 0;

    for (final report in List.from(_pendingReports)) {
      try {
        await http.post(
          Uri.parse(gasWebappUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(report),
        ).timeout(const Duration(seconds: 10));
        _pendingReports.remove(report);
        successCount++;
      } catch (e) {
        debugPrint("Gagal kirim item antrean: $e");
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF009640),
          content: Text("$successCount laporan tertunda berhasil disinkronkan!"),
        ),
      );
    }
  }

  Future<void> _kirimLaporan() async {
    final payload = _buildPayload();

    if (!_isOnline) {
      setState(() {
        _pendingReports.add(payload);
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: const [
              Icon(Icons.signal_cellular_connected_no_internet_0_bar,
                  color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text("Disimpan Offline", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: const Text(
            "Tidak ada sinyal GSM. Laporan instalasi berhasil disimpan di memori HP dan akan otomatis terkirim begitu sinyal tersedia.",
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D66CC)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Mengerti", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await http.post(
        Uri.parse(gasWebappUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(
          context,
          '/success',
          arguments: payload,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pendingReports.add(payload);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD97706),
            content: Text("Sinyal terputus. Data diamankan ke Antrean Offline."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tglStr =
        "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}";
    final jamStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D66CC),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "LAPORAN INSTALASI TMAT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              setState(() => _isOnline = !_isOnline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isOnline
                      ? "Mode Simulasi: Sinyal GSM Tersedia (Online)"
                      : "Mode Simulasi: Tidak Ada Sinyal (Offline)"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isOnline ? const Color(0xFF009640) : const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.signal_cellular_4_bar : Icons.signal_cellular_off,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isOnline ? "Online" : "No Signal",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke server..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  if (_pendingReports.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Color(0xFFD97706), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_pendingReports.length} Laporan Belum Terkirim",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const Text(
                                  "Tersimpan di HP karena tidak ada sinyal.",
                                  style: TextStyle(fontSize: 10, color: Color(0xFF78350F)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: _sinkronisasiAntrean,
                            child: const Text(
                              "Kirim",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 1. KARTU TANGGAL & JAM
                  InkWell(
                    onTap: () async {
                      await _pilihTanggal();
                      await _pilihJam();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF4A90E2), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Color(0xFF0D66CC), size: 30),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TANGGAL:",
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "$tglStr • Jam $jamStr",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. KARTU FORM 1 • Aktivasi Perangkat
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assignment_outlined,
                                color: Color(0xFF0D66CC), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "FORM 1 • Aktivasi Perangkat",
                              style: TextStyle(
                                color: Color(0xFF0D66CC),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildEditableRow("Nomor Box TMAT", _boxController),
                        _buildEditableRow("S/N Starlink", _starlinkController),
                        _buildEditableRow("Nama Site", _siteController),
                        _buildEditableRow("Nama Perusahaan", _ptController),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. KARTU FORM 2 • Verifikasi Instalasi
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.check_box_outlined,
                                    color: Color(0xFF0A7E35), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "FORM 2 • Verifikasi Instalasi",
                                  style: TextStyle(
                                    color: Color(0xFF0A7E35),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Switch Auto GPS / Manual
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F6FD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFD0E1F9), width: 0.8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isGpsAuto
                                        ? Icons.my_location
                                        : Icons.edit_location_alt,
                                    size: 16,
                                    color: const Color(0xFF0D66CC),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isGpsAuto
                                        ? "Mode: Auto (GPS HP)"
                                        : "Mode: Manual (Ketik Sendiri)",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D66CC),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    _isGpsAuto ? "Auto" : "Manual",
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: _isGpsAuto,
                                      activeTrackColor: const Color(0xFF0D66CC),
                                      onChanged: (val) {
                                        setState(() => _isGpsAuto = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (_isGpsAuto) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 28,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  backgroundColor: const Color(0xFFE3EDFB),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: _isFetchingGps
                                    ? null
                                    : _ambilKoordinatGps,
                                icon: _isFetchingGps
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh,
                                        size: 14, color: Color(0xFF0D66CC)),
                                label: Text(
                                  _isFetchingGps
                                      ? "Mengambil..."
                                      : "Refresh GPS",
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF0D66CC)),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),
                        _buildCoordinateRow(
                            "Latitude", _latController, _isGpsAuto),
                        _buildCoordinateRow(
                            "Longitude", _longController, _isGpsAuto),

                        const Divider(
                            height: 14,
                            thickness: 0.6,
                            color: Color(0xFFEEEEEE)),

                        _buildEditableRow("PT/Perusahaan", _form2PtController),
                        _buildEditableRow("Blok / Site", _blokSiteController),
                        _buildEditableRow("Panel No", _panelNoController),
                        _buildEditableRow("Box No", _boxNoController),
                        _buildEditableRow("Rainfall S/N", _rainfallSnController),
                        _buildEditableRow(
                            "Water Level S/N", _waterLevelSnController),
                        _buildEditableRow(
                            "Soil Moisture S/N", _soilMoistureSnController),

                        const Divider(
                            height: 14,
                            thickness: 0.6,
                            color: Color(0xFFEEEEEE)),

                        // Dropdown Starlink / GSM
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Pilihan Koneksi",
                                style: TextStyle(
                                  color: Color(0xFF222222),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedKoneksi,
                                  isDense: true,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      size: 18, color: Color(0xFF0D66CC)),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "Starlink",
                                      child: Text("Starlink",
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    DropdownMenuItem(
                                      value: "GSM",
                                      child: Text("GSM",
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedKoneksi = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_selectedKoneksi == "Starlink") ...[
                          _buildEditableRow(
                              "Starlink Kit S/N", _starlinkKitSnController),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 4,
                                  child: Text(
                                    "GSM",
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: TextField(
                                    controller: _gsmNoController,
                                    textAlign: TextAlign.right,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                      color: Color(0xFF111111),
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 4),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _gsmChecked,
                                    fillColor: WidgetStateProperty.resolveWith(
                                        (states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return const Color(0xFF009640);
                                      }
                                      return null;
                                    }),
                                    onChanged: (val) {
                                      setState(
                                          () => _gsmChecked = val ?? false);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. BAGIAN BERDAMPINGAN: Parameter Pengukuran & Foto Instalasi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kiri: Parameter Pengukuran
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.speed,
                                      color: Color(0xFFD3681D), size: 24),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "PARAMETER\nPENGUKURAN",
                                      style: TextStyle(
                                        color: Color(0xFF9E480C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildParamBoxEditable(
                                title: "No Panel TMAT BOX",
                                controller: _panelBoxParamController,
                              ),
                              const SizedBox(height: 8),
                              _buildParamField(
                                label: "Soil Moisture",
                                controller: _soilMoistureController,
                                hintText: "45.2%",
                              ),
                              const SizedBox(height: 8),
                              _buildParamField(
                                label: "Water Level",
                                controller: _waterLevelController,
                                hintText: "120 cm",
                              ),
                              const SizedBox(height: 8),
                              _buildParamField(
                                label: "Rainfall",
                                controller: _rainfallController,
                                hintText: "15 mm",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Kanan: Grid 9 Foto
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "FOTO INSTALASI TMAT",
                                style: TextStyle(
                                  color: Color(0xFF5D2D8F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Unggah 5 foto dokumentasi",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _photoSlots.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 5,
                                  childAspectRatio: 0.85,
                                ),
                                itemBuilder: (context, index) {
                                  final slot = _photoSlots[index];
                                  final isFilled =
                                      _uploadedPhotos[index] ?? false;
                                  return InkWell(
                                    onTap: () => _simulasiPilihFoto(index),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isFilled
                                            ? const Color(0xFFE2F4E7)
                                            : const Color(0xFFEFF6FF),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isFilled
                                              ? const Color(0xFF009640)
                                              : const Color(0xFF6B9ED8),
                                          width: 0.9,
                                          strokeAlign:
                                              BorderSide.strokeAlignInside,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isFilled ? "✓" : slot["num"]!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isFilled
                                                  ? const Color(0xFF009640)
                                                  : const Color(0xFF0D66CC),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            slot["label"]!,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 7.2,
                                              color: Color(0xFF444444),
                                              height: 1.05,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. TOMBOL KIRIM LAPORAN / SIMPAN OFFLINE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOnline
                            ? const Color(0xFF009640)
                            : const Color(0xFFD97706),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _kirimLaporan,
                      icon: Icon(
                        _isOnline ? Icons.send_outlined : Icons.save_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        _isOnline ? "KIRIM LAPORAN" : "SIMPAN OFFLINE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildCoordinateRow(
      String label, TextEditingController controller, bool isAuto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAuto)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child:
                        Icon(Icons.lock_outline, size: 13, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: TextField(
              controller: controller,
              readOnly: isAuto,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color:
                    isAuto ? const Color(0xFF0D66CC) : const Color(0xFF111111),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        isAuto ? Colors.transparent : const Color(0xFF0D66CC),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF222222),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                color: Color(0xFF111111),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0D66CC), width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamBoxEditable({
    required String title,
    required TextEditingController controller,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          TextField(
            controller: controller,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 2),
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0D66CC), width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                border: InputBorder.none,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0D66CC), width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// SCREEN 2: SUCCESS SCREEN
// =========================================================================
class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const SuccessScreen({super.key, required this.reportData});

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tgl = reportData["tanggal"] ?? "-";
    final jam = reportData["jam"] ?? "-";
    final lat = reportData["latitude"] ?? "-";
    final long = reportData["longitude"] ?? "-";
    final modeGps = reportData["mode_gps"] ?? "Auto";
    final boxNo = reportData["box_no"] ?? reportData["nomor_box"] ?? "-";
    final site = reportData["blok_site"] ?? reportData["nama_site"] ?? "-";
    final pt = reportData["pt_perusahaan"] ?? reportData["nama_perusahaan"] ?? "-";
    final koneksi = reportData["jenis_koneksi"] ?? "Starlink";

    final sm = reportData["param_soil_moisture"] ?? "-";
    final wl = reportData["param_water_level"] ?? "-";
    final rf = reportData["param_rainfall"] ?? "-";

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "STATUS PENGIRIMAN",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF0D66CC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00B24D),
                size: 72,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Laporan Berhasil Terkirim!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Data instalasi telah dicatat ke Google Sheets & Google Drive",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Ringkasan Instalasi",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D66CC),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F4E7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "TERVERIFIKASI",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF009640),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFEEEEEE)),

                    _buildSummaryRow(
                      icon: Icons.my_location,
                      title: "Koordinat ($modeGps GPS)",
                      content: Text(
                        "Lat: $lat\nLong: $long",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      icon: Icons.business,
                      title: "Perusahaan & Lokasi",
                      content: Text(
                        "$pt • $site",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      icon: Icons.developer_board,
                      title: "Perangkat Terpasang",
                      content: Text(
                        "Box: $boxNo • Koneksi: $koneksi",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSummaryRow(
                      icon: Icons.speed,
                      title: "Parameter Pengukuran",
                      content: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildChipData("Soil Moisture: $sm", Colors.teal),
                          _buildChipData("Water Level: $wl", Colors.blue),
                          _buildChipData("Rainfall: $rf", Colors.indigo),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF009640), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showInfoSnackBar(
                        context, "Simulasi: Membuka WhatsApp Group Lapangan"),
                    icon: const Icon(Icons.chat,
                        color: Color(0xFF009640), size: 18),
                    label: const Text(
                      "WA Group",
                      style: TextStyle(
                          color: Color(0xFF009640),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF0D66CC), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showInfoSnackBar(
                        context, "Simulasi: Membuka Google Sheet Hasil Laporan"),
                    icon: const Icon(Icons.table_chart,
                        color: Color(0xFF0D66CC), size: 18),
                    label: const Text(
                      "Google Sheet",
                      style: TextStyle(
                          color: Color(0xFF0D66CC),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009640),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/form');
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  "Buat Laporan Baru",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Waktu submit: $tgl • $jam",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0D66CC), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              const SizedBox(height: 2),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipData(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.shade700,
        ),
      ),
    );
  }
}
