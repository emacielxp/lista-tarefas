import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
      home: Home()
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _tarefasController =  TextEditingController();

  List _listaTarefas = [];
  Map<String, dynamic> _ultimoRemovido;
  int _ultimoRemovidoPos;

  @override
  void initState() {
    super.initState();

    _lerDados().then((dados) {
      setState(() {
        _listaTarefas = json.decode(dados);
      });
    });
  }

  void _novaTarefa() {
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["title"] = _tarefasController.text;
      _tarefasController.text = "";
      novaTarefa["ok"] = false;
      _listaTarefas.add(novaTarefa);
      _salvaDados();
      _ordenaLista();
    });
  }

  Future<Null> _ordenaLista() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _listaTarefas.sort((a, b){
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });

      _salvaDados();
    });

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
        children: <Widget> [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget> [
                Expanded(
                  child: TextField(
                    controller: _tarefasController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Nova"),
                  textColor: Colors.white,
                  onPressed: _novaTarefa,
                )
              ]
            )
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _listaTarefas.length,
                  itemBuilder: criaItem
              ),
              onRefresh: _ordenaLista
            )
          )
        ]
      ),
    );
  }

  Widget criaItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white)
        )
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_listaTarefas[index]["title"]),
        value: _listaTarefas[index]["ok"],
        secondary: CircleAvatar(
            child: Icon(_listaTarefas[index]["ok"] ? Icons.check : Icons.error)
        ),
        onChanged: (marcado) {
          setState(() {
            _listaTarefas[index]["ok"] = marcado;
            _salvaDados();
            _ordenaLista();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _ultimoRemovido = Map.from(_listaTarefas[index]);
          _ultimoRemovidoPos = index;
          _listaTarefas.removeAt(index);
          _salvaDados();

          final snackBar = SnackBar(
            content: Text("Tarefa \"${_ultimoRemovido["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _listaTarefas.insert(_ultimoRemovidoPos, _ultimoRemovido);
                  _salvaDados();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  Future<File> _recuperaArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();

    return File("${diretorio.path}/data.json");
  }

  Future<File> _salvaDados() async {
    String dados = json.encode(_listaTarefas);
    final arquivo = await _recuperaArquivo();

    return arquivo.writeAsString(dados);
  }

  Future<String> _lerDados() async {
    try {
      final arquivo = await _recuperaArquivo();

      return arquivo.readAsString();
    } catch (e) {
      return null;
    }
  }
}