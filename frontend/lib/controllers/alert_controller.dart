import 'package:get/get.dart';
import 'package:nidswebapp/models/alert_model.dart';
import 'package:nidswebapp/services/api_service.dart';


class AlertController extends GetxController {
  var alerts = <Alert>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchAlerts();
    super.onInit();
  }

  void fetchAlerts() async {
    try {
      isLoading(true);
      var result = await ApiService().getAlerts();
      alerts.assignAll(result);
    } finally {
      isLoading(false);
    }
  }
}
