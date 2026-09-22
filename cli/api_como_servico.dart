/*
Interface comum entre os dois jeitos do CLI falar com os dados: via HTTP de
verdade (ApiClient, em httpHandler.dart) ou local via SQLite (SqliteApiClient,
em sqlite_backend.dart) quando nenhuma API responde. O resto do CLI
(main.dart) não sabe nem precisa saber qual dos dois está por trás — só usa
get/post/patch/delete com os mesmos paths e recebe as mesmas estruturas de
JSON (Map/List) de volta.
*/

abstract class ApiComoServico {
  /// Descrição curta de onde os dados estão vindo, só pra mostrar no início
  /// do CLI (ex: "http://localhost:3000" ou "SQLite local (arquivo.db)").
  String get origem;

  Future<dynamic> get(String path);

  Future<dynamic> post(String path, [Map<String, dynamic>? corpo]);

  Future<dynamic> patch(String path, [Map<String, dynamic>? corpo]);

  Future<dynamic> delete(String path);

  void close();
}
