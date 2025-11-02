import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/providers/ethereum_provider.dart';
import 'package:wallet/providers/swap_provider.dart';

class SwapScreen extends StatefulWidget {
  @override
  _SwapScreenState createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  String fromToken = "ETH";
  String toToken = "USDT";
  TextEditingController amountController = TextEditingController();
  double convertedAmount = 0.0;
  bool _isInitialized = false;
  double _lastEthBalance = -1;
  String _lastWalletAddress = '';
  // REMOVE GlobalKey - không dùng nữa vì gây lỗi

  @override
  void initState() {
    super.initState();
    // Listen to controller để force rebuild
    amountController.addListener(() {
      setState(() {}); // Force rebuild khi amount thay đổi
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

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

  // Tính toán số lượng token sau swap
  void _calculateConversion(SwapProvider swapProvider) {
    if (amountController.text.isEmpty) {
      setState(() => convertedAmount = 0.0);
      return;
    }
    
    double amount = double.tryParse(amountController.text) ?? 0.0;
    setState(() {
      convertedAmount = swapProvider.calculateConversion(fromToken, toToken, amount);
    });
  }

  // Thực hiện swap
  Future<void> _performSwap(BuildContext context) async {
    final swapProvider = Provider.of<SwapProvider>(context, listen: false);
    final ethereumProvider = Provider.of<EthereumProvider>(context, listen: false);
    
    // Debug: In ra token TRƯỚC KHI swap
    print('[SWAP-BUTTON] Button clicked! fromToken = $fromToken, toToken = $toToken');
    
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập số lượng cần swap')),
      );
      return;
    }

    double amount = double.tryParse(amountController.text) ?? 0.0;
    
    // Debug: In ra token hiện tại
    print('[SWAP] Performing swap: $amount $fromToken → $toToken');
    print('[SWAP] Current balances: ETH=${swapProvider.getTokenBalance("ETH")}, USDT=${swapProvider.getTokenBalance("USDT")}, BTC=${swapProvider.getTokenBalance("BTC")}');
    
    // THỰC HIỆN SWAP với validation mới
    Map<String, dynamic> result = await swapProvider.performSwap(
      fromToken: fromToken,
      toToken: toToken,
      amount: amount,
      walletAddress: ethereumProvider.walletModel?.getAddress ?? '',
    );

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Lấy kết quả
    double converted = result['convertedAmount'];
    double fee = result['fee'];
    
    print('[SWAP] Success: $amount $fromToken → $converted $toToken (Fee: \$${fee.toStringAsFixed(2)})');
    print('[SWAP] New balances: ETH=${swapProvider.getTokenBalance("ETH")}, USDT=${swapProvider.getTokenBalance("USDT")}, BTC=${swapProvider.getTokenBalance("BTC")}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Swap thành công!\n'
          '$amount $fromToken → ${converted.toStringAsFixed(6)} $toToken\n'
          'Phí giao dịch: \$${fee.toStringAsFixed(2)} (${SwapProvider.SWAP_FEE_PERCENT}%)'
        ),
        backgroundColor: Color(0xFF9886E5),
        duration: Duration(seconds: 3),
      ),
    );

