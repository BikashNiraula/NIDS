// // // // // // import 'dart:convert';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:flutter_code_editor/flutter_code_editor.dart';
// // // // // // import 'package:highlight/languages/json.dart'; // Import JSON language mode

// // // // // // class NIDSRuleEditor extends StatefulWidget {
// // // // // //   @override
// // // // // //   _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
// // // // // // }

// // // // // // class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
// // // // // //   final CodeController _controller = CodeController(
// // // // // //     text: jsonEncode({
// // // // // //       "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
// // // // // //     }),
// // // // // //     language: json, // Use the JSON language mode
// // // // // //   );

// // // // // //   final List<String> _savedVersions = [];
// // // // // //   int _version = 1;

// // // // // //   void _saveRule() {
// // // // // //     final ruleText = _controller.text;
// // // // // //     try {
// // // // // //       // Validate JSON
// // // // // //       final parsedJson = jsonDecode(ruleText);
// // // // // //       final prettyJson = JsonEncoder.withIndent('  ').convert(parsedJson);

// // // // // //       setState(() {
// // // // // //         _savedVersions.add('{"version": $_version, "rule": $prettyJson}');
// // // // // //         _version++;
// // // // // //       });
// // // // // //     } catch (e) {
// // // // // //       // Show error message if JSON is invalid
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(title: const Text('NIDS Rule Editor')),
// // // // // //       body: Row(
// // // // // //         children: [
// // // // // //           Expanded(
// // // // // //             child: Padding(
// // // // // //               padding: const EdgeInsets.all(8.0),
// // // // // //               child: Column(
// // // // // //                 children: [
// // // // // //                   Expanded(
// // // // // //                     child: CodeTheme(
// // // // // //                       data: CodeThemeData(styles: {
// // // // // //                         'root': TextStyle(color: Colors.white),
// // // // // //                         'string': TextStyle(color: Colors.green),
// // // // // //                         'keyword': TextStyle(
// // // // // //                             color: Colors.blue, fontWeight: FontWeight.bold),
// // // // // //                         'literal': TextStyle(color: Colors.orange),
// // // // // //                         'comment': TextStyle(color: Colors.grey),
// // // // // //                         'punctuation': TextStyle(color: Colors.red),
// // // // // //                       }),
// // // // // //                       child: CodeField(controller: _controller),
// // // // // //                     ),
// // // // // //                   ),
// // // // // //                   ElevatedButton(
// // // // // //                     onPressed: _saveRule,
// // // // // //                     child: const Text('Save Rule'),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //           Expanded(
// // // // // //             child: Padding(
// // // // // //               padding: const EdgeInsets.all(8.0),
// // // // // //               child: ListView.builder(
// // // // // //                 itemCount: _savedVersions.length,
// // // // // //                 itemBuilder: (context, index) {
// // // // // //                   return Card(
// // // // // //                     child: Padding(
// // // // // //                       padding: const EdgeInsets.all(8.0),
// // // // // //                       child: Text(_savedVersions[index]),
// // // // // //                     ),
// // // // // //                   );
// // // // // //                 },
// // // // // //               ),
// // // // // //             ),
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'dart:convert';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_code_editor/flutter_code_editor.dart';
// // // // // import 'package:highlight/languages/json.dart';

// // // // // class NIDSRuleEditor extends StatefulWidget {
// // // // //   @override
// // // // //   _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
// // // // // }

// // // // // class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
// // // // //   final CodeController _controller = CodeController(
// // // // //     text: jsonEncode({
// // // // //       "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
// // // // //     }),
// // // // //     language: json,
// // // // //   );

// // // // //   final List<String> _savedVersions = [];
// // // // //   int _version = 1;

// // // // //   // Predefined boilerplate rule
// // // // //   final String boilerplateRule =
// // // // //       'alert tcp any any -> any any (msg:"Possible Threat Detected"; sid:1001;)';

// // // // //   void _onTextChanged(String text) {
// // // // //     if (text.trim().toLowerCase().contains('boiler')) {
// // // // //       String updatedText = text.replaceAll('boiler', '"$boilerplateRule"');

