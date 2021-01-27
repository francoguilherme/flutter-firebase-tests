import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:english_words/english_words.dart';
import 'package:image_picker/image_picker.dart'; // For Image Picker
import 'package:path/path.dart' as path;
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rango',
      home: LoginScreen(),
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class LoginScreenState extends State<LoginScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _database = Firestore.instance;
  final _storage = FirebaseStorage.instance;
  var pictureUrl = "";
  var signedIn = false;
  File _image;
  final picker = ImagePicker();

  void _signUp(TextEditingController email, TextEditingController password) async {
    print('SignUp: Email: ${email.text}, Password: ${password.text}');
    try {
      final authResult = await _auth.createUserWithEmailAndPassword(email: email.text, password: password.text);
      print(authResult);
      await _database.collection('clients')
          .document(authResult.user.uid)
          .setData({'email': authResult.user.email, 'name': name.text, 'phone': phone.text, 'picture': ''});
    } catch(e) {
      print(e);
      if (e.toString().contains('ERROR_EMAIL_ALREADY_IN_USE')) {
        _showDialog('Usuário já existe');
      } else {
        _showDialog('Tente novamente');
      }
    }
  }

  void _signIn(TextEditingController email, TextEditingController password) async {
    print('SignIn: Email: ${email.text}, Password: ${password.text}');
    try {
      final FirebaseUser user = (await _auth.signInWithEmailAndPassword(email: email.text, password: password.text)).user;
      print("signed in " + user.email);
    } catch(e) {
      print(e);
      if (e.toString().contains('ERROR_WRONG_PASSWORD')) {
        _showDialog('Senha inválida');
      } else {
        _showDialog('Tente novamente');
      }
    }
  }

  void _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
      _showDialog(e.toString());
    }
  }

  void _chooseImage() async {
    var extension = "";
    try {
      await picker.getImage(source: ImageSource.gallery).then((image) {
        setState(() {
          _image =  File(image.path);
          extension = path.extension(image.path);
        });
      });
      var currentUser = await _auth.currentUser();
      final storageReference = _storage.ref().child('clientPictures/${currentUser.uid+extension}');
      StorageUploadTask uploadTask = storageReference.putFile(_image);
      await uploadTask.onComplete;
      print('File Uploaded');
      storageReference.getDownloadURL().then((fileURL) {
        setState(() {
          pictureUrl = fileURL;
        });
      });
    } catch (e) {
      print(e);
      _showDialog(e.toString());
    }

  }

  void _showDialog(String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text('Erro'),
          content: new Text(text),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text('Login')
        ),
        body: Container(
          child: ListView(
            padding: EdgeInsets.all(18),
            children: <Widget>[
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: 'Nome',
                ),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
              TextField(
                controller: password,
                decoration: InputDecoration(
                  labelText: 'Senha',
                ),
              ),
              TextField(
                controller: phone,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                ),
              ),
              Container(
                  child: Card(
                    child: SizedBox(
                        width: 20.0,
                        height: 40.0,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Image(
                                image: NetworkImage(pictureUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(

                              right: 4.0,
                              child: IconButton(icon: Icon(Icons.edit), onPressed: () => _chooseImage()),
                            )
                          ],
                        )
                    ),
                  )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Cadastrar'),
                    onPressed: () => _signUp(email, password),
                  ),
                  RaisedButton(
                    child: Text('Entrar'),
                    onPressed: () => _signIn(email, password),
                  )
                ],
              ),
              Container(
                child: Card(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 180.0,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Image(
                                image: NetworkImage(pictureUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 4.0,
                              right: 4.0,
                              child: IconButton(icon: Icon(Icons.edit), onPressed: null),
                            )
                          ],
                        )
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                        child: Column(
                          children: <Widget>[
                            TextField(
                                controller: name,
                                decoration: InputDecoration(
                                  labelText: 'Nome',
                                ),
                                enabled: false
                            ),
                            TextField(
                              controller: password,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                              ),
                              enabled: false,
                              obscureText: true,
                            ),
                            TextField(
                                controller: phone,
                                decoration: InputDecoration(
                                  labelText: 'Telefone',
                                  //enabledBorder: OutlineInputBorder(borderSide: BorderSide())
                                ),
                                enabled: false
                            ),
                          ],
                        ),
                      )
                    ]
                  ),
                )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Sair'),
                    onPressed: () => _signOut(),
                  ),
                  RaisedButton(
                    child: Text('Remover'),
                    onPressed: () => _signOut(),
                  )
                ],
              ),
            ],
          )
        )
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = Set<WordPair>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.only(left:8, right: 16.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return Divider();

          final index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  Widget _buildRow(WordPair pair) {
    final bool alreadySaved = _saved.contains(pair);
    return ListTile(
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
      leading: Image.network(
          'https://p2.trrsf.com/image/fget/cf/940/0/images.terra.com/2019/01/31/casquinha-de-sorvete.jpg',
          scale: 1,
          repeat: ImageRepeat.noRepeat
      ),
      contentPadding: EdgeInsets.only(left: 0, right: 16),
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      subtitle: Text('subtitle'),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (BuildContext context) {
              final Iterable<ListTile> tiles = _saved.map(
                      (WordPair pair) {
                    return ListTile(
                        title: Text(
                          pair.asPascalCase,
                          style: _biggerFont,
                        )
                    );
                  }
              );

              final List<Widget> divided = ListTile
                  .divideTiles(tiles: tiles, context: context)
                  .toList();

              return Scaffold(
                  appBar: AppBar(
                      title: Text('Saved Suggestions')
                  ),
                  body: ListView(children: divided)
              );
            }
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Startup Name Generator'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
          ]
      ),
      body: _buildSuggestions(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  RandomWordsState createState() => RandomWordsState();
}

/*
  void getData() {
    databaseReference
        .collection("sellers")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) => print('${f.data}}'));
    });
  }
  */