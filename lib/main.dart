import 'dart:io';
import 'package:comparatorr/View/compFile.dart';
import 'package:comparatorr/View/doctotext.dart';
import 'package:comparatorr/ViewModel/menubaritems.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  var butonstyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.indigoAccent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32.0),
    ),
    textStyle: const TextStyle(fontSize: 16, color: Colors.white),
  );
  var textstyle = TextStyle(color: Colors.white);

  List<BarButton> _menuBarButtons() {
    return Menubaritems().menuBarItems;
  }

  @override
  Widget build(BuildContext context) {
    final RxList<File> files = <File>[].obs;
    final visible = false.obs;
    final procVisible = false.obs;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      getPages: [
        GetPage(
            name: '/compfile',
            page: () => CompfilePage(
                  key: const ValueKey('compfile'),
                  title: '',
                )),
        GetPage(name: '/doctotext', page: () => const DocToText())
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        menuTheme: const MenuThemeData(
          style: MenuStyle(
              padding:
                  WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16.0))),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.black87,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
        ),
        menuTheme: const MenuThemeData(
          style: MenuStyle(
              padding:
                  WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16.0))),
        ),
      ),
      themeMode:
          ThemeMode.system, // Sistemin temasını kullanır (light veya dark)
      home: MenuBarWidget(
        barButtons: _menuBarButtons(),
        barStyle: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(Color(0xFF2b2b2b)),
          maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
        ),
        barButtonStyle: const ButtonStyle(
          padding:
              WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6.0)),
          minimumSize: WidgetStatePropertyAll(Size(0.0, 32.0)),
        ),
        menuButtonStyle: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(36.0)),
          padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0)),
        ),
        enabled: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Ekstre Karşılaştırma'),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Yardım'),
                          content: const Text(
                              'Bu uygulama, iki adet dosyanın içeriğini karşılaştırır. Karşılaştırma sonucunda farklılıkların raporunu oluşturur.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Get.back();
                              },
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline_sharp),
                  ),
                ],
              )
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(() => Center(
                  child: /*visible.value ? */
                      Text(visible.value ? '' : 'Dosya seçilmedi.'))),
              ElevatedButton(
                style: butonstyle,
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                            allowMultiple: true,
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'xlsx']);

                    if (result != null) {
                      files.value = result.paths
                          .where((path) => path != null)
                          .map((path) => File(path!))
                          .toList();
                      visible.value = true;
                      print(
                          "Seçilen dosyalar: ${files.first.path.split('\\').last} "
                          "Seçilen dosyalar: ${files.last.path.split('\\').last}");

                      Get.snackbar('Bilgi', 'Dosya seçimi başarılı.',
                          backgroundColor: Colors.greenAccent,
                          colorText: Colors.black);
                    } else {
                      print("Dosya seçimi iptal edildi.");
                      Get.snackbar('UYARI', 'Dosya seçimi iptal edildi.',
                          backgroundColor: Colors.orangeAccent,
                          colorText: Colors.white);
                    }
                  } catch (e) {
                    print("Dosya seçimi sırasında hata oluştu: $e");
                    Get.snackbar(
                        'UYARI', 'Dosya seçimi sırasında hata oluştu: $e',
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white);
                  }
                },
                child: Text(
                  'Dosya Seç',
                  style: textstyle,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => SingleChildScrollView(
                  child: Column(
                    children: files.map((file) {
                      return ListTile(
                        title: Text(file.path.split('/').last),
                        leading: Icon(
                          file.path.endsWith('.pdf')
                              ? Icons.picture_as_pdf
                              : Icons.dashboard_outlined,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Obx(() => Visibility(
                  visible: visible.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                            style: butonstyle,
                            onPressed: () {
                              procVisible.value = true;
                              // İki dosya yolunu gönderiyoruz
                              Get.toNamed('/compfile',
                                  arguments:
                                      files.map((file) => file.path).toList());
                              procVisible.value = false;
                            },
                            child: procVisible.value
                                ? const CircularProgressIndicator(
                                    strokeWidth: 4,
                                    backgroundColor: Colors.amber,
                                    strokeCap: StrokeCap.round,
                                  )
                                : Text(
                                    'Dökümanı Metne Çevir',
                                    style: textstyle,
                                  )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: butonstyle,
                          onPressed: () {
                            if (files.isNotEmpty) {
                              // İlk dosya yolunu gönderiyoruz
                              Get.to(DocToText(), arguments: files);
                            } else {
                              Get.snackbar('UYARI', 'Lütfen bir dosya seçin.',
                                  backgroundColor: Colors.orangeAccent,
                                  colorText: Colors.white);
                            }
                          },
                          child: Text(
                            'Metin Çıkar',
                            style: textstyle,
                          ),
                        ),
                      ),
                    ],
                  ))),
            ],
          ),
        ),
      ),
    );
  }
}
