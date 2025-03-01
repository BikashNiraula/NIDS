// // // import 'package:flutter/material.dart';
// // // import 'package:nidswebapp/go_api/web_socket.dart';

// // // class TerminalScreen extends StatefulWidget {
// // //   final WebSocketService webSocketService;

// // //   TerminalScreen({required this.webSocketService});

// // //   @override
// // //   _TerminalScreenState createState() => _TerminalScreenState();
// // // }

// // // class _TerminalScreenState extends State<TerminalScreen> {
// // //   final TextEditingController _controller = TextEditingController();

// // //   @override
// // //   void dispose() {
// // //     widget.webSocketService.dispose();
// // //     _controller.dispose();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: Text('Web Terminal')),
// // //       body: Column(
// // //         children: [
// // //           Expanded(
// // //             child: StreamBuilder(
// // //               stream: widget.webSocketService.stream,
// // //               builder: (context, snapshot) {
// // //                 return SingleChildScrollView(
// // //                   scrollDirection: Axis.vertical,
// // //                   child: Text(snapshot.hasData ? snapshot.data.toString() : ""),
// // //                 );
// // //               },
// // //             ),
// // //           ),
// // //           TextField(
// // //             controller: _controller,
// // //             onSubmitted: (command) {
// // //               widget.webSocketService.sendMessage(command);
// // //               _controller.clear();
// // //             },
// // //             decoration: InputDecoration(labelText: "Enter Command"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'package:nidswebapp/go_api/web_socket.dart';

// // class TerminalScreen extends StatefulWidget {
// //   final WebSocketService webSocketService;

// //   TerminalScreen({required this.webSocketService});

// //   @override
// //   _TerminalScreenState createState() => _TerminalScreenState();
// // }

// // class _TerminalScreenState extends State<TerminalScreen> {
// //   final TextEditingController _controller = TextEditingController();
// //   final ScrollController _scrollController = ScrollController();
// //   final List<String> _commandHistory = [];
// //   int _historyIndex = -1;

// //   @override
// //   void dispose() {
// //     widget.webSocketService.dispose();
// //     _controller.dispose();
// //     _scrollController.dispose();
// //     super.dispose();
// //   }

