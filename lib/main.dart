import 'dart:convert'; // Для работы с JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // Переменная для управления видимостью пароля
  String? _currentUsername; // Переменная для хранения имени пользователя

  Future<void> _login() async {
    final String url = 'https://exx.pythonanywhere.com/login/';
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == 'Login successful') {
          // Сохраняем имя пользователя в переменную состояния
          setState(() {
            _currentUsername = username;
          });

          // Передаем имя пользователя на следующий экран
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExchangeScreen(username: _currentUsername!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Invalid credentials')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // Фон экрана
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome to Exchanger',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40.0), // Увеличенное расстояние до полей
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800], // Цвет текстового поля
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 30.0), // Увеличенное расстояние между полями
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword, // Переключаем видимость пароля
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility, // Изменяем иконку
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword; // Переключаем видимость пароля
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 40.0), // Увеличенное расстояние до кнопки
              _isLoading
                  ? CircularProgressIndicator() // Индикатор загрузки
                  : ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExchangeScreen extends StatefulWidget {
  final String username;

  ExchangeScreen({required this.username});

  @override
  _ExchangeScreenState createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  bool isUpPressed = false;
  bool isDownPressed = false;
  String? selectedCurrency;
  String? transactionType;
  String selectedMenuOption = 'Меню';

  bool isDropdownOpen = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  List<String> currencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      List<String> fetchedCurrencies = await fetchCurrencies();
      setState(() {
        currencies = fetchedCurrencies;
      });
    } catch (e) {
      print('Error loading currencies: $e');
    }
  }

  Future<List<String>> fetchCurrencies() async {
    final response = await http.get(Uri.parse('http://exx.pythonanywhere.com/currencies/'));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodedBody);
      return data.map((currency) => currency['name'] as String).toList();
    } else {
      throw Exception('Failed to load currencies');
    }
  }

  Future<void> _sendData() async {
    final String currency = selectedCurrency ?? '';
    final String amount = _amountController.text;
    final String rate = _rateController.text;
    final String total = _totalController.text;

    if (currency.isEmpty || amount.isEmpty || rate.isEmpty || total.isEmpty || transactionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните все поля!')),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'currency': currency,
      'amount': amount,
      'exchange_rate': rate,
      'transaction_type': transactionType,
      'username': widget.username
    };

    // // Очистка полей после успешного сохранения
    // setState(() {
    //   _amountController.clear();
    //   _rateController.clear();
    //   _totalController.clear();
    //   selectedCurrency = null;
    //   isUpPressed = false;
    //   isDownPressed = false;
    // });

    try {
      final response = await http.post(
        Uri.parse('http://exx.pythonanywhere.com/transactions/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Данные успешно отправлены!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке данных!')),
        );
      }
    } catch (e) {
      print('Ошибка при отправке данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось подключиться к серверу!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: DropdownButton<String>(
          value: isDropdownOpen ? null : selectedMenuOption,
          dropdownColor: Colors.green,
          iconEnabledColor: Colors.white,
          items: <String>['Меню', 'Валюты','Касса', 'Работники', 'Очистка']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) async {
            if (newValue == null) return;

            setState(() {
              isDropdownOpen = false;
            });

            if (newValue == 'Очистка') {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ConfirmClearDialog();
                },
              );
            } else if (newValue == 'Валюты') {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CurrenciesScreen()),
              );
              await _loadCurrencies();
            } else if (newValue == 'Работники') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WorkersScreen()),
              );
            } else if (newValue == 'Касса') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BoxOfficeScreen()),
              );
            }
          },
          style: TextStyle(color: Colors.white),
          underline: Container(
            height: 2,
            color: Colors.white,
          ),
          onTap: (){
            setState(() {
              isDropdownOpen = true;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.green,
                items: currencies.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.green),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCurrency = newValue;
                  });
                },
                style: TextStyle(color: Colors.green),
                underline: Container(
                  height: 2,
                  color: Colors.green,
                ),
                hint: Text(
                  'Выберите валюту',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Количество',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Курс',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalController,
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'Общее',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    double? amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
                    double? rate = double.tryParse(_rateController.text.replaceAll(',', '.'));

                    if (amount != null && rate != null) {
                      double total = amount * rate;
                      setState(() {
                        _totalController.text = total.toStringAsFixed(2);
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Введите корректные значения!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Icon(Icons.calculate, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isUpPressed = true;
                      isDownPressed = false;
                      transactionType = 'sell';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isUpPressed ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      color: isUpPressed ? Colors.white : Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 32.0),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isDownPressed = true;
                      isUpPressed = false;
                      transactionType = "buy";
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isDownPressed ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      color: isDownPressed ? Colors.white : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Добавить',
              style: TextStyle(fontSize: 16),)
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EventsScreen(currencies: currencies)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Coбытия',
              style: TextStyle(fontSize: 16.0),)
            ),
          ],
        ),
      ),
    );
  }
}

