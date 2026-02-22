import 'dart:typed_data';
import 'package:ecommerce_desktop/models/dashboard_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Generira 2 PDF izvještaja: Peak Hours i Weekly Reservations.
class PdfReportService {
  static final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  /// PDF 1: Peak Hours Analysis – rezervacije po satu
  static Future<Uint8List> generatePeakHoursReport(List<HourlyData> hourlyData) async {
    final pdf = pw.Document();
    final now = _dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Peak Hours Analysis Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 24),
            if (hourlyData.isEmpty)
              pw.Text('No hourly data available.')
            else ...[
              pw.Text(
                'Reservations by hour (last 30 days)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Hour', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Reservations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...hourlyData.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(e.hour)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${e.count}')),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 16),
              _buildPeakHourSummary(hourlyData),
            ],
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPeakHourSummary(List<HourlyData> hourlyData) {
    if (hourlyData.isEmpty) return pw.SizedBox.shrink();
    final maxEntry = hourlyData.reduce((a, b) => a.count >= b.count ? a : b);
    final total = hourlyData.fold<int>(0, (sum, e) => sum + e.count);
    final avg = hourlyData.isEmpty ? 0 : total / hourlyData.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Peak hour: ${maxEntry.hour} (${maxEntry.count} reservations)'),
          pw.Text('Total reservations: $total'),
          pw.Text('Average per hour: ${avg.toStringAsFixed(1)}'),
        ],
      ),
    );
  }

  /// PDF 2: Weekly Reservations – rezervacije po danu
  static Future<Uint8List> generateWeeklyReservationsReport(
    List<WeeklyOccupancyData> weeklyData,
    ReservationsSummary? summary,
  ) async {
    final pdf = pw.Document();
    final now = _dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Weekly Reservations Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 24),
            if (summary != null) ...[
              pw.Text('Overview', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total reservations: ${summary.total}'),
                  pw.Text('Confirmed: ${summary.confirmed}'),
                  pw.Text('Completed: ${summary.completed}'),
                ],
              ),
              pw.SizedBox(height: 24),
            ],
            pw.Text(
              'Reservations by day of week',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            if (weeklyData.isEmpty)
              pw.Text('No weekly data available.')
            else ...[
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Day', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Reservations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...weeklyData.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(e.day)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${e.reservationCount}')),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 16),
              _buildWeeklySummary(weeklyData),
            ],
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildWeeklySummary(List<WeeklyOccupancyData> weeklyData) {
    if (weeklyData.isEmpty) return pw.SizedBox.shrink();
    final total = weeklyData.fold<int>(0, (sum, e) => sum + e.reservationCount);
    final avg = total / weeklyData.length;
    final busiest = weeklyData.reduce((a, b) => a.reservationCount >= b.reservationCount ? a : b);
    final quietest = weeklyData.reduce((a, b) => a.reservationCount <= b.reservationCount ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Busiest day: ${busiest.day} (${busiest.reservationCount} reservations)'),
          pw.Text('Quietest day: ${quietest.day} (${quietest.reservationCount} reservations)'),
          pw.Text('Total: $total | Average per day: ${avg.toStringAsFixed(1)}'),
        ],
      ),
    );
  }
}