    amountController.clear();
    setState(() => convertedAmount = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: In ra state hiện tại
    print('[BUILD] fromToken = $fromToken, toToken = $toToken');
    
    return Consumer2<SwapProvider, EthereumProvider>(
      builder: (context, swapProvider, ethereumProvider, child) {
        final walletAddress = ethereumProvider.walletModel?.getAddress ?? '';
        final currentEthBalance = ethereumProvider.walletModel?.getEtherAmount ?? 0.0;
        
        // Set wallet hiện tại (KHÔNG sync balance tại đây để tránh ghi đè swap balance)
        if (walletAddress.isNotEmpty) {
          // Kiểm tra nếu wallet thay đổi
          if (_lastWalletAddress != walletAddress) {
            _lastWalletAddress = walletAddress;
            _isInitialized = false; // Reset flag khi đổi wallet
          }
          
          if (!_isInitialized) {
            _isInitialized = true;
            swapProvider.setCurrentWallet(walletAddress);
            
            // CHỈ init balance lần đầu tiên nếu wallet chưa có data
            if (!swapProvider.walletBalances.containsKey(walletAddress)) {
              swapProvider.updateEthBalance(walletAddress, currentEthBalance);
            }
          }
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text("Swap tiền mã hóa", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: const Color(0xFF9886E5),
            actions: [
              // Nút clear all balances (debug)
              IconButton(
                icon: Icon(Icons.delete_sweep),
                tooltip: 'Clear All Balances',
                onPressed: () async {
                  await swapProvider.clearAllBalances();
                  // Sau khi clear, sync lại
                  swapProvider.updateEthBalance(
                    walletAddress,
                    ethereumProvider.walletModel?.getEtherAmount ?? 0.0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa toàn bộ balance và sync lại!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              // Nút sync với blockchain (khi restart Ganache)
              IconButton(
                icon: Icon(Icons.sync),
                tooltip: 'Sync với Blockchain',
                onPressed: () {
                  swapProvider.syncWithBlockchain(
                    walletAddress,
                    ethereumProvider.walletModel?.getEtherAmount ?? 0.0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã đồng bộ với blockchain!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              IconButton(
                icon: swapProvider.isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.refresh),
                onPressed: swapProvider.isLoading ? null : () => swapProvider.refreshPrices(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hiển thị số dư các token
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(38, 38, 38, 1.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tổng tài sản",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "\$${swapProvider.getTotalValueInUSD().toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9886E5),
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey),
                        SizedBox(height: 8),
                        _buildBalanceRow(swapProvider, 'ETH'),
                        SizedBox(height: 8),
                        _buildBalanceRow(swapProvider, 'USDT'),
                        SizedBox(height: 8),
                        _buildBalanceRow(swapProvider, 'BTC'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Từ token
                  Text(
                    "Từ loại tiền",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: fromToken,
                    dropdownColor: const Color.fromRGBO(38, 38, 38, 1.0),
                    style: TextStyle(color: Colors.white),
                    items: ['ETH', 'USDT', 'BTC'].map((token) {
                      return DropdownMenuItem(
                        value: token,
                        child: Row(
                          children: [
                            Icon(
                              _getTokenIcon(token),
                              color: _getTokenColor(token),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "$token (${swapProvider.getTokenBalance(token).toStringAsFixed(4)})",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                                    onChanged: (value) {
                      if (value != toToken) {
                        print('[DROPDOWN] User selected: $value (current fromToken: $fromToken)');
                        setState(() {
                          fromToken = value!;
                          convertedAmount = 0.0; // Reset converted amount
                          // CLEAR controller để TextField rebuild hoàn toàn
                          amountController.clear();
                        });
                        print('[DROPDOWN] Updated fromToken to: $fromToken, cleared amount');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Không thể chọn cùng loại tiền! Vui lòng chọn token khác.'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Số lượng - DÙNG ValueKey để FORCE rebuild khi token thay đổi
                  Builder(
                    builder: (context) {
                      // Force rebuild khi fromToken thay đổi
                      return TextFormField(
                        key: ValueKey('amount_input_$fromToken'), // KEY để force rebuild
                        controller: amountController,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.white60),
                          hintText: "Nhập số lượng $fromToken",
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTokenIcon(fromToken),
                                color: _getTokenColor(fromToken),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                fromToken,
                                style: TextStyle(
                                  color: _getTokenColor(fromToken),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 12),
                            ],
                          ),
                          filled: true,
                          fillColor: Color.fromRGBO(38, 38, 38, 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF9886E5), width: 2),
                          ),
                        ),
                        onChanged: (_) {
                          print('[SWAP-UI] Amount changed, fromToken = $fromToken');
                          _calculateConversion(swapProvider);
                        },
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  
                  // Icon swap
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF9886E5).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_vert,
                        size: 32,
                        color: Color(0xFF9886E5),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Sang token
                  Text(
                    "Sang loại tiền",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: toToken,
                    dropdownColor: const Color.fromRGBO(38, 38, 38, 1.0),
                    style: TextStyle(color: Colors.white),
                    items: ['ETH', 'USDT', 'BTC'].map((token) {
                      return DropdownMenuItem(
                        value: token,
                        child: Row(
                          children: [
                            Icon(
                              _getTokenIcon(token),
                              color: _getTokenColor(token),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "$token (${swapProvider.getTokenBalance(token).toStringAsFixed(4)})",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != fromToken) {
                        print('[DROPDOWN] User selected toToken: $value (current: $toToken)');
                        setState(() {
                          toToken = value!;
                          convertedAmount = 0.0;
                        });
                        Future.microtask(() {
                          _calculateConversion(swapProvider);
                        });
                        print('[DROPDOWN] Updated toToken to: $toToken');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Không thể chọn cùng loại tiền!')),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Kết quả chuyển đổi & Thông tin phí
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(38, 38, 38, 1.0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF9886E5).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        // Số lượng nhận được
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Bạn nhận được:",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              "${convertedAmount.toStringAsFixed(6)} $toToken",
                              style: TextStyle(
                                color: Color(0xFF9886E5),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(color: Colors.grey.withOpacity(0.3)),
                        SizedBox(height: 8),
                        // Phí giao dịch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Phí giao dịch (${SwapProvider.SWAP_FEE_PERCENT}%):",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              amountController.text.isNotEmpty 
                                ? "\$${swapProvider.calculateSwapFee(fromToken, double.tryParse(amountController.text) ?? 0.0).toStringAsFixed(2)}"
                                : "\$0.00",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(color: Colors.grey.withOpacity(0.3)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Tỷ giá:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              "1 $fromToken ≈ ${((swapProvider.tokenPrices[fromToken] ?? 1) / (swapProvider.tokenPrices[toToken] ?? 1)).toStringAsFixed(6)} $toToken",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Nút swap
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _performSwap(context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF9886E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Swap ngay",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceRow(SwapProvider swapProvider, String token) {
    double balance = swapProvider.getTokenBalance(token);
    double price = swapProvider.tokenPrices[token] ?? 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF9886E5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  token[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "\$${price.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              balance.toStringAsFixed(4),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "\$${(balance * price).toStringAsFixed(2)}",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
