import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// true = ada tombol "Keluar (mode uji)" untuk testing. Ubah ke false untuk versi asli.
const bool modeUji = true;

const _ch = MethodChannel('fokus/lock');
Future<dynamic> native(String m) async {
  try {
    return await _ch.invokeMethod(m);
  } catch (_) {
    return null; // di DartPad/web tidak ada kode native
  }
}

// Periksa kembali teks ayat dengan mushaf sebelum dipakai serius.
const Map<String, List<String>> surahData = {
  'Al-Ikhlas': [
    'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
    'ٱللَّهُ ٱلصَّمَدُ',
    'لَمْ يَلِدْ وَلَمْ يُولَدْ',
    'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
  ],
  'Al-Falaq': [
    'قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ',
    'مِن شَرِّ مَا خَلَقَ',
    'وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ',
    'وَمِن شَرِّ ٱلنَّفَّٰثَٰتِ فِى ٱلْعُقَدِ',
    'وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
  ],
  'An-Nas': [
    'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
    'مَلِكِ ٱلنَّاسِ',
    'إِلَٰهِ ٱلنَّاسِ',
    'مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ',
    'ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ',
    'مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ',
  ],
  'Al-Kautsar': [
    'إِنَّآ أَعْطَيْنَٰكَ ٱلْكَوْثَرَ',
    'فَصَلِّ لِرَبِّكَ وَٱنْحَرْ',
    'إِنَّ شَانِئَكَ هُوَ ٱلْأَبْتَرُ',
  ],
};

void main() => runApp(const FokusHafalanApp());

class FokusHafalanApp extends StatelessWidget {
  const FokusHafalanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Fokus Hafalan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: const Color(0xFF1B6B50), useMaterial3: true),
        home: const SetupPage(),
      );
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool byTimer = true;
  double minutes = 1;
  String surah = 'Al-Falaq';
  double target = 3;

  @override
  Widget build(BuildContext context) {
    final maxAyat = surahData[surah]!.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Fokus Hafalan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: surah,
            decoration: const InputDecoration(labelText: 'Surah'),
            items: surahData.keys
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() {
              surah = v!;
              target = min(target, surahData[surah]!.length.toDouble());
            }),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Timer')),
              ButtonSegment(value: false, label: Text('Target hafalan')),
            ],
            selected: {byTimer},
            onSelectionChanged: (s) => setState(() => byTimer = s.first),
          ),
          const SizedBox(height: 16),
          if (byTimer) ...[
            Text('Durasi fokus: ${minutes.round()} menit',
                style: const TextStyle(fontSize: 18)),
            Slider(
                value: minutes,
                min: 1,
                max: 120,
                divisions: 119,
                onChanged: (v) => setState(() => minutes = v)),
            const Text(
                'Surah ditampilkan selama timer. Kamu boleh menguji hafalan kapan saja, '
                'tapi kunci tetap terbuka saat waktu habis walau tidak menguji.'),
          ] else ...[
            Text('Target: ${target.round()} ayat harus lolos tes',
                style: const TextStyle(fontSize: 18)),
            Slider(
                value: target,
                min: 1,
                max: maxAyat.toDouble(),
                divisions: maxAyat > 1 ? maxAyat - 1 : null,
                onChanged: (v) => setState(() => target = v)),
            const Text('Kunci baru terbuka setelah semua ayat target lolos tes.'),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.lock),
            label: const Text('Mulai Fokus & Kunci'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FocusPage(
                  byTimer: byTimer,
                  minutes: minutes.round(),
                  surah: surah,
                  target: target.round()),
            )),
          ),
          const SizedBox(height: 8),
          const Text(
              'Android akan menampilkan dialog "pin layar". Pilih Mulai / Got it.',
              style: TextStyle(fontSize: 12)),
          TextButton(
            onPressed: () => native('dndSettings'),
            child: const Text('Izinkan mode Jangan Ganggu (opsional)'),
          ),
        ],
      ),
    );
  }
}

class FocusPage extends StatefulWidget {
  final bool byTimer;
  final int minutes;
  final String surah;
  final int target;
  const FocusPage(
      {super.key,
      required this.byTimer,
      required this.minutes,
      required this.surah,
      required this.target});
  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? _timer;
  late int _left;
  int _i = 0;
  bool _testing = false, _done = false, _passed = false;
  List<String> _words = [];
  List<int> _order = [];
  final List<int> _picked = [];
  String? _msg;

