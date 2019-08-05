import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:peliculas/src/models/actores_model.dart';

import 'package:peliculas/src/models/pelicula_model.dart';

class PeliculasProvider {
  
  String _apiKey   = '23d38d0a041d1c511f6f16aa649c3b92';
  String _url      = 'api.themoviedb.org';
  String _language = 'es-ES';

  int _popularesPage = 0;
  bool _cargando     = false;

  List<Pelicula> _populares = new List();
  //broadcast es para tener varios lugares q escuchen el stream
  final _popularesStreamController = StreamController<List<Pelicula>>.broadcast();
  //Para introducir datos
  Function(List<Pelicula>) get popularesSink => _popularesStreamController.sink.add;
  //Para escuchar los datos
  Stream<List<Pelicula>> get popularesStream => _popularesStreamController.stream;

  void disposeStreams() { 
    _popularesStreamController?.close();
  }

  Future<List<Pelicula>> _procesarRespuesta(Uri url) async {
    final resp = await http.get(url);

    final decodedData = json.decode(resp.body);

    final peliculas = new Peliculas.fromJsonList(decodedData['results']);

    return peliculas.items;
  }

  Future<List<Pelicula>> getEnCines() async {
    final url = Uri.https(_url, '3/movie/now_playing', {
      'api_key' : _apiKey,
      'language': _language
    });

    return await _procesarRespuesta(url);
  }

  Future<List<Pelicula>> getPopulares() async {
    //para evitar multiples peticiones al llegar a la ultima tarjeta
    if(_cargando) return [];
    _cargando = true;

    _popularesPage++;
    
    final url = Uri.https(_url, '3/movie/popular', {
      'api_key' : _apiKey,
      'language': _language,
      'page'    : _popularesPage.toString()
    });

    final resp = await _procesarRespuesta(url);

    _populares.addAll(resp);
    popularesSink(_populares);
    //Se normaliza el estado
    _cargando = false;
    return resp;
  }

  Future<List<Actor>> getCast (String peliId) async {
    final url = Uri.https(_url, '3/movie/$peliId/credits',{
      'api_key' : _apiKey,
      'language': _language,
    });

    final resp = await http.get(url);
    final decodedData = json.decode(resp.body);

    final cast = new Cast.fromJsonList(decodedData['cast']);

    return cast.actores;
  }

  Future<List<Pelicula>> buscarPelicula(String query) async {
    final url = Uri.https(_url, '3/search/movie', {
      'api_key' : _apiKey,
      'language': _language,
      'query'   : query,
    });

    return await _procesarRespuesta(url);
  }
}