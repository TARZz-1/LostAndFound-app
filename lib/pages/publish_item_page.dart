import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/fs_service.dart';

class PublishItemPage extends StatefulWidget {
  const PublishItemPage({super.key});

  @override
  State<PublishItemPage> createState() => _PublishItemPageState();
}

class _PublishItemPageState extends State<PublishItemPage> {
  final formKey = GlobalKey<FormState>();

  final tituloCtrl = TextEditingController();
  final lugarCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  String tipoSeleccionado = 'Perdido';
  String? categoriaSeleccionada;
  Uint8List? imagenBytes;
  bool guardando = false;

  late Stream<QuerySnapshot<Object?>> categoriasStream;

  @override
  void initState() {
    super.initState();
    categoriasStream = FsService().getCategorias().asStream();
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    lugarCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> seleccionarImagen(ImageSource fuente) async {
    if (guardando) return;

    try {
      final foto = await ImagePicker().pickImage(
        source: fuente,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (foto == null) return;

      final bytes = await foto.readAsBytes();

      if (!mounted) return;

      setState(() {
        imagenBytes = bytes;
      });
    } catch (error) {
      debugPrint('Error al seleccionar imagen: $error');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible seleccionar la fotografía'),
        ),
      );
    }
  }

  Future<void> publicar() async {
    if (guardando) return;

    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
      );
      return;
    }

    if (imagenBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una fotografía')),
      );
      return;
    }

    if (imagenBytes!.lengthInBytes >= 950000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fotografía supera el tamaño permitido'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para publicar')),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await FsService().agregarObjetos(
        titulo: tituloCtrl.text.trim(),
        descripcion: descripcionCtrl.text.trim(),
        tipo: tipoSeleccionado,
        categoria: categoriaSeleccionada!,
        lugar: lugarCtrl.text.trim(),
        fecha: Timestamp.now().toDate(),
        fotoBytes: imagenBytes!,
        autorUid: user.uid,
        autorNombre: user.displayName ?? user.email ?? 'Usuario',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación creada correctamente')),
      );

      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error al crear la publicacion: $error');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible crear la publicación')),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar objeto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colores.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagenBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 70,
                            color: colores.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Selecciona una fotografía',
                            style: TextStyle(color: colores.onSurfaceVariant),
                          ),
                        ],
                      )
                    : Image.memory(imagenBytes!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: guardando
                          ? null
                          : () => seleccionarImagen(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: guardando
                          ? null
                          : () => seleccionarImagen(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Perdido', child: Text('Perdido')),
                  DropdownMenuItem(
                    value: 'Encontrado',
                    child: Text('Encontrado'),
                  ),
                ],
                onChanged: guardando
                    ? null
                    : (valor) {
                        setState(() {
                          tipoSeleccionado = valor ?? 'Perdido';
                        });
                      },
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Object?>>(
                stream: categoriasStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Text('No fue posible cargar las categorías');
                  }

                  final documentos = snapshot.data?.docs ?? [];
                  final categorias = <String>[];

                  for (final documento in documentos) {
                    final datos = documento.data();

                    if (datos is Map<String, dynamic>) {
                      final nombre = datos['nombre']?.toString().trim();

                      if (nombre != null && nombre.isNotEmpty) {
                        categorias.add(nombre);
                      }
                    }
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categorias.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Selecciona una categoría';
                      }

                      return null;
                    },
                    onChanged: guardando
                        ? null
                        : (valor) {
                            setState(() {
                              categoriaSeleccionada = valor;
                            });
                          },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tituloCtrl,
                enabled: !guardando,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej. Llaves, celular, mochila',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => _validarTexto(v, minLength: 3),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lugarCtrl,
                enabled: !guardando,
                decoration: const InputDecoration(
                  labelText: 'Lugar',
                  hintText: 'Ej. Biblioteca, Patio central',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => _validarTexto(v, minLength: 3),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descripcionCtrl,
                enabled: !guardando,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe las características del objeto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => _validarTexto(v, minLength: 5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: guardando ? null : publicar,
                  icon: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: Text(guardando ? 'Publicando...' : 'Publicar'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String? _validarTexto(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo no puede quedar vacio';
    }
    final texto = value.trim();
    if (texto.length < minLength) {
      return 'Debe Ingresar al menos $minLength caracteres';
    }
    final formatoValido = RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s.,\-]+$');
    if (!formatoValido.hasMatch(texto)) {
      return 'No se permiten caracteres especiales (@, #, !, etc.)';
    }
    if (!RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]').hasMatch(texto)) {
      return 'Debe incluir por lo menos una letra';
    }
    return null;
  }
}
