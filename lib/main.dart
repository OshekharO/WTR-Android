import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/network/dns_service.dart';
import 'src/core/storage/prefs_service.dart';
import 'src/extensions/registry/source_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot order: prefs → DNS → registry.
  await PrefsService.init();
  await DnsService.init();
  SourceRegistry.instance.init();

  runApp(const OtakuStreamApp());
}
