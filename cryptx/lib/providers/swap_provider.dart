import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet/models/transaction_model.dart';
import 'package:wallet/models/wallet_model.dart';
import 'package:wallet/services/transaction_service.dart';

class SwapProvider extends ChangeNotifier {
  final _storage = FlutterSecureStorage();
  final _transactionService = TransactionService();
  
  // Giá token (sẽ được cập nhật từ API)
  Map<String, double> tokenPrices = {
    'ETH': 3864.53,
    'BTC': 95000.0,
    'USDT': 1.0,
  };
  
  // PHÍ GIAO DỊCH (Swap fee) - Thường 0.3% như Uniswap
  static const double SWAP_FEE_PERCENT = 0.3; // 0.3%
  
  // SLIPPAGE TOLERANCE - Chấp nhận chênh lệch giá tối đa
  static const double SLIPPAGE_TOLERANCE = 1.0; // 1%
  
  // MINIMUM SWAP AMOUNT - Số lượng tối thiểu để swap (tính bằng USD)
  static const double MIN_SWAP_USD = 1.0; // $1 minimum
  
  // Số dư token theo wallet address: {walletAddress: {token: balance}}
  Map<String, Map<String, double>> walletBalances = {};
  
  // Track blockchain balance để phát hiện khi nhận ETH
  Map<String, double> _blockchainBalances = {};
  
  String _currentWalletAddress = '';
  
  bool _isLoading = false;
  bool _isPricesLoaded = false;
  DateTime? _lastPriceUpdate;
  
  bool get isLoading => _isLoading;
  bool get isPricesLoaded => _isPricesLoaded;
  
  // Lấy số dư token của wallet hiện tại
  Map<String, double> get currentWalletTokenBalances {
    if (_currentWalletAddress.isEmpty) {
      return {'ETH': 0.0, 'USDT': 0.0, 'BTC': 0.0};
    }
    return walletBalances[_currentWalletAddress] ?? {'ETH': 0.0, 'USDT': 0.0, 'BTC': 0.0};
  }
  
  SwapProvider() {
    _loadBalances();
    _loadTokenPrices();
  }
  
  // Set wallet hiện tại
  void setCurrentWallet(String address) {
    if (_currentWalletAddress != address) {
      _currentWalletAddress = address;
      print('[WALLET] Set current wallet: $address');
      print('[WALLET] Balances for this wallet: ${walletBalances[address]}');
      
      // Đảm bảo wallet có balance entry
      if (!walletBalances.containsKey(address)) {
        walletBalances[address] = {'ETH': 0.0, 'USDT': 0.0, 'BTC': 0.0};
        print('[WALLET] Wallet chua co balance, khoi tao ve 0');
      }
      notifyListeners();
    }
  }
  
  // Load số dư từ storage
  Future<void> _loadBalances() async {
    try {
      final balancesJson = await _storage.read(key: 'wallet_token_balances');
      if (balancesJson != null) {
        final Map<String, dynamic> data = json.decode(balancesJson);
        walletBalances = data.map((walletAddr, tokens) {
          return MapEntry(
            walletAddr,
            (tokens as Map<String, dynamic>).map((token, balance) {
              return MapEntry(token, (balance as num).toDouble());
            }),
          );
        });
        notifyListeners();
      }
      
      // Load blockchain balances
      final blockchainJson = await _storage.read(key: 'blockchain_balances');
      if (blockchainJson != null) {
        final Map<String, dynamic> data = json.decode(blockchainJson);
        _blockchainBalances = data.map((walletAddr, balance) {
          return MapEntry(walletAddr, (balance as num).toDouble());
        });
      }
    } catch (e) {
      print('Error loading balances: $e');
    }
  }
  
  // Lưu số dư vào storage
  Future<void> _saveBalances() async {
    try {
      await _storage.write(
        key: 'wallet_token_balances',
        value: json.encode(walletBalances),
      );
      await _storage.write(
        key: 'blockchain_balances',
        value: json.encode(_blockchainBalances),
      );
    } catch (e) {
      print('Error saving balances: $e');
    }
  }
  
