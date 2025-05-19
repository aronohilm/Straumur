import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SjoppanPage extends StatefulWidget {
  const SjoppanPage({super.key});

  @override
  State<SjoppanPage> createState() => _SjoppanPageState();
}

class _SjoppanPageState extends State<SjoppanPage> {
  // Payment processing state
  bool _isProcessingPayment = false;
  String _transactionStatus = '';
  bool _showTransactionStatus = false;
  // Selected category filter
  String _selectedCategory = 'Allt';
  
  // Shopping cart - Map to track product and quantity
  final Map<String, CartItem> _cartItems = {};
  
  // List of available categories
  List<String> _categories = ['Allt', 'Gos', 'Áfengi', 'Sælgæti'];
  
  // Product database - in a real app, this would come from a backend
  final List<Product> _products = [
    Product(
      id: 'A1',
      name: 'Viking Gull',
      price: 4.50,
      category: 'Áfengi',
      color: const Color(0xFFE8F5C8), // Light green
    ),
    Product(
      id: 'A2',
      name: 'Rauðvín',
      price: 8.95,
      category: 'Áfengi',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'B1',
      name: 'Hvítvín',
      price: 7.95,
      category: 'Áfengi',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'B2',
      name: 'Nóa Kropp',
      price: 2.50,
      category: 'Sælgæti',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'C1',
      name: 'Trítlar',
      price: 1.95,
      category: 'Sælgæti',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'C2',
      name: 'Coke Zero',
      price: 2.25,
      category: 'Gos',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'D1',
      name: 'Pepsi Max',
      price: 2.25,
      category: 'Gos',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'D2',
      name: 'Appelsín',
      price: 2.25,
      category: 'Gos',
      color: const Color(0xFFE8F5C8),
    ),
    Product(
      id: 'E1',
      name: 'Prins Póló',
      price: 1.50,
      category: 'Sælgæti',
      color: const Color(0xFFE8F5C8),
    ),
  ];

