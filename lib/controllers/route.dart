import 'package:get/get.dart';

enum RoutePages { explorePage, addPage, selectFilePage }

class RouteController extends GetxController {
  RoutePages route = RoutePages.explorePage;

  void setRoute(RoutePages newRoute) {
    route = newRoute;

    update();
  }
}
