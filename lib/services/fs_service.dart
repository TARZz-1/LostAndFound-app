import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class FsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getObjetos() {
    return _firestore
        .collection('objetos')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getCategorias() {
    return _firestore.collection('categorias').orderBy('nombre').get();
  }

  Future<void> agregarObjetos({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String categoria,
    required String lugar,
    required DateTime fecha,
    required Uint8List fotoBytes,
    required String autorUid,
    required String autorNombre,
  }) async {
    await _firestore.collection('objetos').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'categoria': categoria,
      'lugar': lugar,
      'fecha': Timestamp.fromDate(fecha),
      'fotoBlob': Blob(fotoBytes),
      'autorUid': autorUid,
      "autorNombre": autorNombre,
      'estado': 'Vigente',
      'creacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> marcarDevuelto(String id) async {
    await _firestore.collection("objetos").doc(id).update({
      'estado': 'Devuelto',
    });
  }

  Future<void> eliminarObjeto(String id) async {
    await _firestore.collection('objetos').doc(id).delete();
  }
}
