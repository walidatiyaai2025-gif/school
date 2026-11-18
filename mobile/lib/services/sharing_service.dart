import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_store.dart';
import '../data/models.dart';

class SharingService {
  const SharingService(this.store);
  final AppStore store;
  Future<void> open(PdfRecord record) async {
    if(!await File(record.path).exists()) throw const FileSystemException('PDF was deleted');
    final result=await OpenFilex.open(record.path,type:'application/pdf');
    if(result.type!=ResultType.done) throw FileSystemException(result.message);
  }
  Future<void> share(PdfRecord record,BuildContext context) async {
    if(!await File(record.path).exists()) throw const FileSystemException('PDF was deleted');
    final box=context.findRenderObject() as RenderBox?;
    // Share Plus uses OS share sheet. Count openings/attempts, NEVER claim delivery.
    await SharePlus.instance.share(ShareParams(
      files:[XFile(record.path,mimeType:'application/pdf',name:record.filename)],
      sharePositionOrigin:box==null?null:box.localToGlobal(Offset.zero)&box.size,
    ));
    await store.noteShareOpened(record.id);
  }
  Future<void> export(PdfRecord record) async {
    if(!await File(record.path).exists()) throw const FileSystemException('PDF was deleted');
    // Native Save to Files / print share sheet. No public-storage permission.
    await Printing.sharePdf(bytes:await File(record.path).readAsBytes(),filename:record.filename);
  }
}
