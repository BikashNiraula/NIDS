import 'package:get/get.dart';
import 'package:nidswebapp/models/log_model.dart';
import 'package:nidswebapp/services/api_service.dart';


class LogController extends GetxController {
  var logs = <LogEntry>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchLogs();
    super.onInit();
  }

  void fetchLogs() async {
    try {
      isLoading(true);
      var result = await ApiService().getLogs();
      logs.assignAll(result);
    } finally {
      isLoading(false);
    }
  }
}