// // // // //       setState(() {
// // // // //         _controller.value = _controller.value.copyWith(text: updatedText);
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _saveRule() {
// // // // //     final ruleText = _controller.text;
// // // // //     try {
// // // // //       final parsedJson = jsonDecode(ruleText);
// // // // //       final prettyJson = JsonEncoder.withIndent('  ').convert(parsedJson);

// // // // //       setState(() {
// // // // //         _savedVersions.add('{"version": $_version, "rule": $prettyJson}');
// // // // //         _version++;
// // // // //       });
// // // // //     } catch (e) {
// // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // //         SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
// // // // //       );
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       appBar: AppBar(title: const Text('NIDS Rule Editor')),
// // // // //       body: Row(
// // // // //         children: [
// // // // //           Expanded(
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(8.0),
// // // // //               child: Column(
// // // // //                 children: [
// // // // //                   Expanded(
// // // // //                     child: CodeTheme(
// // // // //                       data: CodeThemeData(styles: {
// // // // //                         'root': TextStyle(color: Colors.white),
// // // // //                         'string': TextStyle(color: Colors.green),
// // // // //                         'keyword': TextStyle(
// // // // //                             color: Colors.blue, fontWeight: FontWeight.bold),
// // // // //                         'literal': TextStyle(color: Colors.orange),
// // // // //                         'comment': TextStyle(color: Colors.grey),
// // // // //                         'punctuation': TextStyle(color: Colors.red),
// // // // //                       }),
// // // // //                       child: CodeField(
// // // // //                         controller: _controller,
// // // // //                         onChanged: _onTextChanged,
// // // // //                       ),
// // // // //                     ),
// // // // //                   ),
// // // // //                   ElevatedButton(
// // // // //                     onPressed: _saveRule,
// // // // //                     child: const Text('Save Rule'),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           Expanded(
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(8.0),
// // // // //               child: ListView.builder(
// // // // //                 itemCount: _savedVersions.length,
// // // // //                 itemBuilder: (context, index) {
// // // // //                   return Card(
// // // // //                     child: Padding(
// // // // //                       padding: const EdgeInsets.all(8.0),
// // // // //                       child: Text(_savedVersions[index]),
// // // // //                     ),
// // // // //                   );
// // // // //                 },
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // // import 'dart:convert';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_code_editor/flutter_code_editor.dart';
// // // // import 'package:highlight/languages/json.dart';

// // // // class NIDSRuleEditor extends StatefulWidget {
// // // //   @override
// // // //   _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
// // // // }

// // // // class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
// // // //   final CodeController _controller = CodeController(
// // // //     text: jsonEncode({
// // // //       "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
// // // //     }, toEncodable: (object) => object),
// // // //     language: json,
// // // //   );
// // // //   final List<String> _savedVersions = [];
// // // //   int _version = 1;
// // // //   bool _isReplacing = false;

// // // //   final String boilerplateRule =
// // // //       r'alert tcp any any -> any any (msg:"Possible Threat Detected"; sid:1001;)';

// // // //   void _onTextChanged(String text) {
// // // //     if (_isReplacing) return;

// // // //     if (text.endsWith('\n')) {
// // // //       final lines = text.split('\n');
// // // //       final lastLine = lines[lines.length - 2].trim();

// // // //       if (lastLine == 'boiler') {
// // // //         final escapedRule = boilerplateRule.replaceAll('"', r'\"');
// // // //         lines[lines.length - 2] = '  "rule": "$escapedRule",';
// // // //         final newText = lines.join('\n');

// // // //         setState(() {
// // // //           _isReplacing = true;
// // // //           _controller.text = newText;
// // // //           _isReplacing = false;
// // // //         });
// // // //       }
// // // //     }
// // // //   }

// // // //   void _saveRule() {
// // // //     try {
// // // //       final parsed = jsonDecode(_controller.text);
// // // //       final formatted = JsonEncoder.withIndent('  ').convert(parsed);
// // // //       setState(() {
// // // //         _savedVersions.add('Version $_version:\n$formatted');
// // // //         _version++;
// // // //       });
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text('NIDS Rule Editor'),
// // // //         backgroundColor: Colors.grey[900],
// // // //       ),
// // // //       body: Container(
// // // //         color: Colors.grey[850],
// // // //         child: Row(
// // // //           children: [
// // // //             Expanded(
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.all(16.0),
// // // //                 child: Column(
// // // //                   children: [
// // // //                     Expanded(
// // // //                       child: Container(
// // // //                         decoration: BoxDecoration(
// // // //                           border: Border.all(color: Colors.grey[700]!),
// // // //                           borderRadius: BorderRadius.circular(8),
// // // //                         ),
// // // //                         child: CodeTheme(
// // // //                           data: CodeThemeData(styles: {
// // // //                             'root': TextStyle(
// // // //                               color: Colors.white,
// // // //                               backgroundColor: Colors.grey[900],
// // // //                             ),
// // // //                             'string': TextStyle(color: Colors.greenAccent),
// // // //                             'keyword': TextStyle(
// // // //                               color: Colors.blueAccent,
// // // //                               fontWeight: FontWeight.bold,
// // // //                             ),
// // // //                             'literal': TextStyle(color: Colors.orangeAccent),
// // // //                             'comment': TextStyle(color: Colors.grey),
// // // //                             'punctuation': TextStyle(color: Colors.white),
// // // //                             'class': TextStyle(color: Colors.purpleAccent),
// // // //                             'number': TextStyle(color: Colors.orangeAccent),
// // // //                           }),
// // // //                           child: CodeField(
// // // //                             controller: _controller,
// // // //                             onChanged: _onTextChanged,
// // // //                             textStyle: TextStyle(fontFamily: 'FiraCode'),
// // // //                             gutterStyle: GutterStyle(
// // // //                               textStyle: TextStyle(color: Colors.grey),
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                     const SizedBox(height: 16),
// // // //                     ElevatedButton.icon(
// // // //                       icon: Icon(Icons.save),
// // // //                       label: Text('Save Rule'),
// // // //                       style: ElevatedButton.styleFrom(
// // // //                         backgroundColor: Colors.blueGrey[800],
// // // //                         foregroundColor: Colors.white,
// // // //                         padding:
// // // //                             EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // // //                       ),
// // // //                       onPressed: _saveRule,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             VerticalDivider(color: Colors.grey[700], width: 1),
// // // //             Expanded(
// // // //               child: Padding(
// // // //                 padding: const EdgeInsets.all(16.0),
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     Padding(
// // // //                       padding: const EdgeInsets.only(bottom: 8.0),
// // // //                       child: Text(
// // // //                         'Saved Versions:',
// // // //                         style: TextStyle(
// // // //                           color: Colors.white,
// // // //                           fontSize: 16,
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                     Expanded(
// // // //                       child: ListView.builder(
// // // //                         itemCount: _savedVersions.length,
// // // //                         itemBuilder: (context, index) {
// // // //                           return Card(
// // // //                             color: Colors.grey[900],
// // // //                             child: Padding(
// // // //                               padding: const EdgeInsets.all(12.0),
// // // //                               child: CodeTheme(
// // // //                                 data: CodeThemeData(styles: {
// // // //                                   'root': TextStyle(color: Colors.white),
// // // //                                   'string':
// // // //                                       TextStyle(color: Colors.greenAccent),
// // // //                                   'number':
// // // //                                       TextStyle(color: Colors.orangeAccent),
// // // //                                   'keyword':
// // // //                                       TextStyle(color: Colors.blueAccent),
// // // //                                   'punctuation': TextStyle(color: Colors.white),
// // // //                                 }),
// // // //                                 child: CodeField(
// // // //                                   controller: CodeController(
// // // //                                     text: _savedVersions[index],
// // // //                                     language: json,
// // // //                                   ),
// // // //                                   readOnly: true,
// // // //                                   textStyle: TextStyle(fontFamily: 'FiraCode'),
// // // //                                 ),
// // // //                               ),
// // // //                             ),
// // // //                           );
// // // //                         },
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_code_editor/flutter_code_editor.dart';
// // // import 'package:highlight/languages/json.dart';

// // // class NIDSRuleEditor extends StatefulWidget {
// // //   @override
// // //   _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
// // // }

// // // class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
// // //   final CodeController _controller = CodeController(
// // //     text: jsonEncode({
// // //       "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
// // //     }, toEncodable: (object) => object),
// // //     language: json,
// // //   );

// // //   final List<String> _savedVersions = [];
// // //   int _version = 1;
// // //   bool _isReplacing = false;

// // //   final String boilerplateRule =
// // //       'alert tcp any any -> any any (msg:"Possible Threat Detected"; sid:1001;)';

// // //   void _onTextChanged(String text) {
// // //     if (_isReplacing) return; // Prevent infinite loop

// // //     try {
// // //       final parsedJson = jsonDecode(text);

// // //       if (parsedJson is Map<String, dynamic> &&
// // //           parsedJson.containsKey("rule") &&
// // //           parsedJson["rule"].toString().trim() == "boiler") {
// // //         parsedJson["rule"] = boilerplateRule;

// // //         final updatedText = JsonEncoder.withIndent('  ').convert(parsedJson);

// // //         setState(() {
// // //           _isReplacing = true;
// // //           _controller.value = _controller.value.copyWith(
// // //             text: updatedText,
// // //             selection: TextSelection.collapsed(offset: updatedText.length),
// // //           );
// // //           _isReplacing = false;
// // //         });
// // //       }
// // //     } catch (e) {
// // //       print("JSON Parse Error: $e");
// // //     }
// // //   }

// // //   void _saveRule() {
// // //     try {
// // //       final parsed = jsonDecode(_controller.text);
// // //       final formatted = JsonEncoder.withIndent('  ').convert(parsed);

// // //       setState(() {
// // //         _savedVersions.add('Version $_version:\n$formatted');
// // //         _version++;
// // //       });
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
// // //       );
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('NIDS Rule Editor'),
// // //         backgroundColor: Colors.grey[900],
// // //       ),
// // //       body: Container(
// // //         color: Colors.grey[850],
// // //         child: Row(
// // //           children: [
// // //             Expanded(
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(16.0),
// // //                 child: Column(
// // //                   children: [
// // //                     Expanded(
// // //                       child: Container(
// // //                         decoration: BoxDecoration(
// // //                           border: Border.all(color: Colors.grey[700]!),
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                         child: CodeTheme(
// // //                           data: CodeThemeData(styles: {
// // //                             'root': TextStyle(
// // //                               color: Colors.white,
// // //                               backgroundColor: Colors.grey[900],
// // //                             ),
// // //                             'string': TextStyle(color: Colors.greenAccent),
// // //                             'keyword': TextStyle(
// // //                               color: Colors.blueAccent,
// // //                               fontWeight: FontWeight.bold,
// // //                             ),
// // //                             'literal': TextStyle(color: Colors.orangeAccent),
// // //                             'comment': TextStyle(color: Colors.grey),
// // //                             'punctuation': TextStyle(color: Colors.white),
// // //                             'class': TextStyle(color: Colors.purpleAccent),
// // //                             'number': TextStyle(color: Colors.orangeAccent),
// // //                           }),
// // //                           child: CodeField(
// // //                             controller: _controller,
// // //                             onChanged: _onTextChanged,
// // //                             textStyle: TextStyle(fontFamily: 'FiraCode'),
// // //                             gutterStyle: GutterStyle(
// // //                               textStyle: TextStyle(color: Colors.grey),
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 16),
// // //                     ElevatedButton.icon(
// // //                       icon: Icon(Icons.save),
// // //                       label: Text('Save Rule'),
// // //                       style: ElevatedButton.styleFrom(
// // //                         backgroundColor: Colors.blueGrey[800],
// // //                         foregroundColor: Colors.white,
// // //                         padding:
// // //                             EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// // //                       ),
// // //                       onPressed: _saveRule,
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //             VerticalDivider(color: Colors.grey[700], width: 1),
// // //             Expanded(
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(16.0),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Padding(
// // //                       padding: const EdgeInsets.only(bottom: 8.0),
// // //                       child: Text(
// // //                         'Saved Versions:',
// // //                         style: TextStyle(
// // //                           color: Colors.white,
// // //                           fontSize: 16,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     Expanded(
// // //                       child: ListView.builder(
// // //                         itemCount: _savedVersions.length,
// // //                         itemBuilder: (context, index) {
// // //                           return Card(
// // //                             color: Colors.grey[900],
// // //                             child: Padding(
// // //                               padding: const EdgeInsets.all(12.0),
// // //                               child: CodeTheme(
// // //                                 data: CodeThemeData(styles: {
// // //                                   'root': TextStyle(color: Colors.white),
// // //                                   'string':
// // //                                       TextStyle(color: Colors.greenAccent),
// // //                                   'number':
// // //                                       TextStyle(color: Colors.orangeAccent),
// // //                                   'keyword':
// // //                                       TextStyle(color: Colors.blueAccent),
// // //                                   'punctuation': TextStyle(color: Colors.white),
// // //                                 }),
// // //                                 child: CodeField(
// // //                                   controller: CodeController(
// // //                                     text: _savedVersions[index],
// // //                                     language: json,
// // //                                   ),
// // //                                   readOnly: true,
// // //                                   textStyle: TextStyle(fontFamily: 'FiraCode'),
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           );
// // //                         },
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_code_editor/flutter_code_editor.dart';
// // import 'package:highlight/languages/json.dart';

// // class NIDSRuleEditor extends StatefulWidget {
// //   @override
// //   _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
// // }

// // class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
// //   final CodeController _controller = CodeController(
// //     text: jsonEncode({
// //       "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
// //     }, toEncodable: (object) => object),
// //     language: json,
// //   );
// //   final List<String> _savedVersions = [];
// //   int _version = 1;

// //   final String boilerplateRule =
// //       r'alert tcp any any -> any any (msg:"Possible Threat Detected"; sid:1001;)';

// //   void _onTextChanged(String text) {
// //     if (text.endsWith('\n')) {
// //       final lines = text.split('\n');
// //       final lastLine = lines[lines.length - 2].trim();

// //       if (lastLine == 'boiler') {
// //         final updatedText = text.replaceAll(
// //           'boiler\n',
// //           '"$boilerplateRule"\n',
// //         );

// //         setState(() {
// //           _controller.text = updatedText;
// //         });
// //       }
// //     }
// //   }

// //   void _saveRule() {
// //     try {
// //       final parsed = jsonDecode(_controller.text);
// //       final formatted = JsonEncoder.withIndent('  ').convert(parsed);
// //       setState(() {
// //         _savedVersions.add('Version $_version:\n$formatted');
// //         _version++;
// //       });
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('NIDS Rule Editor'),
// //         backgroundColor: Colors.grey[900],
// //         elevation: 0,
// //       ),
// //       body: Container(
// //         color: Colors.grey[850],
// //         child: Row(
// //           children: [
// //             Expanded(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   children: [
// //                     Expanded(
// //                       child: Container(
// //                         decoration: BoxDecoration(
// //                           border: Border.all(color: Colors.grey[700]!),
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                         child: CodeTheme(
// //                           data: CodeThemeData(styles: {
// //                             'root': TextStyle(
// //                               color: Colors.white,
// //                               backgroundColor: Colors.grey[900],
// //                             ),
// //                             'string': TextStyle(color: Colors.greenAccent),
// //                             'keyword': TextStyle(
// //                               color: Colors.blueAccent,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                             'literal': TextStyle(color: Colors.orangeAccent),
// //                             'comment': TextStyle(color: Colors.grey),
// //                             'punctuation': TextStyle(color: Colors.white),
// //                             'class': TextStyle(color: Colors.purpleAccent),
// //                             'number': TextStyle(color: Colors.orangeAccent),
// //                           }),
// //                           child: CodeField(
// //                             controller: _controller,
// //                             onChanged: _onTextChanged,
// //                             textStyle: TextStyle(fontFamily: 'FiraCode'),
// //                             gutterStyle: GutterStyle(
// //                               textStyle: TextStyle(color: Colors.grey),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     ElevatedButton.icon(
// //                       icon: Icon(Icons.save),
// //                       label: Text('Save Rule'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.blueGrey[800],
// //                         foregroundColor: Colors.white,
// //                         padding:
// //                             EdgeInsets.symmetric(horizontal: 24, vertical: 12),
// //                       ),
// //                       onPressed: _saveRule,
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             VerticalDivider(color: Colors.grey[700], width: 1),
// //             Expanded(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Padding(
// //                       padding: const EdgeInsets.only(bottom: 8.0),
// //                       child: Text(
// //                         'Saved Versions:',
// //                         style: TextStyle(
// //                           color: Colors.white,
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                     Expanded(
// //                       child: ListView.builder(
// //                         itemCount: _savedVersions.length,
// //                         itemBuilder: (context, index) {
// //                           return Card(
// //                             color: Colors.grey[900],
// //                             child: Padding(
// //                               padding: const EdgeInsets.all(12.0),
// //                               child: CodeTheme(
// //                                 data: CodeThemeData(styles: {
// //                                   'root': TextStyle(color: Colors.white),
// //                                   'string':
// //                                       TextStyle(color: Colors.greenAccent),
// //                                   'number':
// //                                       TextStyle(color: Colors.orangeAccent),
// //                                   'keyword':
// //                                       TextStyle(color: Colors.blueAccent),
// //                                   'punctuation': TextStyle(color: Colors.white),
// //                                 }),
// //                                 child: CodeField(
// //                                   controller: CodeController(
// //                                     text: _savedVersions[index],
// //                                     language: json,
// //                                   ),
// //                                   readOnly: true,
// //                                   textStyle: TextStyle(fontFamily: 'FiraCode'),
// //                                 ),
// //                               ),
// //                             ),
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_code_editor/flutter_code_editor.dart';
// import 'package:highlight/languages/json.dart';

// class NIDSRuleEditor extends StatefulWidget {
//   @override
//   _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
// }

// class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
//   final CodeController _controller = CodeController(
//     text: jsonEncode({
//       "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
//     }), // Removed unnecessary toEncodable parameter
//     language: json,
//   );
//   final List<String> _savedVersions = [];
//   int _version = 1;

//   final String boilerplateRule =
//       r'alert tcp any any -> any any (msg:"Possible Threat Detected"; sid:1001;)';

//   void _onTextChanged(String text) {
//     if (text.contains('boiler')) {
//       // Changed from endsWith to contains
//       // Create a new JSON object with the boilerplate rule
//       final newJson = jsonEncode({"rule": boilerplateRule});

//       setState(() {
//         _controller.text = newJson;
//         // Set cursor to end of text
//         _controller.selection = TextSelection.fromPosition(
//           TextPosition(offset: _controller.text.length),
//         );
//       });
//     }
//   }

//   void _saveRule() {
//     try {
//       final parsed = jsonDecode(_controller.text);
//       final formatted = JsonEncoder.withIndent('  ').convert(parsed);
//       setState(() {
//         _savedVersions.add('Version $_version:\n$formatted');
//         _version++;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Rest of the build method remains the same
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('NIDS Rule Editor'),
//         backgroundColor: Colors.grey[900],
//         elevation: 0,
//       ),
//       body: Container(
//         color: Colors.grey[850],
//         child: Row(
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey[700]!),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: CodeTheme(
//                           data: CodeThemeData(styles: {
//                             'root': TextStyle(
//                               color: Colors.white,
//                               backgroundColor: Colors.grey[900],
//                             ),
//                             'string': TextStyle(color: Colors.greenAccent),
//                             'keyword': TextStyle(
//                               color: Colors.blueAccent,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             'literal': TextStyle(color: Colors.orangeAccent),
//                             'comment': TextStyle(color: Colors.grey),
//                             'punctuation': TextStyle(color: Colors.white),
//                             'class': TextStyle(color: Colors.purpleAccent),
//                             'number': TextStyle(color: Colors.orangeAccent),
//                           }),
//                           child: CodeField(
//                             controller: _controller,
//                             onChanged: _onTextChanged,
//                             textStyle: TextStyle(fontFamily: 'FiraCode'),
//                             gutterStyle: GutterStyle(
//                               textStyle: TextStyle(color: Colors.grey),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       icon: Icon(Icons.save),
//                       label: Text('Save Rule'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueGrey[800],
//                         foregroundColor: Colors.white,
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       ),
//                       onPressed: _saveRule,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             VerticalDivider(color: Colors.grey[700], width: 1),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 8.0),
//                       child: Text(
//                         'Saved Versions:',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: _savedVersions.length,
//                         itemBuilder: (context, index) {
//                           return Card(
//                             color: Colors.grey[900],
//                             child: Padding(
//                               padding: const EdgeInsets.all(12.0),
//                               child: CodeTheme(
//                                 data: CodeThemeData(styles: {
//                                   'root': TextStyle(color: Colors.white),
//                                   'string':
//                                       TextStyle(color: Colors.greenAccent),
//                                   'number':
//                                       TextStyle(color: Colors.orangeAccent),
//                                   'keyword':
//                                       TextStyle(color: Colors.blueAccent),
//                                   'punctuation': TextStyle(color: Colors.white),
//                                 }),
//                                 child: CodeField(
//                                   controller: CodeController(
//                                     text: _savedVersions[index],
//                                     language: json,
//                                   ),
//                                   readOnly: true,
//                                   textStyle: TextStyle(fontFamily: 'FiraCode'),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';

class NIDSRuleEditor extends StatefulWidget {
  @override
  _NIDSRuleEditorState createState() => _NIDSRuleEditorState();
}

class _NIDSRuleEditorState extends State<NIDSRuleEditor> {
  final CodeController _controller = CodeController(
    text: jsonEncode({
      "rule": "alert tcp any any -> any any (msg:\"Possible attack detected\");"
    }),
    language: json,
  );
  final List<String> _savedVersions = [];
  int _version = 1;

  final String boilerplateRule =
      r'alert tcp any any -> any any (msg:"Possible Threat Detected"; sid:1001;)';

  void _onTextChanged(String text) {
    if (text.endsWith('\n')) {
      // Check for Enter key press
      final lines = text.split('\n');
      if (lines.length >= 2) {
        // Ensure we have at least 2 lines
        final lastLine =
            lines[lines.length - 2].trim(); // Get the line before the new line

        if (lastLine == 'boiler') {
          // Create a new JSON object with the boilerplate rule
          final newJson = jsonEncode({"rule": boilerplateRule});

          setState(() {
            _controller.text = newJson;
            // Set cursor to end of text
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        }
      }
    }
  }

  void _saveRule() {
    try {
      final parsed = jsonDecode(_controller.text);
      final formatted = JsonEncoder.withIndent('  ').convert(parsed);
      setState(() {
        _savedVersions.add('Version $_version:\n$formatted');
        _version++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NIDS Rule Editor'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[850],
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CodeTheme(
                          data: CodeThemeData(styles: {
                            'root': TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.grey[900],
                            ),
                            'string': TextStyle(color: Colors.greenAccent),
                            'keyword': TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            'literal': TextStyle(color: Colors.orangeAccent),
                            'comment': TextStyle(color: Colors.grey),
                            'punctuation': TextStyle(color: Colors.white),
                            'class': TextStyle(color: Colors.purpleAccent),
                            'number': TextStyle(color: Colors.orangeAccent),
                          }),
                          child: CodeField(
                            controller: _controller,
                            onChanged: _onTextChanged,
                            textStyle: TextStyle(fontFamily: 'FiraCode'),
                            gutterStyle: GutterStyle(
                              textStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Save Rule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _saveRule,
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(color: Colors.grey[700], width: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Saved Versions:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _savedVersions.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CodeTheme(
                                data: CodeThemeData(styles: {
                                  'root': TextStyle(color: Colors.white),
                                  'string':
                                      TextStyle(color: Colors.greenAccent),
                                  'number':
                                      TextStyle(color: Colors.orangeAccent),
                                  'keyword':
                                      TextStyle(color: Colors.blueAccent),
                                  'punctuation': TextStyle(color: Colors.white),
                                }),
                                child: CodeField(
                                  controller: CodeController(
                                    text: _savedVersions[index],
                                    language: json,
                                  ),
                                  readOnly: true,
                                  textStyle: TextStyle(fontFamily: 'FiraCode'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
