import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../state/finance_controller.dart';

class _CategoryGroup {
  _CategoryGroup(this.category, this.items, this.total);

  final Category category;
  final List<Transaction> items;
  final double total;
}

class PdfReportService {
  Future<File> buildCategoryReport({
    required FinanceController finance,
    required List<String> categoryIds,
    required DateTime from,
    required DateTime to,
    required String periodLabel,
    required String symbol,
  }) async {
    final List<_CategoryGroup> groups = _groups(finance, categoryIds, from, to);
    double grandTotal = 0;
    for (final _CategoryGroup g in groups) {
      grandTotal += g.total;
    }

    final pw.Document doc = pw.Document();
    pw.ThemeData? theme;
    try {
      final pw.Font base =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-400.ttf'));
      final pw.Font bold =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-700.ttf'));
      theme = pw.ThemeData.withFont(base: base, bold: bold);
    } catch (_) {
      theme = null;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        header: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text('ZOOM - Relatório por categoria',
                style: const pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text('Período: $periodLabel',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
            pw.Text(
                'Gerado em ${DateHelpers.dateTime.format(DateTime.now())}',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            pw.Divider(),
          ],
        ),
        footer: (pw.Context ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
        ),
        build: (pw.Context ctx) => <pw.Widget>[
          if (groups.isEmpty)
            pw.Text('Nenhum lançamento encontrado neste período.'),
          ...groups.map((_CategoryGroup g) => _groupBlock(g, symbol)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text('Total geral',
                  style: const pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                Money.format(grandTotal, '', symbol: symbol),
                style: const pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );

    final Directory dir = await getTemporaryDirectory();
    final File file = File(
        '${dir.path}${Platform.pathSeparator}relatorio_zoom_categorias.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  List<_CategoryGroup> _groups(
    FinanceController finance,
    List<String> categoryIds,
    DateTime from,
    DateTime to,
  ) {
    final List<_CategoryGroup> groups = <_CategoryGroup>[];
    for (final String id in categoryIds) {
      final Category? c = finance.categoryById(id);
      if (c == null) continue;
      final List<Transaction> items =
          finance.filtered(categoryId: id, from: from, to: to)
            ..sort((Transaction a, Transaction b) =>
                a.date.compareTo(b.date));
      if (items.isEmpty) continue;
      double total = 0;
      for (final Transaction t in items) {
        total += t.signedAmount;
      }
      groups.add(_CategoryGroup(c, items, total));
    }
    groups.sort((_CategoryGroup a, _CategoryGroup b) =>
        a.category.name.toLowerCase().compareTo(b.category.name.toLowerCase()));
    return groups;
  }

  pw.Widget _groupBlock(_CategoryGroup g, String symbol) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(g.category.name,
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfColor(g.category.colorHex))),
              pw.Text(Money.format(g.total, '', symbol: symbol),
                  style: const pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        ...g.items.map(
          (Transaction t) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              children: <pw.Widget>[
                pw.SizedBox(
                    width: 70,
                    child: pw.Text(DateHelpers.full.format(t.date),
                        style: const pw.TextStyle(fontSize: 10))),
                pw.Expanded(
                  child: pw.Text(
                    t.description.trim().isEmpty
                        ? g.category.name
                        : t.description,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Text(
                  '${t.type == TransactionType.income ? '+' : '-'} '
                  '${Money.format(t.amount.abs(), '', symbol: symbol)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: t.type == TransactionType.income
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  PdfColor _pdfColor(String hex) {
    String value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final int parsed = int.tryParse(value, radix: 16) ?? 0xFF6C5CE7;
    return PdfColor.fromInt(parsed);
  }
}
