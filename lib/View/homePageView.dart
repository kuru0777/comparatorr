import 'package:comparatorr/ViewModel/homePageViewModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final PickFileViewModel pickFileViewModel = Get.put(PickFileViewModel());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Hello World!'),
            ElevatedButton(
              onPressed: () {
                pickFileViewModel.pickFile();
              },
              child: const Text('İçeri Aktar'),
            ),
          ],
        ),
      ),
    );
  }
}
