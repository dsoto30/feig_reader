import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bindings/performance_counter.dart';
import 'viewmodels/feig_reader_viewmodel.dart';
import 'views/feig_reader_view.dart';

void main() {
  PerformanceCounter.init();
  runApp(const FeigReaderApp());
}

class FeigReaderApp extends StatelessWidget {
  const FeigReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FEIG Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29B6F6),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29B6F6),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: FeigReaderView(viewModel: FeigReaderViewModel()),
    );
  }
}
