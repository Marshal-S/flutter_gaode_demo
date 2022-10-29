import 'dart:async';
import 'dart:io';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const String amapAndroidKey = "a551cc8a227032924733d16cbb59f683";
const String amapIosKey = "f3d258b85086e98d66100f5a9a396970";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AMapController? _controller;
  //平台key
  static const AMapApiKey amapApiKeys = AMapApiKey(iosKey: amapIosKey, androidKey: amapAndroidKey, );
  //高德地图隐私政策连接，使用前请先确定用于已经同意了隐私政策，https://lbs.amap.com/pages/privacy/
  static const AMapPrivacyStatement amapPrivacyStatement = AMapPrivacyStatement(hasContains: true, hasShow: true, hasAgree: true);

  Map<String, Object>? _locationResult; //用于更新位置的参数
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation(); //listter
  StreamSubscription<Map<String, Object>>? _locationListener;//监听定位

  double lon = 117;
  double lat = 39;

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  initLocation() async{
    //启动一下
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    AMapFlutterLocation.setApiKey(amapAndroidKey, amapIosKey);
    //动态申请权限,前面 Permission_handler 有介绍到
    requestPermission();

    if (Platform.isIOS) {
      //精确定位权限，和上面一样
      requestAccuracyAuthorization();
    }
    ///注册持续定位结果监听
    _locationListener = _locationPlugin.onLocationChanged().listen((Map<String, Object> result) {

    });
  }

  ///设置定位参数
  void setLocationOption() {
    AMapLocationOption locationOption = AMapLocationOption();
    ///是否单次定位，设置了之后会定位一次，比较精确，但是仍受ios端精确权限限制
    locationOption.onceLocation = false;

    ///是否需要返回逆地理信息
    locationOption.needAddress = true;

    ///逆地理信息的语言类型
    locationOption.geoLanguage = GeoLanguage.DEFAULT;

    locationOption.desiredLocationAccuracyAuthorizationMode = AMapLocationAccuracyAuthorizationMode.ReduceAccuracy;

    locationOption.fullAccuracyPurposeKey = "AMapLocationScene";

    ///设置Android端连续定位的定位间隔
    locationOption.locationInterval = 2000;

    ///设置Android端的定位模式<br>
    ///可选值：<br>
    ///<li>[AMapLocationMode.Battery_Saving]</li>
    ///<li>[AMapLocationMode.Device_Sensors]</li>
    ///<li>[AMapLocationMode.Hight_Accuracy]</li>
    locationOption.locationMode = AMapLocationMode.Hight_Accuracy;

    ///设置iOS端的定位最小更新距离<br>
    locationOption.distanceFilter = -1;

    ///设置iOS端期望的定位精度
    /// 可选值：<br>
    /// <li>[DesiredAccuracy.Best] 最高精度</li>
    /// <li>[DesiredAccuracy.BestForNavigation] 适用于导航场景的高精度 </li>
    /// <li>[DesiredAccuracy.NearestTenMeters] 10米 </li>
    /// <li>[DesiredAccuracy.Kilometer] 1000米</li>
    /// <li>[DesiredAccuracy.ThreeKilometers] 3000米</li>
    locationOption.desiredAccuracy = DesiredAccuracy.Best;

    ///设置iOS端是否允许系统暂停定位
    locationOption.pausesLocationUpdatesAutomatically = false;

    ///将定位参数设置给定位插件
    _locationPlugin.setLocationOption(locationOption);
  }

  ///开始定位
  void startLocation() {
    ///开始定位之前设置定位参数
    setLocationOption();
    _locationPlugin.startLocation();
  }

  ///停止持续定位
  void stopLocation() {
    _locationPlugin.stopLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("地图页面"),
      ),
      body: AMapWidget(
        onLocationChanged: (argument) {
          print(argument);
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lon),
        ),
        myLocationStyleOptions: MyLocationStyleOptions(true),
        privacyStatement: amapPrivacyStatement,
        apiKey: amapApiKeys,
        onMapCreated: (AMapController controller) {
          _controller = controller;
        },
      ),
    );
  }

  ///获取iOS native的accuracyAuthorization类型
  void requestAccuracyAuthorization() async {
    AMapAccuracyAuthorization currentAccuracyAuthorization = await _locationPlugin.getSystemAccuracyAuthorization();
    if (currentAccuracyAuthorization == AMapAccuracyAuthorization.AMapAccuracyAuthorizationFullAccuracy) {
      print("精确定位类型");
    } else if (currentAccuracyAuthorization == AMapAccuracyAuthorization.AMapAccuracyAuthorizationReducedAccuracy) {
      print("模糊定位类型");
    } else {
      print("未知定位类型");
    }
  }

  /// 动态申请定位权限
  void requestPermission() async {
    // 申请权限
    bool hasLocationPermission = await requestLocationPermission();
    if (hasLocationPermission) {
      print("定位权限申请通过");
    } else {
      print("定位权限申请不通过");
    }
  }

  /// 申请定位权限
  /// 授予定位权限返回true， 否则返回false
  Future<bool>  requestLocationPermission() async {
    //获取当前的权限
    var status = await Permission.location.status;
    if (status == PermissionStatus.granted) {
      //已经授权
      return true;
    } else {
      //未授权则发起一次申请
      status = await Permission.location.request();
      if (status == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }
}
