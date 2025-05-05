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
      // User routes
      ..get('/user/<email>', _userGet)
      ..post('/user/<email>', _userPost)
      ..patch('/user/<uuid>', _userPatch)
      // Planning routes
      ..get('/planning/<uuid>', _planningGet)
      ..post('/planning/<uuid>', _planningPost)
      ..patch('/planning/<uuid>', _planningPatch);

// Database
late Connection database;

Response _rootHandler(Request req) {
  return Response.ok('Backend is online!\n');
}

// TODO: POST Request for putting data into database for all tables
Future<Response> _userPost(Request request) async {
  final email = request.params['email'];
  final decode = jsonDecode(await request.readAsString());
  final uuid = Uuid().v4();

  // TODO: add email check here to see if user exists in database

  // query format
  final query = Sql.named('''
    INSERT INTO public.users (
      user_id,
      email,
      first_name,
      last_name,
      img_url,
      created_on
    )
    VALUES (
      @user_id,
      @email,
      @first_name,
      @last_name,
      @img_url,
      NOW()
    )
  ''');

  // add parameters to query
  final parameters = {
    'user_id': uuid,
    'email': email,
    'first_name': decode['first_name'],
    'last_name': decode['last_name'],
    'img_url': decode['img_url'],
  };
  if (email != null &&
      decode['first_name'] != null &&
      decode['last_name'] != null &&
      decode['img_url'] != null) {
    try {
      await database.execute(query, parameters: parameters);
      print("User has been added: $email");
      return Response.ok("User has been added!");
    } catch (e) {
      print('Error inserting user: $e');
      return Response.internalServerError(
        body: 'An error occurred while adding the user.',
      );
    }
  } else {
    return Response.badRequest(
      body: "Request does not contain all data required.",
    );
  }
}

Future<Response> _planningPost(Request request) async {
  final uuid = request.params['uuid'];
  final decode = jsonDecode(await request.readAsString());

  final query = Sql.named('''
    INSERT INTO public.planning (
      user_id, 
      month, 
      data
      )
    VALUES (
      @user_id,
      @month,
      @data
      )
  ''');

  final parameters = {
    'user_id': uuid,
    'month': decode['month'],
    'data': decode['data'],
  };

  if (decode['month'] != null && decode['data'] != null) {
    try {
      await database.execute(query, parameters: parameters);
      print("Data has been added: $uuid");
      return Response.ok(
        "Data has successfully been added to data for user: $uuid",
      );
    } catch (e) {
      print('Error inserting data: $e');
      return Response.internalServerError(
        body: 'An error occurred while adding data.',
      );
    }
  } else {
    return Response.badRequest(
      body: "Request does not contain all data required.",
    );
  }
}

