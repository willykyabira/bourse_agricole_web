import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

/// Service permettant de générer les rapports
/// au format PDF et CSV.
class ReportService {
  // ================= RAPPORT PDF =================

  /// Génère un rapport au format PDF.
  static Future<void> generatePdf(
    String title,
    String content,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text('$title\n\n$content'),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  // ================= RAPPORT CSV =================

  /// Génère un fichier CSV téléchargeable.
  static Future<void> generateCsv(
    String filename,
    List<List<dynamic>> rows,
  ) async {
    final csv = const ListToCsvConverter().convert(rows);

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', '$filename.csv')
      ..click();
  }
}