# Logic giải thích: Quản lý Balance với Swap

## 🎯 Vấn đề cần giải quyết

App có 2 loại balance cần quản lý:
1. **Blockchain Balance**: ETH thực sự trên blockchain (Ganache)
2. **Swap Balance**: Số dư các token sau khi swap (ETH, USDT, BTC)

## ⚠️ Thử thách

Khi user **SWAP** token (ETH → USDT), blockchain balance KHÔNG thay đổi (vì đây là demo, không có smart contract thật). Nhưng swap balance phải thay đổi!

Khi user **NHẬN/GỬI** ETH, cả blockchain và swap balance đều phải cập nhật!

## ✅ Giải pháp

### 1. Track 2 loại balance riêng biệt:

```dart
// Hiển thị cho user (sau khi swap)
Map<String, Map<String, double>> walletBalances = {
  '0xABC...': {
    'ETH': 50.0,    // Đã swap 50 ETH sang USDT
    'USDT': 194000,
    'BTC': 0.0,
  }
};

// Track blockchain để phát hiện giao dịch
Map<String, double> _blockchainBalances = {
  '0xABC...': 100.0,  // Blockchain vẫn có 100 ETH
};
```

### 2. Logic update balance:

#### Khi nhận ETH từ blockchain:
```dart
receivedETH = newBlockchainBalance - oldBlockchainBalance
swapETH = currentSwapETH + receivedETH
```

**Ví dụ:**
- Old blockchain: 100 ETH
- Current swap: 50 ETH (đã swap 50 → USDT)
- New blockchain: 150 ETH (nhận thêm 50 từ người khác)
- **Received**: 150 - 100 = 50 ETH
- **New swap**: 50 + 50 = **100 ETH** ✅

#### Khi gửi ETH:
```dart
sentETH = oldBlockchainBalance - newBlockchainBalance
swapETH = currentSwapETH - sentETH
```

**Ví dụ:**
- Old blockchain: 150 ETH
- Current swap: 100 ETH
- New blockchain: 130 ETH (gửi đi 20)
- **Sent**: 150 - 130 = 20 ETH
- **New swap**: 100 - 20 = **80 ETH** ✅

#### Khi swap local (ETH → USDT):
```dart
// Blockchain KHÔNG đổi!
// Chỉ cập nhật swap balance:
swapETH = swapETH - amount
swapUSDT = swapUSDT + (amount * priceETH / priceUSDT)
```

## 📊 Test case theo yêu cầu:

### Bước 1: Acc5 ban đầu
- Blockchain: **100 ETH**
- Swap: ETH=**100**, USDT=0, BTC=0
- ✅ Hiển thị: **100 ETH**

### Bước 2: Acc5 swap 50 ETH → USDT
- Blockchain: **100 ETH** (không đổi)
- Swap: ETH=**50**, USDT=**194216**, BTC=0
- ✅ Hiển thị: **50 ETH**

### Bước 3: Acc4 send 50 ETH → Acc5
- Blockchain: **150 ETH** (100 + 50)
- Blockchain change: +50 ETH
- Swap: ETH=**100** (50 + 50), USDT=194216, BTC=0
- ✅ Hiển thị: **100 ETH**

### Bước 4: Acc5 swap 50 ETH → BTC
- Blockchain: **150 ETH** (không đổi)
- Swap: ETH=**50**, USDT=194216, BTC=**1.76**
- ✅ Hiển thị: **50 ETH**

### Bước 5: Acc4 send 20 ETH → Acc5
- Blockchain: **170 ETH** (150 + 20)
- Blockchain change: +20 ETH
- Swap: ETH=**70** (50 + 20), USDT=194216, BTC=1.76
- ✅ Hiển thị: **70 ETH** (ĐÚNG!)

## 🔧 Code Implementation

### updateEthBalance() method:

```dart
void updateEthBalance(String walletAddress, double blockchainBalance) {
  if (!walletBalances.containsKey(walletAddress)) {
    // Lần đầu: Init cả swap và blockchain balance
    walletBalances[walletAddress] = {
      'ETH': blockchainBalance,
      'USDT': 0.0,
      'BTC': 0.0,
    };
    _blockchainBalances[walletAddress] = blockchainBalance;
  } else {
    double currentSwapEth = walletBalances[walletAddress]!['ETH'] ?? 0.0;
    double lastBlockchainEth = _blockchainBalances[walletAddress] ?? 0.0;
    
    if (blockchainBalance > lastBlockchainEth) {
      // NHẬN ETH: Cộng thêm vào swap
      double received = blockchainBalance - lastBlockchainEth;
      walletBalances[walletAddress]!['ETH'] = currentSwapEth + received;
      _blockchainBalances[walletAddress] = blockchainBalance;
      
    } else if (blockchainBalance < lastBlockchainEth) {
      // GỬI ETH: Trừ đi từ swap
      double sent = lastBlockchainEth - blockchainBalance;
      walletBalances[walletAddress]!['ETH'] = currentSwapEth - sent;
      _blockchainBalances[walletAddress] = blockchainBalance;
    }
    // Nếu bằng nhau: Đã sync
  }
}
```

## 🎉 Kết luận

Logic này cho phép:
- ✅ Track chính xác ETH sau khi swap
- ✅ Cập nhật đúng khi nhận/gửi ETH
- ✅ Không bị ghi đè balance khi có swap
- ✅ Persist data qua app restart

**Lưu ý quan trọng**: 
- `walletBalances` = Số dư **SAU SWAP** (hiển thị cho user)
- `_blockchainBalances` = Số dư **TRÊN BLOCKCHAIN** (để phát hiện giao dịch)
- Khi swap: Chỉ `walletBalances` thay đổi
- Khi send/receive: Cả 2 đều thay đổi
