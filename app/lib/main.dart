import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Restante do seu código...

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fixar a orientação para retrato
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lista de Contatos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ContactListPage(),
    );
  }
}

class ContactListPage extends StatefulWidget {
  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  final List<Contact> contacts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // Carrega os contatos do armazenamento local
  void _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsString = prefs.getString('contacts');
    if (contactsString != null) {
      final List<dynamic> contactsJson = jsonDecode(contactsString);
      setState(() {
        contacts.addAll(contactsJson.map((json) => Contact.fromJson(json)).toList());
      });
    }
  }

  // Salva os contatos no armazenamento local
  void _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String contactsString = jsonEncode(contacts.map((contact) => contact.toJson()).toList());
    prefs.setString('contacts', contactsString);
  }

  @override
  Widget build(BuildContext context) {
    final List<Contact> filteredContacts = contacts
        .where((contact) => contact.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Contatos'),
        backgroundColor: Colors.blue[900], // Azul mais escuro
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white70,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                ),
              ),
            ),
            Expanded(
              child: _buildContactList(filteredContacts),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newContact = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddContactPage(onSave: _saveContacts)),
          );
          if (newContact != null) {
            setState(() {
              contacts.add(newContact);
            });
            _saveContacts();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildContactList(List<Contact> filteredContacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'Não há nenhum contato cadastrado.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    } else if (filteredContacts.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'Contato não localizado.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = filteredContacts[index];
          return Card(
            color: Colors.white70,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.person, color: Colors.blue[700], size: 40.0),
              title: Text(contact.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Telefone: ${contact.phone}'),
                  Text('Celular: ${contact.mobile}'),
                  Text('E-mail: ${contact.email}'),
                  Text('Endereço: ${contact.address}'),
                  Text('Descrição: ${contact.description}'),
                ],
              ),
              onTap: () async {
                final editedContact = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditContactPage(
                      contact: contact,
                      onDelete: () {
                        setState(() {
                          contacts.removeAt(index);
                          _saveContacts();
                        });
                      },
                      onSave: _saveContacts,
                    ),
                  ),
                );
                if (editedContact != null) {
                  setState(() {
                    contacts[index] = editedContact;
                    _saveContacts();
                  });
                }
              },
            ),
          );
        },
      );
    }
  }
}

class AddContactPage extends StatefulWidget {
  final VoidCallback onSave;

  AddContactPage({required this.onSave}); // Adicione uma vírgula aqui

  @override
  _AddContactPageState createState() => _AddContactPageState();
}


class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Contato'),
        backgroundColor: Colors.blue[900], // Azul mais escuro
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(_nameController, 'Nome', Icons.person, true),
                  _buildTextField(_phoneController, 'Telefone', Icons.phone, true, TextInputType.phone),
                  _buildTextField(_mobileController, 'Celular', Icons.smartphone, true, TextInputType.phone),
                  _buildTextField(_emailController, 'E-mail', Icons.email, true, TextInputType.emailAddress),
                  _buildTextField(_addressController, 'Endereço', Icons.home, false),
                  _buildTextField(_descriptionController, 'Descrição', Icons.description, false),
                  SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text;
                    final phone = _phoneController.text;
                    final mobile = _mobileController.text;
                    final email = _emailController.text;
                    final address = _addressController.text;
                    final description = _descriptionController.text;
                    final newContact = Contact(name, phone, mobile, email, address, description);

                    // Aqui salva os dados do novo contato no Firestore
                    final db = FirebaseFirestore.instance;
                    final info = <String, String>{
                      "nome": _nameController.text,
                      "telefone": _phoneController.text,
                      "celular": _mobileController.text,
                      "email": _emailController.text,
                      "endereço": _addressController.text,
                      "descrição": _descriptionController.text,
                    };
                    db.collection('info').doc('info').set(info).onError((error, stackTrace) => print('erro no firebase'));

                    Navigator.pop(context, newContact);
                    widget.onSave();
                  }
                },
                child: Text('Adicionar Contato'),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isRequired, [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.phone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11), PhoneNumberFormatter()] : null,
        decoration: InputDecoration(
          labelText: isRequired ? label : '$label (Campo Opcional)',
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white70,
        ),
        validator: isRequired
            ? (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo é obrigatório';
          }
          return null;
        }
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class EditContactPage extends StatefulWidget {
  final Contact contact;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  EditContactPage({required this.contact, required this.onDelete, required this.onSave});

  @override
  _EditContactPageState createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
    _mobileController = TextEditingController(text: widget.contact.mobile);
    _emailController = TextEditingController(text: widget.contact.email);
    _addressController = TextEditingController(text: widget.contact.address);
    _descriptionController = TextEditingController(text: widget.contact.description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Contato'),
        backgroundColor: Colors.blue[900], // Azul mais escuro
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(_nameController, 'Nome', Icons.person, true),
                  _buildTextField(_phoneController, 'Telefone', Icons.phone, true, TextInputType.phone),
                  _buildTextField(_mobileController, 'Celular', Icons.smartphone, true, TextInputType.phone),
                  _buildTextField(_emailController, 'E-mail', Icons.email, true, TextInputType.emailAddress),
                  _buildTextField(_addressController, 'Endereço', Icons.home, false),
                  _buildTextField(_descriptionController, 'Descrição', Icons.description, false),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          widget.contact.name = _nameController.text;
                          widget.contact.phone = _phoneController.text;
                          widget.contact.mobile = _mobileController.text;
                          widget.contact.email = _emailController.text;
                          widget.contact.address = _addressController.text;
                          widget.contact.description = _descriptionController.text;
                        });
                        Navigator.pop(context, widget.contact);
                        widget.onSave();
                      }
                    },
                    child: Text('Salvar Alterações'),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.red)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirmar Exclusão'),
                            content: Text('Tem certeza que deseja excluir este contato?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('NÃO'),
                              ),
                              TextButton(
                                onPressed: () {
                                  widget.onDelete();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                                child: Text('SIM'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('Excluir Contato'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isRequired, [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.phone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11), PhoneNumberFormatter()] : null,
        decoration: InputDecoration(
          labelText: isRequired ? label : '$label (Campo Opcional)',
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white70,
        ),
        validator: isRequired
            ? (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo é obrigatório';
          }
          return null;
        }
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.length >= 3 && !text.startsWith('(')) {
      final newText = '(${text.substring(0, 2)}) ${text.substring(2)}';
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    return newValue;
  }
}

// Classe para representar um contato
class Contact {
  String name;
  String phone;
  String mobile;
  String email;
  String address;
  String description;

  Contact(this.name, this.phone, this.mobile, this.email, this.address, this.description);

  // Converte um contato em um mapa
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'mobile': mobile,
    'email': email,
    'address': address,
    'description': description,
  };

  // Cria um contato a partir de um mapa
  Contact.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        phone = json['phone'],
        mobile = json['mobile'],
        email = json['email'],
        address = json['address'],
        description = json['description'];
}