class CurrenciesScreen extends StatefulWidget {
  @override
  _CurrenciesScreenState createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  List<Map<String, dynamic>> currencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final fetchedCurrencies = await CurrencyService.fetchCurrencies();
      setState(() {
        currencies = fetchedCurrencies;
      });
    } catch (e) {
      _showError('Не удалось загрузить список валют.');
    }
  }

  void _addCurrency(String newCurrency) async {
    try {
      final addedCurrency = await CurrencyService.addCurrency(newCurrency);
      setState(() {
        currencies.add(addedCurrency);
      });
    } catch (e) {
      _showError('Не удалось добавить валюту.');
    }
  }

  void _deleteCurrency(int id) async {
    try {
      await CurrencyService.deleteCurrency(id);
      setState(() {
        currencies.removeWhere((currency) => currency['id'] == id);
      });
    } catch (e) {
      _showError('Не удалось удалить валюту.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Валюты'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                return ListTile(
                  title: Text(currency['name'],
                  style: TextStyle(color: Colors.white),
                ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCurrency(currency['id']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showAddCurrencyDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: Text('Добавить валюту', style: TextStyle(fontSize: 16.0)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCurrencyDialog(onAdd: _addCurrency);
      },
    );
  }
}

class AddCurrencyDialog extends StatelessWidget {
  final Function(String) onAdd;

  AddCurrencyDialog({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    return AlertDialog(
      title: Text('Добавить валюту'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: 'Название валюты'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Отмена')),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              onAdd(_controller.text);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: Text('Добавить', style: TextStyle(fontSize: 16.0)),
        ),
      ],
    );
  }
}

class CurrencyService {
  static const String _baseUrl = 'http://exx.pythonanywhere.com/currencies/';

  // Получение списка валют
  static Future<List<Map<String, dynamic>>> fetchCurrencies() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final decodeResponse = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodeResponse);
      return data
          .map((currency) => {'id': currency['id'], 'name': currency['name']})
          .toList();
    } else {
      throw Exception('Failed to load currencies');
    }
  }

  // Добавление новой валюты
  static Future<Map<String, dynamic>> addCurrency(String name) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    if (response.statusCode == 201) {
      final decodeResponse = utf8.decode(response.bodyBytes);
      return json.decode(decodeResponse);
    } else {
      throw Exception('Failed to add currency');
    }
  }

  // Удаление валюты
  static Future<void> deleteCurrency(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl$id/'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete currency');
    }
  }
}

