import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/main.dart';
import 'package:wallet/providers/ethereum_provider.dart';
import 'package:wallet/utils/format.dart';
import 'package:wallet/screens/nav/_nav.dart';
import 'package:wallet/utils/localization.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late EthereumProvider ethereumProvider;
  int _currentIndex = 0;
  String network = 'Ethereum';

  final List<Widget> _pages = [
    HomeScreen(),
    CollectionScreen(),
    HistoryScreen(),
    LastScreen()
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ethereumProvider = Provider.of<EthereumProvider>(context);
  }

  @override
  void dispose() {
    super.dispose();
    ethereumProvider.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var address = ethereumProvider.walletModel!.getAddress;
    List<ListTile> wallets = [];
    for (var i = 0; i < ethereumProvider.wallets.length; i++) {
      bool isSelected =
          ethereumProvider.currentWalletIndex == i; // Kiểm tra ví hiện tại
      wallets.add(
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFF9886E5), // Màu nền
            child: Text(
              'V${i + 1}'[0], // Lấy chữ cái đầu của "Ví 1", "Ví 2",...
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Chữ màu trắng
              ),
            ),
          ),
          title: Text('Wallet ${i + 1}', style: TextStyle(color: Colors.black)),
          subtitle: Text(AddressFormat.formatAddress(
              ethereumProvider.wallets[i].address ?? '0x123...789')),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              if (ethereumProvider.wallets.length > 1) {
                setState(() {
                  ethereumProvider.wallets.removeAt(i);
                });
                ethereumProvider.saveVault(ethereumProvider.wallets);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Wallet ${i + 1} xóa thành công!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể xóa ví')),
                );
              }
            },
          ),
          onTap: () {
            ethereumProvider.switchWallet(i);
            Navigator.pop(context);
          },
        ),
      );
    }

    wallets.add(
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.add, color: Colors.green),
        ),
        title: Text(
          AppLocalizations.of(context).translate("add_wallet"),
          style: TextStyle(color: Colors.black), // White text
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );

    return Scaffold(
      backgroundColor:
          const Color.fromRGBO(48, 48, 48, 1.0), // Darker background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: const Color.fromRGBO(48, 48, 48, 1.0), // Darker AppBar
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                38, 38, 38, 1.0), // Modal background
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: wallets,
                                ),
                              ),
                              Divider(color: Colors.grey), // Divider color
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF9886E5),
                    child: Text(
                      'V${ethereumProvider.currentWalletIndex + 1}',
                      style: TextStyle(color: Colors.black), // Text color
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate("wallet"),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white, // White text
                      ),
                    ),
                    Text(
                      AddressFormat.formatAddress(address),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white, // Light grey text
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  dropdownColor: const Color.fromRGBO(
                      38, 38, 38, 1.0), // Dropdown background
                  value: network,
                  items: ['Ethereum', 'Solana', 'Polygon'].map((String choice) {
                    return DropdownMenuItem<String>(
                      value: choice,
                      child: Text(
                        choice,
                        style: TextStyle(color: Colors.white), // White text
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        network = newValue;
                      });
                    }
                  },
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner,
                      color: const Color(0xFF9886E5)), // White icon
                  onPressed: () {},
                ),
                PopupMenuButton(
                  color:
                      const Color.fromRGBO(38, 38, 38, 1.0), // Popup background
                  icon: Icon(Icons.settings,
                      color: const Color(0xFF9886E5)), // White icon
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.language, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)
                                .translate("switch_language"),
                            style: TextStyle(color: Colors.white), // White text
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: const Color.fromRGBO(
                                  38, 38, 38, 1.0), // Dialog background
                              title: Text(
                                AppLocalizations.of(context)
                                    .translate("select_language"),
                                style: TextStyle(
                                    color: Colors.white), // White text
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text(
                                      AppLocalizations.of(context)
                                          .translate("english"),
                                      style: TextStyle(
                                          color: Colors.white), // White text
                                    ),
                                    onTap: () {
                                      MyApp.setLocale(
                                          context, Locale('en', ''));
                                      setState(() {}); // Update UI
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: Text(
                                      AppLocalizations.of(context)
                                          .translate("vietnamese"),
                                      style: TextStyle(
                                          color: Colors.white), // White text
                                    ),
                                    onTap: () {
                                      MyApp.setLocale(
                                          context, Locale('vi', ''));
                                      setState(() {}); // Update UI
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).translate("settings"),
                            style: TextStyle(color: Colors.white), // White text
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).translate("logout"),
                            style: TextStyle(color: Colors.white), // White text
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đăng xuất thành công"),
                            backgroundColor: const Color(0xFF9886E5),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            const Color.fromRGBO(38, 38, 38, 1.0), // Darker background
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9886E5), // Selected item color
        unselectedItemColor: Colors.grey, // Unselected item color
        selectedFontSize: 14,
        unselectedFontSize: 12,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context).translate("home"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: AppLocalizations.of(context).translate("collection"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: AppLocalizations.of(context).translate("history"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.network_check),
            label: AppLocalizations.of(context).translate("network"),
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