  // Get filtered products based on selected category
  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Allt') {
      return _products;
    } else {
      return _products.where((product) => product.category == _selectedCategory).toList();
    }
  }

  // Calculate total price
  double get _totalPrice {
    return _cartItems.values.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  // Add product to cart
  void _addToCart(Product product) {
    setState(() {
      if (_cartItems.containsKey(product.id)) {
        _cartItems[product.id]!.quantity++;
      } else {
        _cartItems[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  // Remove product from cart
  void _removeFromCart(String productId) {
    setState(() {
      if (_cartItems.containsKey(productId)) {
        if (_cartItems[productId]!.quantity > 1) {
          _cartItems[productId]!.quantity--;
        } else {
          _cartItems.remove(productId);
        }
      }
    });
  }

  // Show cart dialog
  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF002244),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with back button and more options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {
                          // Show more options
                        },
                      ),
                    ],
                  ),
                  
                  // Cart items list
                  Expanded(
                    child: _cartItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Karfan er tóm',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final cartItem = _cartItems.values.elementAt(index);
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.product.id,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF002244),
                                        ),
                                      ),
                                      Text(
                                        '€${cartItem.product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF002244),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    cartItem.product.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: InkWell(
                                    onTap: () {
                                      _removeFromCart(cartItem.product.id);
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.red,
                                      child: const Center(
                                        child: Text(
                                          'X',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Add more button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'BÆTA VIÐ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Process payment
  void _processPayment() async {
    if (_cartItems.isEmpty) return;
    
    // Skip confirmation dialog and directly process payment
    _processPaymentRequest();
  }
  
  // Process payment request to API
  void _processPaymentRequest() async {
    // Show loading indicator
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Calculate total amount
      final totalAmount = _totalPrice;
      
      // Adyen Terminal API credentials
      final String _apiKey = "AQEqhmfxL43JaxFCw0m/n3Q5qf3Ve59fDIZHTXfy5UT9AM9RlDqYku8lh1U2EMFdWw2+5HzctViMSCJMYAc=-iql6F+AYb1jkHn3zzDBcXZZvYzXFr9wd1iCR9y2JDU0=-i1i{=<;wFH*jLc94NQe";
      final String _url = "https://terminal-api-test.adyen.com/sync";
      final String _poiId = "S1F2-000158242574825";
      
      // Generate unique IDs for the transaction
      final now = DateTime.now();
      final String saleId = "Sjoppan-${now.millisecondsSinceEpoch}";
      final String serviceId = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final String transactionId = "Tx-${now.millisecondsSinceEpoch}";

      
      // Create the payment request payload
      final Map<String, dynamic> requestPayload = {
        "SaleToPOIRequest": {
          "MessageHeader": {
            "ProtocolVersion": "3.0",
            "MessageClass": "Service",
            "MessageCategory": "Payment",
            "MessageType": "Request",
            "ServiceID": serviceId,
            "SaleID": saleId,
            "POIID": _poiId
          },
          "PaymentRequest": {
            "SaleData": {
              "SaleTransactionID": {
                "TransactionID": transactionId,
                "TimeStamp": DateTime.now().toIso8601String()
              }
            },
            "PaymentTransaction": {
              "AmountsReq": {
                "Currency": "EUR",
                "RequestedAmount": totalAmount
              }
            }
          }
        }
      };
      
      // Log the request for debugging
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/adyen_log.txt');
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'sale_id': saleId,
        'request': requestPayload,
      };
      
      // Make the API request
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
        },
        body: jsonEncode(requestPayload),
      );
      
      // Log the response
      if (response.statusCode != 200) {
        // API request failed - Add more detailed error logging
        logEntry['error'] = {
          'statusCode': response.statusCode,
          'body': response.body,
        };
        await logFile.writeAsString('${jsonEncode(logEntry)}\n', mode: FileMode.append);
        
        print('API error: ${response.statusCode} - ${response.body}');
        
        setState(() {
          _isProcessingPayment = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Villa við greiðslu: ${response.statusCode} - ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final responseJson = jsonDecode(response.body);
      logEntry['response'] = responseJson;
      
      // Append to log file
      await logFile.writeAsString('${jsonEncode(logEntry)}\n', mode: FileMode.append);
      
      // Determine transaction status
      String transactionStatus = 'Unknown';
      if (responseJson['SaleToPOIResponse'] != null && 
          responseJson['SaleToPOIResponse']['PaymentResponse'] != null &&
          responseJson['SaleToPOIResponse']['PaymentResponse']['Response'] != null) {
        
        final responseResult = responseJson['SaleToPOIResponse']['PaymentResponse']['Response']['Result'];
        transactionStatus = responseResult == 'Success' ? 'Approved' : 'Declined';
      }
      
      // Show status with a more prominent banner instead of a snackbar
      setState(() {
        _isProcessingPayment = false;
        _transactionStatus = transactionStatus;
        _showTransactionStatus = true;
        
        // Clear cart if payment was approved
        if (transactionStatus == 'Approved') {
          _cartItems.clear();
        }
        
        // Auto-hide the status after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showTransactionStatus = false;
            });
          }
        });
      });
    } catch (e) {
      // Handle errors with better logging
      print('Exception during payment processing: $e');
      
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Villa: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show product management dialog
  void _showProductManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF002244),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with back button and title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Vörustjórnun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.category, color: Colors.white),
                            onPressed: () {
                              // Show category management
                              _showCategoryManagementDialog(context, setModalState);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.white),
                            onPressed: () {
                              // Add new product functionality
                              _showAddEditProductDialog(context, setModalState);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Product list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF002244),
                              child: Text(
                                product.id,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '€${product.price.toStringAsFixed(2)} - ${product.category}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    // Edit product functionality
                                    _showAddEditProductDialog(context, setModalState, product: product);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // Delete product functionality
                                    _showDeleteConfirmationDialog(context, setModalState, product);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show category management dialog
  void _showCategoryManagementDialog(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Flokkar'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // List of existing categories
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length - 1, // Skip 'Allt'
                      itemBuilder: (context, index) {
                        // Skip 'Allt' category which is just for filtering
                        final category = _categories[index + 1];
                        return ListTile(
                          title: Text(category),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Check if category is in use
                              final inUse = _products.any((p) => p.category == category);
                              if (inUse) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ekki hægt að eyða $category - í notkun'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Remove category
                              this.setState(() {
                                _categories.remove(category);
                              });
                              setState(() {});
                              setModalState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Add new category
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      _showAddCategoryDialog(context, setState, setModalState);
                    },
                    child: const Text(
                      'Bæta við flokk',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hætta við'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Show dialog to add a new category
  void _showAddCategoryDialog(BuildContext context, StateSetter dialogSetState, StateSetter modalSetState) {
    final categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nýr flokkur'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Heiti flokks',
            hintText: 'T.d. Drykkir, Matur, o.s.frv.',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hætta við'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002244),
            ),
            onPressed: () {
              final newCategory = categoryController.text.trim();
              
              // Validate category name
              if (newCategory.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Flokkur má ekki vera tómur'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Check if category already exists
              if (_categories.contains(newCategory)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Flokkur er nú þegar til'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Add new category
              setState(() {
                _categories.add(newCategory);
              });
              
              // Update both dialogs
              dialogSetState(() {});
              modalSetState(() {});
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Flokk $newCategory bætt við!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Bæta við',
              style: TextStyle(color: Colors.white),
            ),
          ),
          // Transaction status overlay
          if (_showTransactionStatus)
            Container(
              width: double.infinity,
              height: 80,
              color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
              child: Center(
                child: Text(
                  'Greiðsla: $_transactionStatus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show confirmation dialog before deleting a product
  void _showDeleteConfirmationDialog(BuildContext context, StateSetter setModalState, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eyða vöru'),
        content: Text('Ertu viss um að þú viljir eyða ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hætta við'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              setState(() {
                // Remove product from list
                _products.removeWhere((p) => p.id == product.id);
                
                // Also remove from cart if it exists there
                if (_cartItems.containsKey(product.id)) {
                  _cartItems.remove(product.id);
                }
              });
              
              // Update the modal state to reflect changes
              setModalState(() {});
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vöru eytt!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Eyða',
              style: TextStyle(color: Colors.white),
            ),
          ),
          // Transaction status overlay
          if (_showTransactionStatus)
            Container(
              width: double.infinity,
              height: 80,
              color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
              child: Center(
                child: Text(
                  'Greiðsla: $_transactionStatus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show dialog to add or edit a product
  void _showAddEditProductDialog(BuildContext context, StateSetter setModalState, {Product? product}) {
    final isEditing = product != null;
    final idController = TextEditingController(text: isEditing ? product.id : '');
    final nameController = TextEditingController(text: isEditing ? product.name : '');
    final priceController = TextEditingController(text: isEditing ? product.price.toString() : '');
    
    // Use the categories list excluding 'Allt' which is just for filtering
    final productCategories = _categories.where((cat) => cat != 'Allt').toList();
    String selectedCategory = isEditing ? product.category : productCategories[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Breyta vöru' : 'Bæta við vöru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Vörunúmer',
                  hintText: 'T.d. A1, B2, C3',
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vöruheiti',
                  hintText: 'T.d. Pepsi Max',
                ),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Verð (kr)',
                  hintText: 'T.d. 500',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Flokkur',
                ),
                items: productCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hætta við'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002244),
            ),
            onPressed: () {
              // Validate inputs
              if (idController.text.isEmpty || 
                  nameController.text.isEmpty || 
                  priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vinsamlegast fylltu út alla reiti'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Parse price
              final price = int.tryParse(priceController.text);
              if (price == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verð verður að vera heiltala'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Create or update product
              final newProduct = Product(
                id: idController.text,
                name: nameController.text,
                price: price.toDouble(),
                category: selectedCategory,
                color: const Color(0xFFE8F5C8),
              );
              
              setState(() {
                if (isEditing) {
                  // Update existing product
                  final index = _products.indexWhere((p) => p.id == product.id);
                  if (index != -1) {
                    _products[index] = newProduct;
                  }
                } else {
                  // Add new product
                  _products.add(newProduct);
                }
              });
              
              // Update the modal state to reflect changes
              setModalState(() {});
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Vöru breytt!' : 'Vöru bætt við!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              isEditing ? 'Uppfæra' : 'Bæta við',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // Transaction status overlay
          if (_showTransactionStatus)
            Container(
              width: double.infinity,
              height: 80,
              color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
              child: Center(
                child: Text(
                  'Greiðsla: $_transactionStatus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Show payment options dialog
  void _showPaymentOptions(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greiðslumáti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Greiða með korti'),
              onTap: () {
                Navigator.pop(context);
                _processPayment();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hætta við'),
          ),
          // Transaction status overlay
          if (_showTransactionStatus)
            Container(
              width: double.infinity,
              height: 80,
              color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
              child: Center(
                child: Text(
                  'Greiðsla: $_transactionStatus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002244),
      appBar: AppBar(
        title: const Text(
          'Matseðill',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Connect settings icon to product management
              _showProductManagement();
            },
          ),
        ],
      ),
      bottomNavigationBar: _showTransactionStatus ? Container(
        height: 50,
        width: double.infinity,
        color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
        child: Center(
          child: Text(
            'Greiðsla: $_transactionStatus',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ) : null,
      body: Stack(
        children: [
          Column(
        children: [
          // Category filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text(
                  'Flokka: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryButton(category),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Product grid
          Expanded(
            flex: 3,
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
          
          // White background container for cart section
          if (_cartItems.isNotEmpty)
            Container(
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart header
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Karfa',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'EUR ${_totalPrice}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cart items grid
                  Container(
                    height: 150, // Fixed height for the cart grid
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = _cartItems.values.elementAt(index);
                        return _buildCartItemCard(cartItem);
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Payment button
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cartItems.isEmpty ? Colors.grey : const Color(0xFF002244),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isProcessingPayment ? null : _processPayment,
              child: _isProcessingPayment
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'GREIÐA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ),
          ),
          // Transaction status overlay
          if (_showTransactionStatus)
            Container(
              width: double.infinity,
              height: 80,
              color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
              child: Center(
                child: Text(
                  'Greiðsla: $_transactionStatus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      ]));
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = _selectedCategory == category;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFE8F5C8) : Colors.white,
        foregroundColor: isSelected ? Colors.black : Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.green : Colors.grey,
            width: 1,
          ),
        ),
      ),
      onPressed: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Text(category),
    );
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5C8),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              product.id,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF002244),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
                '€${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002244),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return InkWell(
      onTap: () => _removeFromCart(item.product.id),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5C8),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${item.quantity}x ${item.product.id}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.product.name,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF002244),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
                '€${item.product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002244),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;  // Changed from int to double
  final String category;
  final Color color;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.color,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
}