// TODO: GET Request for grabbing data from database from all tables
Future<Response> _userGet(Request request) async {
  final email = request.params['email'];

  //query format
  var query = Sql.named('SELECT * FROM public.users WHERE email = @email');

  // add parameters to query
  final parameters = {'email': email};

  List<Map<dynamic, dynamic>> userList = [];
  try {
    final find = await database.execute(query, parameters: parameters);

    if (find.isNotEmpty) {
      for (final row in find) {
        final Map<dynamic, dynamic> rowMap = row.toColumnMap();
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
    print(e);
    return Response.internalServerError(
      body: 'An error occured while trying to find user.',
    );
  }
}

Future<Response> _planningGet(Request request) async {
  final uuid = request.params['uuid'];
  final decode = jsonDecode(await request.readAsString());
  final month = decode['month'];

  if (month >= 1 && month <= 12) {
    final query = Sql.named('''
      SELECT * from public.planning
      WHERE user_id = @user_id AND month = @month
    ''');
    final parameters = {"user_id": uuid, "month": month};

    try {
      final data = await database.execute(query, parameters: parameters);
      if (data.isNotEmpty) {
        final Map<dynamic, dynamic> rowMap = data[0].toColumnMap();
        return Response.ok(jsonEncode(rowMap));
      } else {
        return Response.internalServerError(body: "Data cannot be found.");
      }
    } catch (e) {
      print(e);
      return Response.internalServerError(body: "Data cannot be found. $e");
    }
  } else {
    return Response.badRequest(
      body: "Request does not contain all data required.",
    );
  }
}

// TODO: PATCH Request for updating table in database for all tables
Future<Response> _userPatch(Request request) async {
  // Update email and/or profile image
  final uuid = request.params['uuid'];
  final decode = jsonDecode(await request.readAsString());
  final newImg = decode['new_img'];
  final newEmail = decode['new_email'];

  // query database for information
  final query = Sql.named(
    'SELECT * from public.users WHERE user_id = @user_id',
  );
  final parameters = {'user_id': uuid};

  try {
    final find = await database.execute(query, parameters: parameters);
    if (find.isNotEmpty) {
      for (final row in find) {
        final Map<dynamic, dynamic> rowMap = row.toColumnMap();
        final parameters = {};
        if (newEmail != null) {
          // update email in database
          parameters.addAll({'email': newEmail});
        } else {
          // don't update and keep original parameter
          parameters.addAll({'email': rowMap['email']});
        }

        if (newImg != null) {
          // update image in database
          parameters.addAll({'img_url': newImg});
        } else {
          // dont update and keep original parameter
          parameters.addAll({'img_url': rowMap['img_url']});
        }

        final query = (Sql.named('''
          UPDATE public.users
          SET email = @email, img_url = @img_url
          WHERE user_id = @user_id
        '''));
        parameters.addAll({'user_id': uuid});

        try {
          await database.execute(query, parameters: parameters);
          print("User has been modified: $uuid");
          return Response.ok("User has been modified. $uuid");
        } catch (e) {
          print('Error in modifying user:\n $e');
          return Response.badRequest(body: "User has failed to be edited.");
        }
      }
    } else {
      return Response.notFound("User was not found in database.");
    }
  } catch (e) {
    print(e);
    return Response.internalServerError(
      body: 'An error occured while trying to find user.',
    );
  }
  return Response.internalServerError(body: "Error has occured at PATCH /user");
}

Future<Response> _planningPatch(Request request) async {
  final uuid = request.params['uuid'];
  final decode = jsonDecode(await request.readAsString());
  final month = decode['month'];
  final Map<String, dynamic> incomingData = decode['data'];
  final type = decode['type'];
  final bool delete = decode['delete'];

  // add data in database 'data' with incoming data | guard should be in frontend request for malformed data
  var query = Sql.named('''
    SELECT * FROM public.planning
    WHERE user_id = @user_id AND month = @month
  ''');

  var parameters = {"user_id": uuid, "month": month};

  // bills, shopping, food_drink, entertainment, travel, personal
  if (type == "bills" ||
      type == "shopping" ||
      type == "food_drink" ||
      type == "entertainment" ||
      type == "travel" ||
      type == "personal") {
    try {
      final currentData = await database.execute(query, parameters: parameters);
      if (currentData.isNotEmpty) {
        late String result;
        final Map<dynamic, dynamic> rowMap = currentData[0].toColumnMap();
        Map<String, dynamic> dataMap = rowMap['data'];
        if (!delete) {
          // add data
          if (dataMap[type] == null) {
            dataMap[type] = incomingData;
          } else {
            dataMap[type].add(incomingData); // updates old data
          }

          result = "added";
        } else {
          // delete data instead
          if (dataMap[type] != null) {
            final List newDataList = [];
            for (final row in dataMap[type]) {
              if (!(row['label'] == incomingData['label'] &&
                  row['value'] == incomingData['value'] &&
                  row['timestamp'] == incomingData['timestamp'])) {
                newDataList.add(row);
              }
            }
            dataMap[type] = newDataList;
            result = "deleted";
          } else {
            return Response.ok("Data section is empty, no need to delete.");
          }
        }
        // update database
        query = Sql.named('''
          UPDATE public.planning 
          SET data = @data
          WHERE user_id = @user_id AND month = @month
        ''');
        parameters.addAll({"data": dataMap});

        try {
          await database.execute(query, parameters: parameters);
          print("Successfully $result data");
          return Response.ok("Successfully $result data!");
        } catch (e) {
          print(e);
          return Response.internalServerError(
            body: "An error has occurred while trying to add data. $e",
          );
        }
      } else {
        return Response.internalServerError(body: "Data cannot be found.");
      }
    } catch (e) {
      print("An error has occurred in PATCH /planning/ $e");
      return Response.internalServerError(
        body: "An error has occured while trying to add data. $e",
      );
    }
  } else {
    return Response.badRequest(
      body:
          "Request does not contain all data required, or has the incorrect type",
    );
  }
}

void main(List<String> args) async {
  database = await Connection.open(
      Endpoint(
        host: '/cloudsql/${Platform.environment['INSTANCE_CONNECTION_NAME']}/.s.PGSQL.5432',
        database: Platform.environment['DB_NAME'] ?? "",
        username: Platform.environment['DB_USER'],
        password: Platform.environment['DB_PASS'],
        port: 5432,
        isUnixSocket: true,
    ),
    // Endpoint(
    //   host: '127.0.0.1',
    //   database: 'postgres',
    //   username: 'postgres',
    //   password: 'admin',
    //   port: 5432,
    // ),
    // settings: ConnectionSettings(sslMode: SslMode.disable),
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
