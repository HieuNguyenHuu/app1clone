import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Rawdata {
  Rawdata(this.value, this.time);

  final double value;
  final int time;
}

class _MyHomePageState extends State<MyHomePage> {
  final Vector3 _accelerometer = Vector3.zero();
  Vector3 _grav = Vector3.zero();
  int _groupValue = 0;
  double _lacc = 1;
  double _laccfilter = 1;
  double _laccfilterd = 1;
  double _gravity = 9.8;
  double alpha = 0.8;
  int y = 0;

  List<String> labelx = [];

  List<Rawdata> listrawdata = [];
  List<Rawdata> listlpfdata = [];

  ChartSeriesController? _chartSeriesController;

  double pitchacc = 0;

  void setUpdateInterval(int groupValue, int interval) {
    motionSensors.accelerometerUpdateInterval = interval;
    motionSensors.userAccelerometerUpdateInterval = interval;
    motionSensors.gyroscopeUpdateInterval = interval;
    motionSensors.magnetometerUpdateInterval = interval;
    motionSensors.orientationUpdateInterval = interval;
    motionSensors.absoluteOrientationUpdateInterval = interval;
    setState(() {
      _groupValue = groupValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Update Interval'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio(
                value: 1,
                groupValue: _groupValue,
                onChanged: (dynamic value) => setUpdateInterval(
                    value, Duration.microsecondsPerSecond ~/ 1),
              ),
              const Text("1 FPS"),
              Radio(
                value: 2,
                groupValue: _groupValue,
                onChanged: (dynamic value) => setUpdateInterval(
                    value, Duration.microsecondsPerSecond ~/ 20),
              ),
              const Text("20 FPS"),
              Radio(
                value: 3,
                groupValue: _groupValue,
                onChanged: (dynamic value) => setUpdateInterval(
                    value, Duration.microsecondsPerSecond ~/ 60),
              ),
              const Text("60 FPS"),
            ],
          ),
          const Text('Accelerometer'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(_accelerometer.x.toStringAsFixed(4)),
              Text(_accelerometer.y.toStringAsFixed(4)),
              Text(_accelerometer.z.toStringAsFixed(4)),
            ],
          ),
          Text(_lacc.toStringAsFixed(4)),
          SfCartesianChart(
            primaryYAxis: NumericAxis(
              minimum: 5,
              maximum: 20,
            ),
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            series: <LineSeries<Rawdata, int>>[
              LineSeries<Rawdata, int>(
                onRendererCreated: (ChartSeriesController controller) {
                  _chartSeriesController = controller;
                },
                dataSource: listlpfdata,
                color: Colors.blue,
                name: "Low pass filter",
                xValueMapper: (Rawdata rawdata, _) => rawdata.time,
                yValueMapper: (Rawdata rawdata, _) => rawdata.value,
              ),
              LineSeries<Rawdata, int>(
                onRendererCreated: (ChartSeriesController controller) {
                  _chartSeriesController = controller;
                },
                name: "Raw",
                dataSource: listrawdata,
                color: Colors.black,
                xValueMapper: (Rawdata rawdata, _) => rawdata.time,
                yValueMapper: (Rawdata rawdata, _) => rawdata.value,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    motionSensors.accelerometer.listen((AccelerometerEvent event) {
      setState(() {
        /*_grav.x = alpha * _grav.x + (1 - alpha) * event.x;
        _grav.y = alpha * _grav.y + (1 - alpha) * event.y;
        _grav.z = alpha * _grav.z + (1 - alpha) * event.z;
        */
        _accelerometer.setValues(event.x, event.y, event.z);
        _lacc = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

        _grav.x = (1 - alpha) * _grav.x + alpha * event.x;
        _grav.y = (1 - alpha) * _grav.y + alpha * event.y;
        _grav.z = (1 - alpha) * _grav.z + alpha * event.z;

        //_laccfilter = sqrt(pow(_grav.x, 2) + pow(_grav.y, 2) + pow(_grav.z, 2));
        //_laccfilter = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

        _laccfilter = (1 - alpha) * _laccfilter +
            alpha * sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

        listrawdata.add(Rawdata(_lacc, y));
        listlpfdata.add(Rawdata(_laccfilter, y));

        if (listrawdata!.length == 100) {
          listrawdata!.removeAt(0);
          listlpfdata!.removeAt(0);
          _chartSeriesController?.updateDataSource(
              addedDataIndexes: <int>[listrawdata!.length - 1],
              removedDataIndexes: <int>[0]);
        } else {
          _chartSeriesController?.updateDataSource(
            addedDataIndexes: <int>[listrawdata!.length - 1],
          );
        }

        //updatedata();
        //features[0].data.add(_lacc);
        //labelx.add((y).toString());
        //features[0].data.add(_lacc);
        /*data = LineChartData(datasets: [
          Dataset(label: "acc", dataPoints: _createDataPoints(_lacc, y))
        ]);*/
        y++;
      });
    });
  }
}
