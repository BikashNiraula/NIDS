// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class MyApp extends StatelessWidget {
//   final _channel =
//       WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

//   @override
//   Widget build(BuildContext context) {
//     TextEditingController _controller = TextEditingController();

//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text('Web Terminal')),
//         body: Column(
//           children: [
//             Expanded(
//               child: StreamBuilder(
//                 stream: _channel.stream,
//                 builder: (context, snapshot) {
//                   return SingleChildScrollView(
//                     child:
//                         Text(snapshot.hasData ? snapshot.data.toString() : ""),
//                   );
//                 },
//               ),
//             ),
//             TextField(
//               controller: _controller,
//               onSubmitted: (command) {
//                 _channel.sink.add(command);
//                 _controller.clear();
//               },
//               decoration: InputDecoration(labelText: "Enter Command"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
