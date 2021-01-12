import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  final _toDoController = TextEditingController();

  //equivalente do onresume????
  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  //usou future para dar um delay, Null pq nao volta nada, async pq é futuro
  Future<Null> _refresh() async {
    //esperando 1 segundo
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      //sort do dart
      _toDoList.sort((x, y) {
        if (x["ok"] && !y["ok"])
          return 1;
        else if (!x["ok"] && y["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    //retorno null por conta do esquema do delay ali
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                //expanded para ocupar o espaço total permitido
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  onPressed: _addToDo,
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            //fazendo a lista
            child: RefreshIndicator(
              //qdo vc arrasta a tela com o dedo para baixo
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  //tamanho da lista, qtos itens tem
                  itemCount: _toDoList.length,
                  //item da lista
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      //precisa de uma chave, para ele saber qual item esta sendo deslizado, e nao pode ser repetida, por isso usar o tempo
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          //alinhamento do icone da lixeira, vai de 1 a -1 nos dois eixos
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      //direction é o sentido q vc arrasta, pode usar para fazer coisas em sentidos diferentes
      direction: DismissDirection.startToEnd,
      //filho do dismissible é oq aparece
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        //onchanged pega o valor do bool true or false do checkbox
        onChanged: (check) {
          setState(() {
            //atribudindo o true ou false no mapa no lugar clicado
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
      ),
      //coisas por sentido do arrastar
      onDismissed: (direction) {
        setState(() {
          //duplicando o item no mapa lastRemoved
          _lastRemoved = Map.from(_toDoList[index]);
          //pegando a ultima posição para salvar caso queira voltar
          _lastRemovedPos = index;
          //removendo da lista
          _toDoList.removeAt(index);
          _saveData();
          //barra no rodapé para o cara poder cancelar
          final snackBar = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );
          //remover uma snackbar caso exista, para nao encavalar barras
          Scaffold.of(context).removeCurrentSnackBar();
          //mostrar a snackbar
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  //funcao para obter um arquivo (nesse caso data.json)
  Future<File> _getFile() async {
    //pegando o caminho q pode salvar
    final directory = await getApplicationDocumentsDirectory();
    //pegando o caminho junto com o arquivo (nesse caso data.json)
    return File("${directory.path}/data.json");
  }

  //salvando no data.json
  Future<File> _saveData() async {
    //transformando a lista em um json
    String data = json.encode(_toDoList);
    //pegando o arquivo json
    final file = await _getFile();
    //devolvendo o arquivo com as coisas salvas
    return file.writeAsString(data);
  }

  //lendo o data.json
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