  // Cập nhật ETH balance từ blockchain
  void updateEthBalance(String walletAddress, double blockchainBalance) {
    if (!walletBalances.containsKey(walletAddress)) {
      // Lần đầu tiên, khởi tạo với số dư từ blockchain
      walletBalances[walletAddress] = {
        'ETH': blockchainBalance,
        'USDT': 0.0,
        'BTC': 0.0,
      };
      _blockchainBalances[walletAddress] = blockchainBalance;
      _saveBalances();
      notifyListeners();
      print('[INIT] Khoi tao wallet $walletAddress voi $blockchainBalance ETH');
    } else {
      double currentSwapEth = walletBalances[walletAddress]!['ETH'] ?? 0.0;
      double lastBlockchainEth = _blockchainBalances[walletAddress] ?? 0.0;
      
      // Nếu blockchain balance tăng → Nhận thêm ETH
      if (blockchainBalance > lastBlockchainEth) {
        double received = blockchainBalance - lastBlockchainEth;
        // CỘNG THÊM vào swap balance, KHÔNG GHI ĐÈ
        walletBalances[walletAddress]!['ETH'] = currentSwapEth + received;
        _blockchainBalances[walletAddress] = blockchainBalance;
        _saveBalances();
        notifyListeners();
        print('[RECEIVE] Nhan them $received ETH: swap $currentSwapEth -> ${currentSwapEth + received} (blockchain: $lastBlockchainEth -> $blockchainBalance)');
      }
      // Nếu blockchain balance giảm → Đã send ETH
      else if (blockchainBalance < lastBlockchainEth) {
        double sent = lastBlockchainEth - blockchainBalance;
        // TRỪ đi từ swap balance
        walletBalances[walletAddress]!['ETH'] = currentSwapEth - sent;
        _blockchainBalances[walletAddress] = blockchainBalance;
        _saveBalances();
        notifyListeners();
        print('[SEND] Da send $sent ETH: swap $currentSwapEth -> ${currentSwapEth - sent} (blockchain: $lastBlockchainEth -> $blockchainBalance)');
      }
      // Nếu bằng nhau: Đã sync rồi
      else {
        print('[SYNC] ETH da sync: swap=$currentSwapEth, blockchain=$blockchainBalance');
      }
    }
  }
  
  // Refresh balance từ blockchain (dùng khi nhận ETH hoặc send ETH)
  Future<void> refreshBalance(String walletAddress, double blockchainBalance) async {
    if (!walletBalances.containsKey(walletAddress)) {
      walletBalances[walletAddress] = {'ETH': 0.0, 'USDT': 0.0, 'BTC': 0.0};
    }
    
    double currentSwapEth = walletBalances[walletAddress]!['ETH'] ?? 0.0;
    double lastBlockchainEth = _blockchainBalances[walletAddress] ?? 0.0;
    
    // Nếu blockchain balance tăng → Nhận thêm ETH
    if (blockchainBalance > lastBlockchainEth) {
      double received = blockchainBalance - lastBlockchainEth;
      // CỘNG THÊM vào swap balance
      walletBalances[walletAddress]!['ETH'] = currentSwapEth + received;
      _blockchainBalances[walletAddress] = blockchainBalance;
      await _saveBalances();
      notifyListeners();
      print('[REFRESH-RECEIVE] Nhan them $received ETH: swap $currentSwapEth -> ${currentSwapEth + received}');
    } else if (blockchainBalance < lastBlockchainEth) {
      // Blockchain balance giảm → Đã send ETH
      double sent = lastBlockchainEth - blockchainBalance;
      // TRỪ đi từ swap balance
      walletBalances[walletAddress]!['ETH'] = currentSwapEth - sent;
      _blockchainBalances[walletAddress] = blockchainBalance;
      await _saveBalances();
      notifyListeners();
      print('[REFRESH-SEND] Da send $sent ETH: swap $currentSwapEth -> ${currentSwapEth - sent}');
    } else {
      print('[REFRESH-SYNC] ETH da sync: swap=$currentSwapEth, blockchain=$blockchainBalance');
    }
  }
  
