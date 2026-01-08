import 'package:ecommerce_desktop/models/table_model.dart' as table_model;
import 'package:ecommerce_desktop/providers/base_provider.dart';

class TableProvider extends BaseProvider<table_model.Table> {
  TableProvider() : super("tables");

  @override
  table_model.Table fromJson(dynamic json) {
    return table_model.Table.fromJson(json);
  }
}

