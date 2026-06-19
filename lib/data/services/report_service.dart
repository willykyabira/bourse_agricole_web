import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;

class ReportService {
  // Générer un PDF (logique uniquement)
  static Future<void> generatePdf(String title, String content) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text('$title\n\n$content'))));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // Générer un CSV (logique uniquement)
  static Future<void> generateCsv(String filename, List<List<dynamic>> rows) async {
    String csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute("download", "$filename.csv")..click();
  }
}