  // Load giá token từ API (với cache)
  Future<void> _loadTokenPrices({bool forceRefresh = false}) async {
    // Nếu đã load và chưa quá 5 phút thì không cần refresh
    if (_isPricesLoaded && !forceRefresh && _lastPriceUpdate != null) {
      final diff = DateTime.now().difference(_lastPriceUpdate!);
      if (diff.inMinutes < 5) {
        return;
      }
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin,tether&vs_currencies=usd'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        tokenPrices['ETH'] = data['ethereum']['usd'].toDouble();
        tokenPrices['BTC'] = data['bitcoin']['usd'].toDouble();
        tokenPrices['USDT'] = data['tether']['usd'].toDouble();
        _isPricesLoaded = true;
        _lastPriceUpdate = DateTime.now();
      }
    } catch (e) {
      print('Error loading prices: $e');
      // Giữ nguyên giá cũ nếu lỗi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh giá thủ công
  Future<void> refreshPrices() async {
    await _loadTokenPrices(forceRefresh: true);
  }
  
  // Tính toán số lượng token sau swap (CÓ PHÍ)
  double calculateConversion(String fromToken, String toToken, double amount) {
    if (amount <= 0) return 0.0;
    
    double fromPrice = tokenPrices[fromToken] ?? 1.0;
    double toPrice = tokenPrices[toToken] ?? 1.0;
    
    // Tính giá trị USD của amount
    double valueInUSD = amount * fromPrice;
    
    // TRỪ PHÍ GIAO DỊCH (0.3%)
    double feeInUSD = valueInUSD * (SWAP_FEE_PERCENT / 100);
    double valueAfterFee = valueInUSD - feeInUSD;
    
    // Chuyển đổi sang toToken
    double result = valueAfterFee / toPrice;
    
    print('[SWAP-CALC] $amount $fromToken = \$$valueInUSD');
    print('[SWAP-CALC] Fee (${SWAP_FEE_PERCENT}%): \$$feeInUSD');
    print('[SWAP-CALC] After fee: \$$valueAfterFee = $result $toToken');
    
    return result;
  }
  
  // Tính phí giao dịch
  double calculateSwapFee(String fromToken, double amount) {
    double fromPrice = tokenPrices[fromToken] ?? 1.0;
    double valueInUSD = amount * fromPrice;
    return valueInUSD * (SWAP_FEE_PERCENT / 100);
  }
  
  // Kiểm tra swap có hợp lệ không
  String? validateSwap(String fromToken, String toToken, double amount, String walletAddress) {
    // 1. Kiểm tra số dư
    double currentBalance = walletBalances[walletAddress]?[fromToken] ?? 0.0;
    if (currentBalance < amount) {
      return 'Số dư $fromToken không đủ! Có: ${currentBalance.toStringAsFixed(4)}, Cần: ${amount.toStringAsFixed(4)}';
    }
    
    // 2. Kiểm tra minimum amount
    double fromPrice = tokenPrices[fromToken] ?? 1.0;
    double valueInUSD = amount * fromPrice;
    if (valueInUSD < MIN_SWAP_USD) {
      return 'Số lượng swap tối thiểu: \$${MIN_SWAP_USD.toStringAsFixed(2)} (${(MIN_SWAP_USD / fromPrice).toStringAsFixed(6)} $fromToken)';
    }
    
    // 3. Kiểm tra token khác nhau
    if (fromToken == toToken) {
      return 'Không thể swap cùng loại token!';
    }
    
    return null; // Hợp lệ
  }
  
  // Thực hiện swap (CÓ VALIDATION & FEE)
  Future<Map<String, dynamic>> performSwap({
    required String fromToken,
    required String toToken,
    required double amount,
    required String walletAddress,
  }) async {
    // Đảm bảo wallet có balance
    if (!walletBalances.containsKey(walletAddress)) {
      walletBalances[walletAddress] = {'ETH': 0.0, 'USDT': 0.0, 'BTC': 0.0};
    }
    
    // VALIDATE swap
    String? error = validateSwap(fromToken, toToken, amount, walletAddress);
    if (error != null) {
      return {'success': false, 'error': error};
    }
    
    // Tính toán (ĐÃ BAO GỒM PHÍ)
    double convertedAmount = calculateConversion(fromToken, toToken, amount);
    double fee = calculateSwapFee(fromToken, amount);
    
    print('[SWAP] Executing: $amount $fromToken → $convertedAmount $toToken (Fee: \$${fee.toStringAsFixed(2)})');
    
    // Cập nhật số dư
    walletBalances[walletAddress]![fromToken] = 
        (walletBalances[walletAddress]![fromToken] ?? 0.0) - amount;
    walletBalances[walletAddress]![toToken] = 
        (walletBalances[walletAddress]![toToken] ?? 0.0) + convertedAmount;
    
    // Lưu vào storage
    await _saveBalances();
    
    // Lưu lịch sử giao dịch
    try {
      await _transactionService.createTransaction(
        TransactionModel(
          from: WalletModel(publicKey: walletAddress),
          to: WalletModel(publicKey: 'SWAP_${fromToken}_to_$toToken'),
          amount: amount,
        ),
      );
    } catch (e) {
      print('Error saving swap transaction: $e');
    }
    
    notifyListeners();
    
    return {
      'success': true,
      'convertedAmount': convertedAmount,
      'fee': fee,
    };
  }
  
  // Lấy tổng giá trị tài sản của wallet hiện tại
  double getTotalValueInUSD() {
    double total = 0.0;
    final balances = currentWalletTokenBalances;
    print('[VALUE] Calculating total for wallet: $_currentWalletAddress');
    print('[VALUE] Balances: $balances');
    balances.forEach((token, balance) {
      double value = balance * (tokenPrices[token] ?? 0.0);
      print('[VALUE]   - $token: $balance x ${tokenPrices[token]} = \$$value');
      total += value;
    });
    print('[VALUE] Total: \$$total');
    return total;
  }
  
  // Lấy số dư của một token cụ thể
  double getTokenBalance(String token) {
    final balance = currentWalletTokenBalances[token] ?? 0.0;
    // Bỏ log để giảm spam console
    // print('[BALANCE] getTokenBalance($token) for wallet $_currentWalletAddress = $balance');
    return balance;
  }
  
  // Reset balance (để test hoặc sync lại với blockchain)
  Future<void> resetBalance(String walletAddress, double ethBalance) async {
    walletBalances[walletAddress] = {
      'ETH': ethBalance,
      'USDT': 0.0,
      'BTC': 0.0,
    };
    _blockchainBalances[walletAddress] = ethBalance;
    await _saveBalances();
    notifyListeners();
    print('[RESET] Reset balance: ETH = $ethBalance');
  }
  
  // Clear all data (for testing)
  Future<void> clearAllData() async {
    walletBalances.clear();
    _blockchainBalances.clear();
    await _storage.delete(key: 'wallet_token_balances');
    await _storage.delete(key: 'blockchain_balances');
    notifyListeners();
    print('[CLEAR] Cleared all wallet data');
  }
  
  // Sync với blockchain (khi restart Ganache hoặc muốn cập nhật từ blockchain)
  Future<void> syncWithBlockchain(String walletAddress, double blockchainEthBalance) async {
    if (walletBalances.containsKey(walletAddress)) {
      walletBalances[walletAddress]!['ETH'] = blockchainEthBalance;
      await _saveBalances();
      notifyListeners();
      print('[SYNC] Dong bo voi blockchain: ETH = $blockchainEthBalance');
    } else {
      // Nếu chưa có, khởi tạo
      updateEthBalance(walletAddress, blockchainEthBalance);
    }
  }
  
  // Clear all balances (để reset hoàn toàn)
  Future<void> clearAllBalances() async {
    walletBalances.clear();
    await _storage.delete(key: 'wallet_token_balances');
    notifyListeners();
    print('[CLEAR] Da xoa toan bo du lieu balance');
  }
}