class WorkersScreen extends StatefulWidget {
  @override
  _WorkersScreenState createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  List<Map<String, String>> workers = []; // Список работников из базы данных
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWorkers(); // Загрузка работников при открытии экрана
  }

  // Загрузка работников с сервера
  Future<void> fetchWorkers() async {
    final url = Uri.parse('http://exx.pythonanywhere.com/workers/');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        setState(() {
          workers = responseData.map((worker) {
            return {'username': worker['username'].toString()};
          }).toList();
        });
      } else {
        showErrorDialog('Не удалось загрузить работников: ${response.statusCode}');
      }
    } catch (error) {
      showErrorDialog('Ошибка подключения: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addWorkerToServer(String username, String password) async {
    final url = Uri.parse('http://exx.pythonanywhere.com/add-worker/');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 201) { // Код 201 для успешного добавления
        // Добавляем нового работника в локальный список
        setState(() {
          workers.add({'username': username});
        });
      } else {
        final responseData = jsonDecode(response.body);
        showErrorDialog(responseData['error'] ?? 'Ошибка при добавлении работника.');
      }
    } catch (error) {
      showErrorDialog('Не удалось подключиться к серверу.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Универсальный метод для отображения ошибок
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Работники'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: workers.isEmpty
                    ? Center(child: Text('Список работников пуст.'))
                : ListView.builder(
              itemCount: workers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(workers[index]['username']!,
                  style: TextStyle(color: Colors.white),
    ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddWorkerDialog(
                      addWorker: (username, password) async {
                        await addWorkerToServer(username, password);
                        fetchWorkers();
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Добавить работника',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddWorkerDialog extends StatefulWidget {
  final Function(String, String) addWorker;

  AddWorkerDialog({required this.addWorker});

  @override
  _AddWorkerDialogState createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends State<AddWorkerDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Добавить работника'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Имя пользователя',
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Пароль',
            ),
            obscureText: true,
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
            final username = _usernameController.text.trim();
            final password = _passwordController.text.trim();

            if (username.isNotEmpty && password.isNotEmpty) {
              setState(() {
                _isLoading = true;
              });

              await widget.addWorker(username, password);

              setState(() {
                _isLoading = false;
              });

              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Введите имя пользователя и пароль')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            'Добавить',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ],
    );
  }
}

class ConfirmClearDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Вы уверены?'),
      content: Text('Вы действительно хотите выполнить очистку?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Нет'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Выполнение запроса на сервер для удаления всех транзакций
            final response = await http.delete(Uri.parse('http://exx.pythonanywhere.com/clear-transactions/'));

            if (response.statusCode == 204) {
              // Успешно удалены все транзакции
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Все транзакции удалены')));
            } else {
              // Ошибка при удалении
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при удалении')));
            }

            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            'Да',
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ],
    );
  }
}

class EventsScreen extends StatefulWidget {
  final List<String> currencies;

