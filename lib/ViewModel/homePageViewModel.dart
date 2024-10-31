import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class PickFileViewModel extends GetxController {
  // Dosyaları tutacak bir liste
  final RxList<File> files = <File>[].obs;

  Future<void> pickFile() async {
    try {
      // Dosya seçim işlemini başlat
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null) {
        // Seçilen dosyaları File tipine çevirip listeye ekle
        files.value = result.paths.map((path) => File(path!)).toList();
        print("Seçilen dosyalar: ${files.map((file) => file.path).join(", ")}");
      } else {
        // Kullanıcı dosya seçim işlemini iptal etti
        print("Dosya seçimi iptal edildi.");
      }
    } catch (e) {
      // Hata durumunu ele al
      print("Dosya seçimi sırasında hata oluştu: $e");
    }
  }
}
