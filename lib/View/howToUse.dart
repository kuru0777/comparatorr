import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class Howtouse extends StatelessWidget {
  const Howtouse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.back();
            },
          ),
          title: const Text('Nasıl Kullanılır?'),
        ),
        body: Column(
          children: [
            const Center(
              child: Text('Nasıl Kullanılır?'),
            ),
          ],
        ));
  }
}
