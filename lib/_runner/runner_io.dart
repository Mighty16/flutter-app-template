import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app.dart';

void run() => runZonedGuarded(() {
      runApp(const App());
    }, (Object error, StackTrace stack) {
      //TODO: Handle Errors
    });