// //   void _scrollToBottom() {
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       _scrollController.animateTo(
// //         _scrollController.position.maxScrollExtent,
// //         duration: Duration(milliseconds: 300),
// //         curve: Curves.easeOut,
// //       );
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black, // Dark theme
// //       appBar: AppBar(
// //         title: Text('NIDS Terminal'),
// //         backgroundColor: Colors.grey[900],
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: StreamBuilder(
// //               stream: widget.webSocketService.stream,
// //               builder: (context, snapshot) {
// //                 if (snapshot.hasData) {
// //                   _scrollToBottom(); // Auto-scroll to bottom
// //                 }
// //                 return SingleChildScrollView(
// //                   controller: _scrollController,
// //                   scrollDirection: Axis.vertical,
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(8.0),
// //                     child: Text(
// //                       snapshot.hasData ? snapshot.data.toString() : "",
// //                       style: TextStyle(
// //                         fontFamily: 'Courier', // Monospace font
// //                         fontSize: 14,
// //                         color: Colors.white, // White text
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //           Container(
// //             padding: EdgeInsets.all(8),
// //             color: Colors.grey[900],
// //             child: Row(
// //               children: [
// //                 Text(
// //                   '\$', // Command prompt
// //                   style: TextStyle(
// //                     fontFamily: 'Courier',
// //                     fontSize: 14,
// //                     color: Colors.green, // Green prompt
// //                   ),
// //                 ),
// //                 SizedBox(width: 8),
// //                 Expanded(
// //                   child: TextField(
// //                     controller: _controller,
// //                     style: TextStyle(
// //                       fontFamily: 'Courier',
// //                       fontSize: 14,
// //                       color: Colors.white, // White text
// //                     ),
// //                     decoration: InputDecoration(
// //                       border: InputBorder.none,
// //                       hintText: "Enter command",
// //                       hintStyle: TextStyle(color: Colors.grey),
// //                     ),
// //                     onSubmitted: (command) {
// //                       if (command.isNotEmpty) {
// //                         widget.webSocketService.sendMessage(command);
// //                         _commandHistory.add(command); // Add to history
// //                         _historyIndex = _commandHistory.length;
// //                         _controller.clear();
// //                       }
// //                     },
// //                     onChanged: (value) {
// //                       setState(() {
// //                         // Handle command history with up/down arrows
// //                         if (value.isEmpty && _commandHistory.isNotEmpty) {
// //                           _controller.value = _controller.value.copyWith(
// //                             text: _commandHistory[_historyIndex],
// //                             selection: TextSelection.collapsed(
// //                               offset: _commandHistory[_historyIndex].length,
// //                             ),
// //                           );
// //                         }
// //                       });
// //                     },
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:nidswebapp/go_api/web_socket.dart';

// class TerminalScreen extends StatefulWidget {
//   final WebSocketService webSocketService;

//   TerminalScreen({required this.webSocketService});

//   @override
//   _TerminalScreenState createState() => _TerminalScreenState();
// }

// class _TerminalScreenState extends State<TerminalScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<String> _commandHistory = [];
//   final List<String> _outputHistory = [];
//   int _historyIndex = -1;
//   bool _showCursor = true;

//   @override
//   void initState() {
//     super.initState();
//     // Start blinking cursor animation
//     _startCursorAnimation();
//   }

//   @override
//   void dispose() {
//     widget.webSocketService.dispose();
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _startCursorAnimation() {
//     Future.delayed(Duration(milliseconds: 500), () {
//       if (mounted) {
//         setState(() {
//           _showCursor = !_showCursor;
//         });
//         _startCursorAnimation();
//       }
//     });
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   void _handleCommand(String command) {
//     if (command.isNotEmpty) {
//       // Add command to history
//       _commandHistory.add(command);
//       _outputHistory.add('\$ $command'); // Display command in output
//       _historyIndex = _commandHistory.length;

//       // Send command to WebSocket server
//       widget.webSocketService.sendMessage(command);

//       // Clear input field
//       _controller.clear();
//     }
//   }

//   void _navigateHistory(int direction) {
//     if (_commandHistory.isEmpty) return;

//     setState(() {
//       _historyIndex =
//           (_historyIndex + direction).clamp(0, _commandHistory.length - 1);
//       _controller.value = _controller.value.copyWith(
//         text: _commandHistory[_historyIndex],
//         selection: TextSelection.collapsed(
//           offset: _commandHistory[_historyIndex].length,
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black, // Dark theme
//       appBar: AppBar(
//         title: Text('NIDS Terminal'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder(
//               stream: widget.webSocketService.stream,
//               builder: (context, snapshot) {
//                 if (snapshot.hasData) {
//                   // Add output to history
//                   _outputHistory.add(snapshot.data.toString());
//                   _scrollToBottom(); // Auto-scroll to bottom
//                 }
//                 return SingleChildScrollView(
//                   controller: _scrollController,
//                   scrollDirection: Axis.vertical,
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: _outputHistory.map((line) {
//                         return Text(
//                           line,
//                           style: TextStyle(
//                             fontFamily: 'Courier', // Monospace font
//                             fontSize: 14,
//                             color: line.startsWith('\$')
//                                 ? Colors.green
//                                 : Colors
//                                     .white, // Green for commands, white for output
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.all(8),
//             color: Colors.grey[900],
//             child: Row(
//               children: [
//                 Text(
//                   '\$', // Command prompt
//                   style: TextStyle(
//                     fontFamily: 'Courier',
//                     fontSize: 14,
//                     color: Colors.green, // Green prompt
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     style: TextStyle(
//                       fontFamily: 'Courier',
//                       fontSize: 14,
//                       color: Colors.white, // White text
//                     ),
//                     decoration: InputDecoration(
//                       border: InputBorder.none,
//                       hintText: "Enter command",
//                       hintStyle: TextStyle(color: Colors.grey),
//                       suffix: _showCursor
//                           ? Container(
//                               width: 8,
//                               height: 16,
//                               color: Colors.white, // Blinking cursor
//                             )
//                           : SizedBox.shrink(),
//                     ),
//                     onSubmitted: _handleCommand,
//                     onChanged: (value) {
//                       setState(() {
//                         // Handle command history with up/down arrows
//                         if (value.isEmpty && _commandHistory.isNotEmpty) {
//                           _controller.value = _controller.value.copyWith(
//                             text: _commandHistory[_historyIndex],
//                             selection: TextSelection.collapsed(
//                               offset: _commandHistory[_historyIndex].length,
//                             ),
//                           );
//                         }
//                       });
//                     },
//                     onTap: () {
//                       setState(() {
//                         _showCursor = true; // Show cursor when typing
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:nidswebapp/go_api/web_socket.dart';

class TerminalScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  TerminalScreen({required this.webSocketService});

  @override
  _TerminalScreenState createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _commandHistory = [];
  final List<String> _outputHistory = [];
  int _historyIndex = -1;
  // bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    // _startCursorAnimation();

    // Listen to WebSocket messages and update UI
    widget.webSocketService.stream.listen((message) {
      setState(() {
        _outputHistory.add(message);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    widget.webSocketService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _handleCommand(String command) {
    if (command.isNotEmpty) {
      setState(() {
        _commandHistory.add(command);
        _outputHistory.add('\$ $command'); // Display the command in output
        _historyIndex = _commandHistory.length;
      });

      widget.webSocketService.sendMessage(command);
      _controller.clear();
    }
  }

  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;

    setState(() {
      _historyIndex =
          (_historyIndex + direction).clamp(0, _commandHistory.length - 1);
      _controller.value = _controller.value.copyWith(
        text: _commandHistory[_historyIndex],
        selection: TextSelection.collapsed(
            offset: _commandHistory[_historyIndex].length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('NIDS Terminal',
            style: TextStyle(fontFamily: 'Courier', fontSize: 16)),
        // backgroundColor: Colors.grey[900],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _outputHistory.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        color:
                            line.startsWith('\$') ? Colors.green : Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.grey[900],
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '\$',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    cursorColor: Colors.white, // Set blinker color to white
                    cursorWidth: 2.5, // Make the blinker a bit wider
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter command...",
                      hintStyle: TextStyle(color: Colors.grey),
                      // suffix: _showCursor
                      //     ? Container(width: 4, height: 16, color: Colors.white)
                      //     : SizedBox.shrink(),
                    ),
                    onSubmitted: _handleCommand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
