import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/fs_service.dart';
import 'item_detail_page.dart';
import 'publish_item_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FsService _fsService = FsService();

  Widget _construirListado(
    BuildContext context,
    List<QueryDocumentSnapshot> documentos,
    bool misPublicaciones,
  ) {
    final colores = Theme.of(context).colorScheme;
    final user = _authService.currentUser;

    final publicaciones = documentos.where((doc) {
      final data = doc.data();
      if (data is! Map<String, dynamic>) return false;
      if (!misPublicaciones) return true;
      return user != null && data['autorUid'] == user.uid;
    }).toList();

    if (publicaciones.isEmpty) {
      return const Center(child: Text('No existen publicaciones todavia'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: publicaciones.length,
      itemBuilder: (context, index) {
        final doc = publicaciones[index];
        final data = doc.data();
        if (data is! Map<String, dynamic>) {
          return const SizedBox.shrink();
        }

        final objeto = <String, dynamic>{...data, 'id': doc.id};

        final titulo = objeto['titulo']?.toString() ?? 'Sin título';
        final categoria = objeto['categoria']?.toString() ?? 'Sin categoría';
        final lugar = objeto['lugar']?.toString() ?? 'Sin lugar';
        final tipo = objeto['tipo']?.toString() ?? 'Objeto';
        final estado = objeto['estado']?.toString() ?? 'Vigente';
        final devuelto = estado == 'Devuelto';
        final foto = objeto['fotoBlob'];

        return Opacity(
          opacity: devuelto ? 0.6 : 1,
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: devuelto ? colores.surfaceContainerLow : colores.surface,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailPage(objeto: objeto),
                  ),
                );
              },

              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: colores.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: foto is Blob
                          ? Image.memory(foto.bytes, fit: BoxFit.cover)
                          : Icon(
                              Icons.image_outlined,
                              color: colores.onSurfaceVariant,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Categoria: $categoria'),
                          Text('Lugar: $lugar'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              Chip(
                                label: Text(tipo),
                                backgroundColor: colores.primaryContainer,
                                labelStyle: TextStyle(
                                  color: colores.onPrimaryContainer,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                label: Text(estado),
                                backgroundColor: devuelto
                                    ? colores.tertiaryContainer
                                    : colores.secondaryContainer,
                                labelStyle: TextStyle(
                                  color: devuelto
                                      ? colores.onTertiaryContainer
                                      : colores.onSecondaryContainer,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final nombre = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email ?? 'Usuario';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(nombre)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (valor) async {
                if (valor == 'cerrar') {
                  await _authService.signOut();
                }
              },

              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cerrar', child: Text('Cerrar Sesion')),
              ],
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Todos'),
              Tab(text: 'Mis publicaciones'),
            ],
          ),
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: _fsService.getObjetos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('ERROR al cargar publicaciones'));
            }

            final documentos =
                snapshot.data?.docs.cast<QueryDocumentSnapshot>() ?? [];

            return TabBarView(
              children: [
                _construirListado(context, documentos, false),
                _construirListado(context, documentos, true),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublishItemPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        ),
      ),
    );
  }
}
