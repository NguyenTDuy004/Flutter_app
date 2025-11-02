import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/providers/ethereum_provider.dart';
import 'package:wallet/providers/swap_provider.dart';
import 'package:wallet/screens/qr_screen.dart';
import 'package:wallet/utils/format.dart';

class SendScreen extends StatefulWidget {
  @override
  SendScreenState createState() => SendScreenState();
}

class SendScreenState extends State<SendScreen> {
  final List<String> tokens = ["Solana", "Ethereum", "USDT"];
  String selectedToken = "Ethereum";
  TextEditingController amountController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  double transactionFee = 0.0;

  bool isValidInput() {
    if (amountController.text.isEmpty || addressController.text.isEmpty) {
      return false;
    }

    if (double.tryParse(amountController.text) == null) {
      return false;
    }

    return true;
  }

  late EthereumProvider ethereumProvider;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ethereumProvider = Provider.of<EthereumProvider>(context, listen: false);
    ethereumProvider.fetchBalance();
    ethereumProvider.fetchPriceChange();
    ethereumProvider.startAutoUpdateBalance();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gửi tiền mã hóa", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF9886E5),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Số dư: ${ethereumProvider.walletModel?.getEtherAmount} ETH",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
              SizedBox(height: 16),
              Text(
                "Chọn loại tiền",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedToken,
                  icon:
                      Icon(Icons.arrow_drop_down, color: const Color(0xFF9886E5)),
                  underline: SizedBox(),
                  items: tokens.map((String token) {
                    return DropdownMenuItem<String>(
                      value: token,
                      child: Text(token, style: TextStyle(fontSize: 16,color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedToken = newValue!;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Địa chỉ ví nhận",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      controller: addressController,
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: Colors.white60),
                        hintText: "Nhập địa chỉ ví nhận",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) {
                        if (isValidInput()) {
                          ethereumProvider.fetchGasFee(
                              addressController.text.toLowerCase(),
                              double.parse(amountController.text));
                          setState(() {
                            transactionFee = ethereumProvider.gasFee;
                          });
                        } else {
                          setState(() {
                            transactionFee = 0.0;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: const Color(0xFF9886E5)),
                    onPressed: () async {
                      final scannedAddress = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QRScannerScreen()),
                      );

                      // If an address is scanned, populate it into the address field
                      if (scannedAddress != null) {
                        setState(() {
                          addressController.text = scannedAddress;
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "Số lượng gửi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
              ),
              SizedBox(height: 8),
              TextField(
                controller: amountController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.white60),
                  hintText: "Nhập số lượng tiền mã hóa",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) {
                  if (isValidInput()) {
                    ethereumProvider.fetchGasFee(addressController.text,
                        double.parse(amountController.text));
                    setState(() {
                      transactionFee = ethereumProvider.gasFee;
                    });
                  } else {
                    setState(() {
                      transactionFee = 0.0;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              Text(
                "Chi phí giao dịch: $transactionFee ETH",
                style: TextStyle(color: Colors.white),
              ),
              Divider(),
              SizedBox(height: 16),
              Text(
                "Chi tiết giao dịch",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Loại tiền: $selectedToken",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Ví nhận: ${addressController.text.isEmpty ? 'Chưa nhập' : AddressFormat.formatAddress(addressController.text)}",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Số lượng: ${amountController.text.isEmpty ? 'Chưa nhập' : amountController.text} $selectedToken",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Chi phí giao dịch: $transactionFee ETH",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isValidInput()) {
                      final swapProvider = Provider.of<SwapProvider>(context, listen: false);
                      final walletAddress = ethereumProvider.walletModel?.getAddress ?? '';
                      final sendAmount = double.parse(amountController.text);
                      
                      // Send transaction
                      await ethereumProvider.sendTransaction(
                          addressController.text.toLowerCase(),
                          sendAmount);
                      
                      // Refresh balance trong SwapProvider sau khi send
                      if (walletAddress.isNotEmpty) {
                        await swapProvider.refreshBalance(
                          walletAddress,
                          ethereumProvider.walletModel?.getEtherAmount ?? 0.0,
                        );
                      }
                      
                      amountController.clear();
                      addressController.clear();
                      setState(() {
                        transactionFee = 0.0;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Giao dịch thành công"),
                          backgroundColor: const Color(0xFF9886E5),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9886E5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Gửi ngay",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
