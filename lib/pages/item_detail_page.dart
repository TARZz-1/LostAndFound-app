import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/fs_service.dart';
import '../utils/format_utils.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({super.key, required this.objeto});

  final Map<String, dynamic> objeto;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final AuthService _authService = AuthService();
  final FsService _fsService = FsService();
  bool _procesando = false;

  Future<void> _marcarDevuelto() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      await _fsService.marcarDevuelto(widget.objeto['id'].toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicacion ha sido cerrada')),
      );
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error al actualizar publicacion: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible actualizar la publicacion'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _confirmarEliminacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Eliminar publicación'),
          content: const Text('¿Seguro que deseas eliminar esta publicación?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || _procesando) return;

    setState(() => _procesando = true);

    try {
      await _fsService.eliminarObjeto(widget.objeto['id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Publicación eliminada')));
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error al eliminar publicacion: $error');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible eliminar la publicación')),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final objeto = widget.objeto;

    final titulo = objeto['titulo']?.toString() ?? 'Sin título';
    final descripcion = objeto['descripcion']?.toString() ?? 'Sin descripción';
    final tipo = objeto['tipo']?.toString() ?? 'Objeto';
    final categoria = objeto['categoria']?.toString() ?? 'Sin categoría';
    final lugar = objeto['lugar']?.toString() ?? 'Sin lugar';
    final estado = objeto['estado']?.toString() ?? 'Vigente';
    final autor = objeto['autorNombre']?.toString() ?? 'Autor desconocido';
    final foto = objeto['fotoBlob'];

    String fechaTexto = 'Sin fecha';
    if (objeto['fecha'] is Timestamp) {
      final Timestamp timestamp = objeto['fecha'] as Timestamp;
      fechaTexto = formatearFecha(timestamp.toDate());
    }

    final esAutor =
        _authService.currentUser?.uid == objeto['autorUid']?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del objeto')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 260,
              child: foto is Blob
                  ? Image.memory(foto.bytes, fit: BoxFit.cover)
                  : Container(
                      color: colores.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 70,
                        color: colores.onSurfaceVariant,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(
                          tipo == 'Encontrado'
                              ? Icons.check_circle_outline
                              : Icons.search,
                          color: colores.onPrimaryContainer,
                        ),
                        label: Text(tipo),
                        backgroundColor: colores.primaryContainer,
                        labelStyle: TextStyle(
                          color: colores.onPrimaryContainer,
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          estado == 'Devuelto'
                              ? Icons.task_alt
                              : Icons.schedule,
                          color: estado == 'Devuelto'
                              ? colores.onTertiaryContainer
                              : colores.onSecondaryContainer,
                        ),
                        label: Text(estado),
                        backgroundColor: estado == 'Devuelto'
                            ? colores.tertiaryContainer
                            : colores.secondaryContainer,
                        labelStyle: TextStyle(
                          color: estado == 'Devuelto'
                              ? colores.onTertiaryContainer
                              : colores.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _dato(
                    context,
                    Icons.category_outlined,
                    'Categoría',
                    categoria,
                  ),
                  _dato(context, Icons.location_on_outlined, 'Lugar', lugar),
                  _dato(
                    context,
                    Icons.calendar_today_outlined,
                    'Fecha',
                    fechaTexto,
                  ),
                  _dato(context, Icons.person_outline, 'Publicado por', autor),
                  const SizedBox(height: 12),
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (esAutor) ...[
                    const SizedBox(height: 24),
                    if (_procesando)
                      const Center(child: CircularProgressIndicator()),
                    if (!_procesando) ...[
                      if (estado != 'Devuelto')
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _marcarDevuelto,
                            icon: const Icon(Icons.task_alt),
                            label: const Text('Marcar como Devuelto'),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmarEliminacion,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar publicación'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colores.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(
    BuildContext context,
    IconData icono,
    String etiqueta,
    String valor,
  ) {
    final colores = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 21, color: colores.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colores.onSurfaceVariant),
                ),
                Text(valor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