  List<String> get _ayat => surahData[widget.surah]!;
  int get _count => widget.byTimer ? _ayat.length : widget.target;

  @override
  void initState() {
    super.initState();
    native('start');
    _left = widget.minutes * 60;
    if (widget.byTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_left <= 1) {
          setState(() => _left = 0);
          _finish();
        } else {
          setState(() => _left--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    _timer?.cancel();
    await native('stop');
    if (mounted) setState(() => _done = true);
  }

  void _prepare() {
    _words = _ayat[_i].split(' ');
    _order = List.generate(_words.length, (k) => k)..shuffle(Random());
    _picked.clear();
    _msg = null;
  }

  void _startTest() {
    _prepare();
    setState(() => _testing = true);
  }

  void _check() {
    if (_picked.map((k) => _words[k]).join(' ') != _ayat[_i]) {
      setState(() {
        _msg = 'Belum tepat, coba susun lagi ya.';
        _picked.clear();
      });
      return;
    }
    if (_i + 1 >= _count) {
      if (widget.byTimer) {
        setState(() {
          _passed = true;
          _testing = false;
          _i = 0;
        });
      } else {
        _finish();
      }
    } else {
      _i++;
      if (widget.byTimer) {
        _prepare();
        setState(() {});
      } else {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _exit() async {
    _timer?.cancel();
    await native('stop');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _done,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Icon(_done ? Icons.lock_open : Icons.lock),
          title: Text(_done ? 'Terbuka' : 'Terkunci · ${widget.surah}'),
          actions: [
            if (modeUji && !_done)
              TextButton(
                  onPressed: _exit, child: const Text('Keluar (mode uji)')),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _done
              ? _buildDone()
              : _testing
                  ? _buildTest()
                  : (widget.byTimer ? _buildTimer() : _buildStudy()),
        ),
      ),
    );
  }

  Widget _buildDone() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Alhamdulillah, fokusmu selesai!',
              style: TextStyle(fontSize: 22), textAlign: TextAlign.center),
          if (_passed) const Text('Tes hafalan: lulus ✓'),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai')),
        ]),
      );

  Widget _buildTimer() {
    final m = (_left ~/ 60).toString().padLeft(2, '0');
    final s = (_left % 60).toString().padLeft(2, '0');
    return Column(children: [
      Text('$m:$s',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
      if (_passed) const Chip(label: Text('Tes hafalan lulus ✓')),
      Expanded(
        child: ListView.separated(
          itemCount: _ayat.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, k) => Directionality(
            textDirection: TextDirection.rtl,
            child: Text('${_ayat[k]} ﴿${k + 1}﴾',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, height: 2)),
          ),
        ),
      ),
      FilledButton(
          onPressed: () {
            _i = 0;
            _startTest();
          },
          child: const Text('Uji hafalan (opsional)')),
    ]);
  }

  Widget _buildStudy() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ayat ${_i + 1} dari $_count', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(_ayat[_i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, height: 2)),
          ),
          const SizedBox(height: 24),
          const Text('Baca berulang sampai hafal, lalu mulai tes.',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: _startTest,
              child: const Text('Saya sudah hafal, tes')),
        ],
      );

  Widget _buildTest() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tes ayat ${_i + 1} dari $_count',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Susun kata sesuai urutan ayat.',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12)),
            child: Wrap(
              textDirection: TextDirection.rtl,
              spacing: 8,
              runSpacing: 8,
              children: _picked
                  .map((k) => InputChip(
                        label:
                            Text(_words[k], style: const TextStyle(fontSize: 22)),
                        onPressed: () => setState(() => _picked.remove(k)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            textDirection: TextDirection.rtl,
            spacing: 8,
            runSpacing: 8,
            children: _order
                .where((k) => !_picked.contains(k))
                .map((k) => ActionChip(
                      label:
                          Text(_words[k], style: const TextStyle(fontSize: 22)),
                      onPressed: () => setState(() {
                        _picked.add(k);
                        _msg = null;
                      }),
                    ))
                .toList(),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_msg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ),
          const Spacer(),
          FilledButton(
              onPressed: _picked.length == _words.length ? _check : null,
              child: const Text('Periksa')),
          TextButton(
              onPressed: () => setState(() => _testing = false),
              child: Text(widget.byTimer ? 'Kembali ke bacaan' : 'Lihat ayat lagi')),
        ],
      );
}
