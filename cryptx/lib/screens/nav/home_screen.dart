import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wallet/providers/ethereum_provider.dart';
import 'package:wallet/providers/swap_provider.dart';
import 'package:wallet/screens/nav/_nav.dart';
import 'package:wallet/utils/localization.dart';
import 'package:wallet/widgets/token_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late EthereumProvider ethereumProvider;
  bool _initialized = false;
  bool _swapInitialized = false; // Track swap provider initialization
  String _lastWalletAddress = ''; // Track last wallet address
  double _lastBlockchainBalance = 0.0; // Track last blockchain balance

  // Helper function để lấy icon cho mỗi token
  IconData _getTokenIcon(String token) {
    switch (token) {
      case 'ETH':
        return Icons.currency_bitcoin; // Ethereum icon
      case 'USDT':
        return Icons.attach_money; // Dollar icon
      case 'BTC':
        return Icons.currency_bitcoin; // Bitcoin icon
      default:
        return Icons.monetization_on;
    }
  }

  // Helper function để lấy màu cho mỗi token
  Color _getTokenColor(String token) {
    switch (token) {
      case 'ETH':
        return Color(0xFF627EEA); // Ethereum blue
      case 'USDT':
        return Color(0xFF26A17B); // Tether green
      case 'BTC':
        return Color(0xFFF7931A); // Bitcoin orange
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ethereumProvider = Provider.of<EthereumProvider>(context);
    
    // Chỉ gọi fetchBalance một lần khi khởi tạo
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() async {
        await ethereumProvider.fetchBalance();
        await ethereumProvider.fetchPriceChange();
        
        // Sau khi fetch xong, sync balance sang SwapProvider
        final swapProvider = Provider.of<SwapProvider>(context, listen: false);
        final walletAddress = ethereumProvider.walletModel?.getAddress ?? '';
        final ethBalance = ethereumProvider.walletModel?.getEtherAmount ?? 0.0;
        
        if (walletAddress.isNotEmpty) {
          swapProvider.setCurrentWallet(walletAddress);
          swapProvider.updateEthBalance(walletAddress, ethBalance);
          print('[SYNC] Synced ETH balance to SwapProvider: $ethBalance ETH');
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapProvider = Provider.of<SwapProvider>(context);
    final walletAddress = ethereumProvider.walletModel?.getAddress ?? '';
    final ethBalance = ethereumProvider.walletModel?.getEtherAmount ?? 0.0;
    
    // Cập nhật wallet hiện tại trong SwapProvider
    // CHỈ gọi updateEthBalance khi:
    // 1. Switch wallet (wallet address thay đổi)
    // 2. Blockchain balance thay đổi (do fetch mới hoặc giao dịch)
    
    bool walletChanged = walletAddress.isNotEmpty && _lastWalletAddress != walletAddress;
    bool balanceChanged = ethBalance != _lastBlockchainBalance;
    
    if (walletChanged) {
      _lastWalletAddress = walletAddress;
      _lastBlockchainBalance = ethBalance;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[HOME] Switching wallet: $walletAddress, ETH from blockchain: $ethBalance');
        swapProvider.setCurrentWallet(walletAddress);
        swapProvider.updateEthBalance(walletAddress, ethBalance);
      });
    } else if (walletAddress.isNotEmpty && !_swapInitialized) {
      _swapInitialized = true;
      _lastWalletAddress = walletAddress;
      _lastBlockchainBalance = ethBalance;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[HOME] Initializing wallet: $walletAddress, ETH from blockchain: $ethBalance');
        swapProvider.setCurrentWallet(walletAddress);
        swapProvider.updateEthBalance(walletAddress, ethBalance);
      });
    } else if (balanceChanged && walletAddress.isNotEmpty) {
      // Blockchain balance thay đổi (do nhận/gửi ETH)
      _lastBlockchainBalance = ethBalance;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[HOME] Blockchain balance changed: $ethBalance ETH');
        swapProvider.updateEthBalance(walletAddress, ethBalance);
      });
    }
    // Nếu chỉ rebuild do swap → KHÔNG gọi updateEthBalance()
    
    return Column(
      children: [
        Container(
          color: const Color.fromRGBO(48, 48, 48, 1.0),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              ethereumProvider.isLoading
                  ? CircularProgressIndicator()
                  : ethereumProvider.walletModel?.getBalance != null
                      ? Text(
                          '\$${ethereumProvider.walletModel?.getBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold,
                              color: Colors.white, )
                        )
                      : Text('NaN'),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ethereumProvider.balanceChange?.toStringAsFixed(2) ?? "NaN",
                    style: TextStyle(
                      fontSize: 16,
                       color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '(${ethereumProvider.priceChange?.toStringAsFixed(2) ?? "NaN"}%)',
                    style: TextStyle(
                      fontSize: 16,
                      color: ethereumProvider.priceChange! > 0
                          ? const Color.fromARGB(255, 0, 200, 0)
                          : const Color.fromARGB(255, 200, 0, 0),
                      backgroundColor: const Color.fromARGB(255, 215, 215, 215),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút Nhận
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ReceiveScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 42, 42, 42),
                            shape: BoxShape.circle,
                          ),
                          padding:
                              EdgeInsets.all(12), // Kích thước padding cân bằng
                          child: Icon(
                            Icons.arrow_downward,
                            color: const Color(0xFF9886E5),
                            size: 24, // Kích thước icon nhỏ hơn
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.translate("receive"),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Nút Gửi
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SendScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                             color: const Color.fromARGB(255, 42, 42, 42),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_upward,
                            color:const Color(0xFF9886E5),
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.translate("send"),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                           color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Nút Đổi
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SwapScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 42, 42, 42),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.swap_horiz,
                            color: const Color(0xFF9886E5),
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.translate("exchange"),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Nút Mua
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BuyAndSellScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:  const Color.fromARGB(255, 42, 42, 42),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.shopping_cart,
                            color: const Color(0xFF9886E5),
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.translate("buy"),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                           color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              // Ethereum
              _buildTokenCard(
                context,
                swapProvider,
                'ETH',
                'Ethereum',
                "https://cryptologos.cc/logos/ethereum-eth-logo.png",
                4,
              ),
              // USDT
              _buildTokenCard(
                context,
                swapProvider,
                'USDT',
                'Tether',
                "https://cryptologos.cc/logos/tether-usdt-logo.png",
                2,
              ),
              // Bitcoin
              _buildTokenCard(
                context,
                swapProvider,
                'BTC',
                'Bitcoin',
                "https://cryptologos.cc/logos/bitcoin-btc-logo.png",
                6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method để tạo token card - tránh gọi getTokenBalance() nhiều lần
  Widget _buildTokenCard(
    BuildContext context,
    SwapProvider swapProvider,
    String tokenSymbol,
    String tokenName,
    String iconUrl,
    int decimals,
  ) {
    // Lấy balance 1 lần duy nhất
    final balance = swapProvider.getTokenBalance(tokenSymbol);
    final price = swapProvider.tokenPrices[tokenSymbol] ?? 0.0;
    final value = balance * price;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 42, 42, 42),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon với màu sắc
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTokenColor(tokenSymbol).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getTokenColor(tokenSymbol),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _getTokenIcon(tokenSymbol),
                color: _getTokenColor(tokenSymbol),
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 16),
          // Token info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tokenName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "${balance.toStringAsFixed(decimals)} $tokenSymbol",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${value.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "\$${price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
