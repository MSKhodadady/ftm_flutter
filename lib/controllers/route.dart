import 'package:get/get.dart';

enum RoutePages { explorePage, addPage, selectFilePage }

class RouteController extends GetxController {
  RoutePages route = RoutePages.explorePage;

  static RouteController get to => Get.find();

  void setRoute(RoutePages newRoute) {
    route = newRoute;

    update();
  }
}
