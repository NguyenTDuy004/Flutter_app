# 🪙 CryptX - Crypto Wallet Application

Ứng dụng ví tiền điện tử (Cryptocurrency Wallet) được xây dựng bằng Flutter, hỗ trợ quản lý ETH, USDT, BTC với tính năng swap token và lưu trữ lịch sử giao dịch.

## 📋 Mục lục

- [Tính năng](#-tính-năng)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt](#-cài-đặt)
- [Chạy dự án](#-chạy-dự-án)
- [Cấu trúc dự án](#-cấu-trúc-dự-án)
- [API Endpoints](#-api-endpoints)

---

## ✨ Tính năng

- 🔐 **Wallet Management**: Tạo, import và quản lý ví Ethereum
- 💰 **Token Support**: Hỗ trợ ETH, USDT, BTC
- 🔄 **Token Swap**: Đổi token với phí 0.3% (chuẩn Uniswap)
- 📊 **Balance Tracking**: Theo dõi số dư và giá trị USD
- 📤 **Send/Receive**: Gửi và nhận crypto
- 📱 **QR Code**: Quét QR code để nhận địa chỉ ví
- 📜 **Transaction History**: Lịch sử giao dịch lưu trên MongoDB
- 🌐 **Multi-language**: Hỗ trợ tiếng Anh và tiếng Việt

---

## 🛠 Công nghệ sử dụng

### Frontend
- **Flutter** 3.2.0+
- **Dart** SDK 3.6.0+
- **Provider** - State management
- **Web3dart** - Blockchain interaction
- **Flutter Secure Storage** - Lưu trữ private key an toàn

### Backend
- **Node.js** - Runtime
- **Express.js** - REST API server
- **Ganache CLI** - Local Ethereum blockchain
- **MongoDB** - Database lưu transaction history
- **Web3.js** - Blockchain interaction

---

## 💻 Yêu cầu hệ thống

### Cần thiết
- **Flutter SDK**: >= 3.2.0
- **Dart SDK**: >= 3.6.0
- **Node.js**: >= 14.x
- **npm** hoặc **yarn**

### Tùy chọn
- **MongoDB Atlas Account** (cho transaction history)
- **Git** (clone repository)

---

## 📦 Cài đặt

### 1. Clone Repository

```bash
git clone https://github.com/NguyenTDuy004/Flutter_app.git
cd flutter-test/cryptx
```

### 2. Cài đặt Flutter Dependencies

```bash
flutter pub get
```

### 3. Cài đặt Backend Dependencies

```bash
cd backend
npm install
cd ..
```

### 4. Cấu hình Environment (Optional)

Nếu muốn sử dụng MongoDB để lưu lịch sử giao dịch:

**Tạo file `.env` trong `assets/` folder:**

```bash
# assets/.env
MONGO_DB_CONNECTION_STRING=mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority
```

> **Lưu ý:** Transaction history là tính năng tùy chọn. App vẫn chạy bình thường không có MongoDB.

---

## 🚀 Chạy dự án

### Bước 1: Khởi động Ganache (Local Blockchain)

Mở terminal mới và chạy:

```bash
cd backend
node ganache.js
```

**Output mong đợi:**
```
Ganache running on http://127.0.0.1:8545

Available accounts
==================

[0] 0x...
    Private Key: 0x...
    Balance: 100 ETH

[1] 0x...
    Private Key: 0x...
    Balance: 100 ETH
...
```

> ⚠️ **Quan trọng:** Ganache phải chạy trước khi start Flutter app!

### Bước 2: Khởi động MongoDB Server (Optional)

Nếu muốn sử dụng transaction history:

```bash
cd backend
node server.js
```

**Output mong đợi:**
```
Server is running on http://127.0.0.1:5000
```

### Bước 3: Chạy Flutter App

Mở terminal mới:

```bash
flutter run
```

Hoặc chạy trên Chrome:

```bash
flutter run -d chrome
```

---

## 📁 Cấu trúc dự án

```
cryptx/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Data models
│   │   ├── transaction_model.dart
│   │   └── wallet_model.dart
│   ├── providers/                   # State management
│   │   ├── ethereum_provider.dart   # Blockchain logic
│   │   ├── swap_provider.dart       # Swap logic
│   │   └── LocalizationProvider.dart
│   ├── screens/                     # UI screens
│   │   ├── login_screen.dart
│   │   ├── home_page.dart
│   │   └── nav/
│   │       ├── home_screen.dart     # Balance display
│   │       ├── swap_screen.dart     # Token swap
│   │       ├── send_screen.dart     # Send crypto
│   │       ├── receive_screen.dart  # Receive crypto
│   │       └── transaction_screen.dart
│   ├── services/                    # Business logic
│   │   ├── blockchain_service.dart  # Web3 interaction
│   │   ├── transaction_service.dart # API calls
│   │   └── coingecko_service.dart   # Price API
│   ├── utils/                       # Utilities
│   │   ├── format.dart
│   │   └── localization.dart
│   └── widgets/                     # Reusable components
│
├── backend/
│   ├── ganache.js                   # Local blockchain
│   ├── server.js                    # REST API server
│   ├── package.json
│   └── test-accounts.json
│
├── assets/
│   └── lang/                        # Translations
│       ├── en.json
│       └── vi.json
│
├── pubspec.yaml                     # Flutter dependencies
└── README.md
```

---

## 🌐 API Endpoints

### Ganache RPC (Port 8545)
```
http://127.0.0.1:8545
```
- Web3 JSON-RPC endpoint
- Xử lý blockchain transactions

### MongoDB Server (Port 5000)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/transactions/sender/:sender` | Lấy giao dịch của người gửi |
| `GET` | `/transactions/recipient/:recipient` | Lấy giao dịch của người nhận |
| `GET` | `/transactions/address/:address` | Lấy tất cả giao dịch của địa chỉ |
| `POST` | `/transactions` | Tạo transaction record mới |

---

## 🔧 Troubleshooting

### ❌ Lỗi: "Failed to connect to http://127.0.0.1:8545"

**Nguyên nhân:** Ganache chưa chạy

**Giải pháp:**
```bash
cd backend
node ganache.js
```

### ❌ Lỗi: Balance hiển thị 0

**Nguyên nhân:** RPC URL sai hoặc Ganache restart

**Giải pháp:**
1. Kiểm tra Ganache đang chạy
2. Restart Flutter app
3. Xóa app data và login lại

### ❌ Lỗi: "setState() called during build"

**Giải pháp:** Đã fix trong code, sử dụng `addPostFrameCallback()`

### ❌ Transaction history không load

**Nguyên nhân:** MongoDB server chưa chạy

**Giải pháp:**
```bash
cd backend
node server.js
```

---

## 📝 Swap Logic

Swap fee: **0.3%** (chuẩn Uniswap V2)

**Công thức:**
```
Received Amount = Input Amount × Exchange Rate × (1 - 0.003)
```

**Validation:**
- ✅ Minimum swap: $1 USD
- ✅ Balance check
- ✅ Same token prevention
- ✅ Slippage tolerance: 1%

---

## 🔑 Default Accounts

Ganache tạo 5 accounts với mnemonic cố định:

```
Mnemonic: test test test test test test test test test test test junk
```

Mỗi account có **100 ETH** khi khởi động.

**Account [0]:**
```
Address: 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1
Private Key: 0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d
```

> Import private key này vào app để test!

---

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
```

### Flutter Tests
```bash
flutter test
```

---

## 📄 License

This project is for educational purposes.

---

## 👨‍💻 Author

- GitHub: [@NguyenTDuy004](https://github.com/NguyenTDuy004)

---

## 🙏 Acknowledgments

- Ethereum Foundation
- Ganache CLI
- Flutter Team
- Web3dart Library
