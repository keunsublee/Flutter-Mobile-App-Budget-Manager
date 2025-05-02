import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

// Configure routes.
final _router =
    Router()
      ..get('/', _rootHandler)
      ..get('/echo/<message>', _echoHandler);

// Database 
// ignore: prefer_typing_uninitialized_variables
late var database; 

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

// TODO: POST Request for putting data into database for all three tables

// TODO: GET  Request for grabbing data from database from all three tables 

// TODO: PUT  Request for updating table in database for all three tables   

void main(List<String> args) async {
  // TODO: Connect to PostgreSQL Database
  print('INSTANCE_CONNECTION_NAME: ${Platform.environment['INSTANCE_CONNECTION_NAME']}');
  print('DB_USER: ${Platform.environment['DB_USER']}');
  print('DB_NAME: ${Platform.environment['DB_NAME']}');
  print('DB_PASS: ${Platform.environment['DB_PASS']}');
  

  database = await Connection.open(
    Endpoint(
      host: '/cloudsql/${Platform.environment['INSTANCE_CONNECTION_NAME']}',
      database: Platform.environment['DB_NAME'] ?? "",
      username: Platform.environment['DB_USER'],
      password: Platform.environment['DB_PASS'],
      port: 5432,
      isUnixSocket: true,
      ),
  );
  print('✅ Connected to Cloud SQL from Cloud Run!');

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
