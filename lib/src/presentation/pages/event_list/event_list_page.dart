import 'package:flutter/material.dart';
import 'package:flutter_alcore/flutter_alcore.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:mysql_client/mysql_client.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final dateTimeTextFieldController = DateTimeTextFieldController();
  Future<List<Map<String, dynamic>>> getDataList() async {
    try {
      final pool = MySQLConnectionPool(
        host: "127.0.0.1",
        port: 3306,
        userName: "ahmad",
        password: "qwerty123456",
        databaseName: "simple_tools", // optional
        maxConnections: 10,
      );

      // // create connection
      // final conn = await MySQLConnection.createConnection(
      //   host: "127.0.0.1",
      //   port: 3306,
      //   userName: "ahmad",
      //   password: "qwerty123456",
      //   databaseName: "simple_tools", // optional
      // );

      //await conn.connect();

      var results = await pool.execute("SELECT * FROM countdown_event");
      List<Map<String, dynamic>> output = [];
      for (var row in results.rows) {
        output.add(row.assoc());
      }
      //await pool.close();
      await pool.close();
      return output;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> addEvent(String name, String dateTime) async {
    try {
      final pool = MySQLConnectionPool(
        host: "127.0.0.1",
        port: 3306,
        userName: "ahmad",
        password: "qwerty123456",
        databaseName: "simple_tools", // optional
        maxConnections: 10,
      );

      var stmt = await pool.prepare(
        "INSERT INTO countdown_event (name, date) VALUES (?, ?)",
      );
      final result = await stmt.execute([name, dateTime]);
      bool success = false;
      if (result.affectedRows.toInt() > 0) {
        success = true;
      }
      await stmt.deallocate();
      await pool.close();
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> removeEvent(String id) async {
    try {
      final pool = MySQLConnectionPool(
        host: "127.0.0.1",
        port: 3306,
        userName: "ahmad",
        password: "qwerty123456",
        databaseName: "simple_tools", // optional
        maxConnections: 10,
      );

      var stmt = await pool.prepare(
        "DELETE FROM countdown_event WHERE id=?",
      );
      final result = await stmt.execute([id]);
      bool success = false;
      if (result.affectedRows.toInt() > 0) {
        success = true;
      }
      await stmt.deallocate();
      await pool.close();
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateEvent(String id, String name, String date) async {
    try {
      final pool = MySQLConnectionPool(
        host: "127.0.0.1",
        port: 3306,
        userName: "ahmad",
        password: "qwerty123456",
        databaseName: "simple_tools", // optional
        maxConnections: 10,
      );

      final result = await pool.execute(
          "UPDATE countdown_event SET name = :name, date = :date WHERE id = :id",
          {"name": name, "date": date, "id": id});
      bool success = false;
      if (result.affectedRows.toInt() > 0) {
        success = true;
      }
      await pool.close();
      return success;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event List"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getDataList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemBuilder: (context, index) {
                final data = snapshot.data?[index];
                return Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Dismissible(
                      key: Key(index.toString()),
                      background: Container(
                        padding: const EdgeInsets.only(left: 10.0),
                        color: Colors.red,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            Text(
                              "Delete",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.green,
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          var isOkay = await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Delete Confirmation"),
                                  content: const Text("Are you sure?"),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text("Cancel")),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text("OK"))
                                  ],
                                );
                              });
                          if (isOkay) {
                            return Future.value(true);
                          } else {
                            return Future.value(false);
                          }
                        } else {
                          return Future.value(false);
                        }
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await removeEvent(data["id"]);
                          setState(() {});
                        } else if (direction == DismissDirection.endToStart) {}
                      },
                      child: InkWell(
                        onTap: () async {
                          dateTimeTextFieldController
                              .textEditingController?.text = data["date"];
                          await showConfirmationAndProcessingDialog<
                              Map<String, String>, bool>(
                            context,
                            "Edit Event",
                            "",
                            extraBodyBuilder:
                                (context, request, processState, stateSetter) {
                              return Column(
                                children: [
                                  LabeledTextField(
                                    initialValue: data["name"],
                                    label: "Name",
                                    onChanged: (value) {
                                      request?["name"] = value;
                                    },
                                  ),
                                  const SpaceHeight(),
                                  DateTimeTextField(
                                    controller: dateTimeTextFieldController,
                                    todayAsLastDate: false,
                                  )
                                ],
                              );
                            },
                            getRequest: (context) {
                              return {};
                            },
                            actionFunction: (context, request) {
                              return updateEvent(
                                  data["id"],
                                  request!["name"]!,
                                  dateTimeTextFieldController
                                      .getDateTimeResult()!
                                      .toIso8601String());
                            },
                            isSuccessfull: (response) {
                              return response;
                            },
                            getMessage: (response) {
                              return "";
                            },
                            resultCallback:
                                (request, response, message, state) {
                              if (state.isSuccess()) {
                                setState(() {});
                              }
                            },
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text(
                                data!["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: data["date"] != null
                                  ? Text(
                                      convertDateTime(data["date"]),
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    )
                                  : const Text("-"),
                            ),
                            TimerCountdown(
                              endTime: getDateTime(data["date"])!,
                            ),
                            const SpaceHeight(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: snapshot.data?.length,
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error?.toString() ?? ""),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showConfirmationAndProcessingDialog<Map<String, String>, bool>(
            context,
            "Add Event",
            "",
            extraBodyBuilder: (context, request, processState, stateSetter) {
              return Column(
                children: [
                  LabeledTextField(
                    label: "Name",
                    onChanged: (value) {
                      request?["name"] = value;
                    },
                  ),
                  const SpaceHeight(),
                  DateTimeTextField(
                    controller: dateTimeTextFieldController,
                    todayAsLastDate: false,
                  )
                ],
              );
            },
            getRequest: (context) {
              return {};
            },
            actionFunction: (context, request) {
              return addEvent(
                  request!["name"]!,
                  dateTimeTextFieldController
                      .getDateTimeResult()!
                      .toIso8601String());
            },
            isSuccessfull: (response) {
              return response;
            },
            getMessage: (response) {
              return "";
            },
            resultCallback: (request, response, message, state) {
              if (state.isSuccess()) {
                setState(() {});
              }
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
