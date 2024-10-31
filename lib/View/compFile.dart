import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';

class CompfilePage extends StatefulWidget {
  final String title;
  const CompfilePage({super.key, required this.title});

  @override
  State<CompfilePage> createState() => _CompfilePageState();
}

class _CompfilePageState extends State<CompfilePage> {
  RxList<File>? data;
  late String firstFileName;
  late String secondFileName;
  late final Rx<TextEditingController> _oldTextEditingController;
  late final Rx<TextEditingController> _newTextEditingController;
  late final Rx<TextEditingController> _diffTimeoutEditingController;
  late final Rx<TextEditingController> _editCostEditingController;
  Rx<DiffCleanupType> _diffCleanupType =
      Rx<DiffCleanupType>(DiffCleanupType.SEMANTIC);

  @override
  void initState() {
    super.initState();
    _oldTextEditingController = Rx<TextEditingController>(
      TextEditingController(
        text: (Get.arguments['firstText'] ?? "Eski metin bulunamadı") as String,
      ),
    );
    _newTextEditingController = Rx<TextEditingController>(
      TextEditingController(
        text:
            (Get.arguments['secondText'] ?? "Yeni metin bulunamadı") as String,
      ),
    );
    firstFileName = Get.arguments['firstFileName'] ?? "Dosya Adı Bulunamadı";
    secondFileName = Get.arguments['secondFileName'] ?? "Dosya Adı Bulunamadı";
    _diffTimeoutEditingController =
        Rx<TextEditingController>(TextEditingController(text: "1.0"));
    _editCostEditingController =
        Rx<TextEditingController>(TextEditingController(text: "4"));
  }

  Widget build(BuildContext context) {
    data = Get.arguments is RxList<File> ? Get.arguments as RxList<File> : null;

    return Scaffold(
      appBar: AppBar(title: Text("Karşılaştırma Raporu")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() => TextField(
                          controller: _oldTextEditingController.value,
                          maxLines: 5,
                          onChanged: (string) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: firstFileName,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        )),
                  ),
                  Container(
                    width: 5,
                  ),
                  Expanded(
                    child: Obx(() => TextField(
                          controller: _newTextEditingController.value,
                          maxLines: 5,
                          onChanged: (string) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: secondFileName,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        )),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                margin: EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "--- Metin Karşılaştırılması ---",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Center(
                        child: Obx(() => PrettyDiffText(
                              textAlign: TextAlign.center,
                              oldText: _oldTextEditingController.value.text,
                              newText: _newTextEditingController.value.text,
                              diffCleanupType: _diffCleanupType.value,
                              diffTimeout: diffTimeoutToDouble(),
                              diffEditCost: editCostToDouble(),
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Row(children: [
                Text(
                  "Diff timeout: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 40,
                  height: 30,
                  child: Obx(() => TextField(
                        keyboardType: TextInputType.number,
                        controller: _diffTimeoutEditingController.value,
                        onChanged: (string) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      )),
                ),
                Text(" seconds"),
              ]),
            ),
            Text(
              "If the mapping phase of the diff computation takes longer than this, then the computation is truncated and the best solution to date is returned. While guaranteed to be correct, it may not be optimal. A timeout of '0' allows for unlimited computation.",
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 3),
              child: Text(
                "Post-diff cleanup:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Obx(() => RadioListTile(
                title: Text("Semantic Cleanup"),
                subtitle: Text(
                    "Increase human readability by factoring out commonalities which are likely to be coincidental"),
                value: DiffCleanupType.SEMANTIC,
                groupValue: _diffCleanupType.value,
                onChanged: (DiffCleanupType? value) {
                  _diffCleanupType.value = value!;
                })),
            Obx(() => RadioListTile(
                title: Row(
                  children: [
                    Text("Efficiency Cleanup. Edit cost: "),
                    SizedBox(
                        width: 40,
                        height: 30,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: _editCostEditingController.value,
                          onChanged: (string) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(5),
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ))
                  ],
                ),
                subtitle: Text(
                    "Increase computational efficiency by factoring out short commonalities which are not worth the overhead. The larger the edit cost, the more aggressive the cleanup"),
                value: DiffCleanupType.EFFICIENCY,
                groupValue: _diffCleanupType.value,
                onChanged: (DiffCleanupType? value) {
                  _diffCleanupType.value = value!;
                })),
            Obx(() => RadioListTile(
                title: Text("No Cleanup"),
                subtitle: Text("Raw output"),
                value: DiffCleanupType.NONE,
                groupValue: _diffCleanupType.value,
                onChanged: (DiffCleanupType? value) {
                  _diffCleanupType.value = value!;
                })),
          ],
        ),
      ),
    );
  }

  double diffTimeoutToDouble() {
    try {
      final response = double.parse(_diffTimeoutEditingController.value.text);
      ScaffoldMessenger.of(context).clearSnackBars();
      return response;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Enter a valid double value for edit cost")));
      });
      return 1.0; // default value for timeout
    }
  }

  int editCostToDouble() {
    try {
      final response = int.parse(_editCostEditingController.value.text);
      ScaffoldMessenger.of(context).clearSnackBars();
      return response;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Enter a valid integer value for edit cost")));
      });
      return 4; // default value for edit cost
    }
  }
}
