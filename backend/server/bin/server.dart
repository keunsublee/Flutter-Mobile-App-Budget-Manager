import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

// Configure routes.
final _router =
    Router()
      ..get('/', _rootHandler)
      ..get('/user/<email>', _userGet)
      ..post('/user/<email>', _userPost);

// Database 
late Connection database; 

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

// TODO: POST Request for putting data into database for all three tables
Future<Response> _userPost(Request request) async {
  final email = request.params['email'];
  final decode = jsonDecode(await request.readAsString());
  final uuid = Uuid().v4();

  // TODO: add email check here to see if user exists in database
  
  // query format
  const query = '''
    INSERT INTO public.users (
      user_id,
      email,
      first_name,
      last_name,
      img_url,
      created_on
    )
    VALUES (
      \$1,
      \$2,
      \$3,
      \$4,
      \$5,
      NOW()
    )
    ''';

    // add parameters to query
    final parameters = [
      uuid,                   // UUID
      email,                  // email
      decode['first_name'],   // first_name
      decode['last_name'],    // last_name
      decode['img_url'],      // img_url
    ];

  try {
    await database.execute(query, parameters: parameters);
    print("User has been added: $email");
    return Response.ok("User has been added!");
  } catch (e) {
    print('Error inserting user: $e');
    return Response.internalServerError(body: 'An error occurred while adding the user.');
  }
}


// TODO: GET Request for grabbing data from database from all three tables 
Future<Response> _userGet(Request request) async {
  final email = request.params['email'];

  //query format
  var query = Sql.named('SELECT * FROM public.users WHERE email = @email');

  // add parameters to query
  final parameters = { 'email': email };

  List<Map<String, dynamic>> userList = [];
  try {
    final find = await database.execute(query, parameters: parameters);

    if(find.isNotEmpty) {
      for (final row in find) {
        final Map<String, dynamic> rowMap = row.toColumnMap();
        rowMap.forEach((key, value) {
        if (value is DateTime) {
          rowMap[key] = value.toIso8601String(); 
       }
      });
        userList.add(rowMap);
      }

      return Response.ok(jsonEncode(userList));
    } else {
      return Response.notFound("User not found.");
    }
  } catch (e) {
      print (e);
      return Response.internalServerError(body: 'An error occured while trying to find user.');
  }
}

// TODO: PUT  Request for updating table in database for all three tables   

void main(List<String> args) async {
  database = await Connection.open(
  //   Endpoint(
  //     host: '/cloudsql/${Platform.environment['INSTANCE_CONNECTION_NAME']}/.s.PGSQL.5432',
  //     database: Platform.environment['DB_NAME'] ?? "",
  //     username: Platform.environment['DB_USER'],
  //     password: Platform.environment['DB_PASS'],
  //     port: 5432,
  //     isUnixSocket: true,
  //     ),
  //     settings: ConnectionSettings(sslMode: SslMode.disable),
    Endpoint(host: '127.0.0.1', database: 'postgres', username: 'postgres', password: 'admin', port: 5432),
    settings: ConnectionSettings(sslMode: SslMode.disable),

  );
  print('Connected to Cloud SQL from Cloud Run!');

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
