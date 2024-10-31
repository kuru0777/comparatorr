import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menu_bar/menu_bar.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BarButton> _menuBarButtons() {
    return [
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
              text: const Text('Kaydet...'),
              shortcutText: 'Ctrl+Shift+S',
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () {},
              text: const Text('Dosya Aç'),
            ),
            MenuButton(
              onTap: () {},
              text: const Text('Klasçör Aç'),
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
                    text: const Text('Tema Değiştir'),
                    submenu: SubMenu(
                      menuItems: [
                        MenuButton(
                          onTap: () {},
                          icon: const Icon(Icons.light_mode),
                          text: const Text('Açık Tema'),
                        ),
                        const MenuDivider(),
                        MenuButton(
                          onTap: () {},
                          icon: const Icon(Icons.dark_mode),
                          text: const Text('Koyu Tema'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const MenuDivider(),
            MenuButton(
              onTap: () {},
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
          'Help',
          style: TextStyle(color: Colors.white),
        ),
        submenu: SubMenu(
          menuItems: [
            MenuButton(
              onTap: () {},
              text: const Text('Güncellemeleri Kontrol Et'),
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Style the menus. Hover over [MenuStyle] for all the options
      theme: ThemeData(
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            padding:
                WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16.0)),
          ),
        ),
      ),

      home: MenuBarWidget(
        // Add a list of [BarButton]. The buttons in this List are
        // displayed as the buttons on the bar itself
        barButtons: _menuBarButtons(),

        // Style the menu bar itself. Hover over [MenuStyle] for all the options
        barStyle: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(Color(0xFF2b2b2b)),
          maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
        ),

        // Style the menu bar buttons. Hover over [ButtonStyle] for all the options
        barButtonStyle: const ButtonStyle(
          padding:
              WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6.0)),
          minimumSize: WidgetStatePropertyAll(Size(0.0, 32.0)),
        ),

        // Style the menu and submenu buttons. Hover over [ButtonStyle] for all the options
        menuButtonStyle: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(36.0)),
          padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0)),
        ),

        // Enable or disable the bar
        enabled: true,

        // Set the child, i.e. the application under the menu bar
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Menu Bar Example'),
          ),
          body: const Center(
            child: Text(
              'My application',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
