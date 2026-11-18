import 'package:intl/intl.dart';

String formatearFecha(DateTime fecha) {
  return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
}