  EventsScreen({required this.currencies});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> transactions = [];
  String? selectedCurrency;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTransactions(); // Изначально загружаем все транзакции
  }

  Future<void> fetchTransactions({String? type, String? currency}) async {
    setState(() {
      isLoading = true;
    });

    String url = 'https://exx.pythonanywhere.com/api/transaction-history/';
    Map<String, String> queryParams = {};

    if (type != null) queryParams['transaction_type'] = type;
    if (currency != null) queryParams['currency'] = currency;

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          final decodedBody = utf8.decode(response.bodyBytes);
          transactions = List<Map<String, dynamic>>.from(json.decode(decodedBody));
          isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteTransaction(int id) async {
    String url = 'https://exx.pythonanywhere.com/api/transaction-history/$id/';
    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 204) {
        setState(() {
          transactions.removeWhere((transaction) => transaction['id'] == id);
        });
      } else {
        print('Error deleting transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  String simplifyTimestamp(String timestamp) {
    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Некорректная дата';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('События'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            isLoading
                ? CircularProgressIndicator()
                : _buildCurrencyDropdown(),
            SizedBox(height: 16),
            _buildTransactionButtons(),
            SizedBox(height: 16),
            Expanded(
              child: _buildTransactionHistory(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blueGrey,
    );
  }

  Widget _buildCurrencyDropdown() {
    List<String> allCurrencies = ['Вся история'] + widget.currencies;

    return DropdownButton<String>(
      value: selectedCurrency,
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.white,
      items: allCurrencies.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedCurrency = newValue;
        });
        // Если выбрана "Вся история", то показываем все транзакции
        if (newValue == 'Вся история') {
          fetchTransactions(); // Показать все транзакции
        } else {
          fetchTransactions(currency: newValue); // Показать транзакции для выбранной валюты
        }
      },
      style: TextStyle(color: Colors.green),
      underline: Container(
        height: 2,
        color: Colors.green,
      ),
      hint: Text(
        'Выберите валюту',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTextButton('Продажа', () {
          fetchTransactions(
            type: 'sell',
            currency: selectedCurrency == 'Вся история' ? null : selectedCurrency,
          );
        }),
        _buildTextButton('Покупка', () {
          fetchTransactions(
            type: 'buy',
            currency: selectedCurrency == 'Вся история' ? null : selectedCurrency,
          );
        }),
      ],
    );
  }

  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          child: ListTile(
            title: Text(
              '${transaction['amount']} ${transaction['currency']}',
            ),
            subtitle: Text(
              '${transaction['transaction_type'] == 'buy' ? 'Покупка' : 'Продажа'} по курсу ${transaction['exchange_rate']}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(simplifyTimestamp(transaction['timestamp'])),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteTransaction(transaction['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BoxOfficeScreen extends StatefulWidget {
  @override
  _BoxOfficeScreenState createState() => _BoxOfficeScreenState();
}

class _BoxOfficeScreenState extends State<BoxOfficeScreen> {
  List<dynamic> transactions = [];
  double totalProfit = 0.0;
  bool isLoading = true;
  double somBalance = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
    fetchSomBalance();
  }

  Future<void> fetchSomBalance() async {
    final url = Uri.parse('https://exx.pythonanywhere.com/som_balance');  // Адрес API для получения баланса
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Безопасное преобразование и проверка на null
          somBalance = data['balance'] != null ? double.tryParse(data['balance'].toString()) ?? 0.0 : 0.0;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load balance');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> fetchTransactions() async {
    final url = Uri.parse('http://exx.pythonanywhere.com/aggregate_transactions/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          transactions = data['transactions'].map((transaction) {
            return {
              'currency': transaction['currency'],
              'total_buy_amount': double.tryParse(transaction['total_buy_amount'].toString()) ?? 0.0,
              'total_sell_amount': double.tryParse(transaction['total_sell_amount'].toString()) ?? 0.0,
              'avg_buy_rate': double.tryParse(transaction['avg_buy_rate'].toString()) ?? 0.0,
              'avg_sell_rate': double.tryParse(transaction['avg_sell_rate'].toString()) ?? 0.0,
              'profit': double.tryParse(transaction['profit'].toString()) ?? 0.0,
            };
          }).toList();
          totalProfit = double.tryParse(data['total_profit'].toString()) ?? 0.0;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Касса'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Заголовки таблицы
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTableHeader('Валюта'),
                _buildTableHeader('Покупка'),
                _buildTableHeader('Продажа'),
                _buildTableHeader('Курс покупки'),
                _buildTableHeader('Курс продажи' ),
                _buildTableHeader('Выручка'),
              ],
            ),
            Divider(color: Colors.black),
            // Данные таблицы
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),  // Добавляем отступ между строками
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTableCell(transaction['currency']),
                        _buildTableCell(transaction['total_buy_amount'].toStringAsFixed(2)),
                        _buildTableCell(transaction['total_sell_amount'].toStringAsFixed(2)),
                        _buildTableCell(transaction['avg_buy_rate'].toStringAsFixed(2)),
                        _buildTableCell(transaction['avg_sell_rate'].toStringAsFixed(2)),
                        _buildTableCell(transaction['profit'].toStringAsFixed(2)),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            // Выручка и баланс СОМ
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSummaryBox('Выручка', totalProfit),
                SizedBox(width: 100), // Отступ между блоками
                _buildSummaryBox('Сoм', somBalance),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTableHeader(String text) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSummaryBox(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 120,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
