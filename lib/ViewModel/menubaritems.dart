import 'dart:io';

import 'package:comparatorr/View/howToUse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:menu_bar/menu_bar.dart';

class Menubaritems {
  List<BarButton> menuBarItems = [
    BarButton(
      text: const Text(
        'Dosya',
        style: TextStyle(color: Colors.white),
      ),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            onTap: () => print('Kaydet'),
            text: const Text('Kaydet'),
            shortcutText: 'Ctrl+S',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyS, control: true),
          ),
          MenuButton(
            onTap: () {},
            text: const Text('Farklı Kaydet...'),
            shortcutText: 'Ctrl+Shift+S',
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            text: const Text('Dosya Aç'),
          ),
          MenuButton(
            onTap: () {},
            text: const Text('Klasör Aç'),
          ),
          const MenuDivider(),
          MenuButton(
            text: const Text('Seçenekler'),
            icon: const Icon(Icons.settings),
            submenu: SubMenu(
              menuItems: [
                MenuButton(
                  onTap: () {},
                  icon: const Icon(Icons.keyboard),
                  text: const Text('Kısayollar'),
                ),
                const MenuDivider(),
                MenuButton(
                  onTap: () {},
                  icon: const Icon(Icons.extension),
                  text: const Text('Eklentiler'),
                ),
                const MenuDivider(),
                MenuButton(
                  icon: const Icon(Icons.looks),
                  text: const Text('Tema'),
                  submenu: SubMenu(
                    menuItems: [
                      MenuButton(
                        onTap: () {
                          Get.changeThemeMode(ThemeMode.light);
                        },
                        icon: const Icon(Icons.light_mode),
                        text: const Text('Açık tema'),
                      ),
                      const MenuDivider(),
                      MenuButton(
                        onTap: () {
                          Get.changeThemeMode(ThemeMode.dark);
                        },
                        icon: const Icon(Icons.dark_mode),
                        text: const Text('Koyu tema'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {
              exit(0);
            },
            shortcutText: 'Ctrl+Q',
            text: const Text('Çıkış'),
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
    ),
    BarButton(
      text: const Text(
        'Düzenle',
        style: TextStyle(color: Colors.white),
      ),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            onTap: () {},
            text: const Text('Geri Al'),
            shortcutText: 'Ctrl+Z',
          ),
          MenuButton(
            onTap: () {},
            text: const Text('İleri Al'),
            shortcutText: 'Ctrl+Y',
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            text: const Text('Kes'),
            shortcutText: 'Ctrl+X',
          ),
          MenuButton(
            onTap: () {},
            text: const Text('Kopyala'),
            shortcutText: 'Ctrl+C',
          ),
          MenuButton(
            onTap: () {},
            text: const Text('Yapıştır'),
            shortcutText: 'Ctrl+V',
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            text: const Text('Bul...'),
            shortcutText: 'Ctrl+F',
          ),
        ],
      ),
    ),
    BarButton(
      text: const Text(
        'Yardım',
        style: TextStyle(color: Colors.white),
      ),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            onTap: () {
              Get.to(Howtouse());
            },
            text: const Text('Nasıl Kullanılır?'),
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            text: const Text('Lisansı Görüntüle'),
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            icon: const Icon(Icons.info),
            text: const Text('Hakkında'),
          ),
        ],
      ),
    ),
  ];
  final MenuStyle _barstyle = const MenuStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.zero),
    backgroundColor: WidgetStatePropertyAll(Color(0xFF2b2b2b)),
    maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
  );
}
