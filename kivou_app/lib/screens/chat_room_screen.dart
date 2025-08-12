import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chat.dart';
import '../providers/app_providers.dart';
import '../services/chat_upload_service.dart';
import 'image_viewer_screen.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int conversationId;
  const ChatRoomScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  bool _sending = false;
  Timer? _poll;
  String? _peerPhone;

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatServiceProvider)
          .send(conversationId: widget.conversationId, body: text);
      _controller.clear();
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec d'envoi du message: $e")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendFromCamera() async {
    if (_sending) return;
    try {
      final img =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img == null) return;
      setState(() => _sending = true);
      final url = await ChatUploadService().uploadAttachment(File(img.path));
      await ref
          .read(chatServiceProvider)
          .send(conversationId: widget.conversationId, attachmentUrl: url);
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Caméra: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendMultiple() async {
    if (_sending) return;
    try {
      final imgs = await _picker.pickMultiImage(imageQuality: 80);
      if (imgs.isEmpty) return;
      setState(() => _sending = true);
      for (final x in imgs) {
        final url = await ChatUploadService().uploadAttachment(File(x.path));
        await ref
            .read(chatServiceProvider)
            .send(conversationId: widget.conversationId, attachmentUrl: url);
      }
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Envoi multiple: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareLocation() async {
    if (_sending) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de localisation désactivé');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }
      setState(() => _sending = true);
      final pos = await Geolocator.getCurrentPosition();
      await ref.read(chatServiceProvider).send(
            conversationId: widget.conversationId,
            lat: pos.latitude,
            lng: pos.longitude,
            body:
                'Ma position: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          );
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Localisation: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _ensurePeerPhone(ChatConversation conv) async {
    try {
      final opened = await ref.read(chatServiceProvider).openOrCreate(
          peerUserId: conv.peerUserId, providerId: conv.providerId);
      if (!mounted) return;
      setState(() => _peerPhone = opened.peerPhone);
    } catch (_) {
      // silencieux
    }
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galerie (plusieurs)'),
                onTap: _sending
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _pickAndSendMultiple();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Caméra'),
                onTap: _sending
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _pickAndSendFromCamera();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.my_location_rounded),
                title: const Text('Ma position'),
                onTap: _sending
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _shareLocation();
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/auth');
      });
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final convsAsync = ref.watch(chatConversationsProvider);
    ChatConversation? conv;
    convsAsync.whenData((list) {
      try {
        conv = list.firstWhere((c) => c.id == widget.conversationId);
      } catch (_) {}
    });

    if (_peerPhone == null && conv != null) {
      _ensurePeerPhone(conv!);
    }

    _poll ??= Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    });

    final msgs = ref.watch(chatMessagesProvider(widget.conversationId));
    final myId = (auth.user?['id'] as int?) ?? -1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        (conv?.providerAvatarUrl.isNotEmpty ?? false)
                            ? NetworkImage(conv!.providerAvatarUrl)
                            : (conv?.peerAvatarUrl.isNotEmpty ?? false)
                                ? NetworkImage(conv!.peerAvatarUrl)
                                : null,
                    child: ((conv?.providerAvatarUrl.isEmpty ?? true) &&
                            (conv?.peerAvatarUrl.isEmpty ?? true))
                        ? const Icon(Icons.storefront_rounded, size: 22)
                        : null,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.surface,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundImage:
                          (conv?.clientAvatarUrl.isNotEmpty ?? false)
                              ? NetworkImage(conv!.clientAvatarUrl)
                              : null,
                      child: (conv?.clientAvatarUrl.isEmpty ?? true)
                          ? const Icon(Icons.person, size: 14)
                          : null,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (conv != null)
                        ? ((conv!.providerOwnerUserId != null &&
                                conv!.providerOwnerUserId == myId)
                            ? (conv!.clientName.isNotEmpty
                                ? conv!.clientName
                                : conv!.peerName)
                            : (conv!.providerName.isNotEmpty
                                ? conv!.providerName
                                : conv!.peerName))
                        : 'Discussion',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (conv != null) ...[
                    Text(
                      (conv!.providerOwnerUserId != null &&
                              conv!.providerOwnerUserId == myId)
                          ? (conv!.clientName.isNotEmpty
                              ? 'Client: ${conv!.clientName}'
                              : '')
                          : (conv!.providerName.isNotEmpty
                              ? 'Prestataire: ${conv!.providerName}'
                              : ''),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (conv != null && (conv!.providerOwnerUserId != myId))
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.icon(
                onPressed: () => context.push('/booking/${conv!.providerId}'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('Commander'),
              ),
            ),
          if (_peerPhone != null)
            IconButton(
              tooltip: 'Appeler',
              onPressed: () => launchUrl(Uri.parse('tel:${_peerPhone!}')),
              icon: const Icon(Icons.call_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.when(
              data: (list) {
                return ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[list.length - 1 - i];
                    final mine = m.isMine(myId);

                    Widget messageContent() {
                      final children = <Widget>[];
                      if ((m.attachmentUrl ?? '').isNotEmpty) {
                        children.add(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                              maxHeight: 280,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ImageViewerScreen(
                                          imageUrl: _absUrl(m.attachmentUrl!)),
                                    ),
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: _absUrl(m.attachmentUrl!),
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, _) => Container(
                                    height: 150,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (ctx, _, __) => Container(
                                    padding: const EdgeInsets.all(12),
                                    color: theme.colorScheme.errorContainer,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.broken_image_outlined,
                                            size: 18),
                                        SizedBox(width: 6),
                                        Text('Image indisponible'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                        children.add(const SizedBox(height: 4));
                        children.add(
                          Text(
                            _fileNameFromUrl(m.attachmentUrl!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      if (m.lat != null && m.lng != null) {
                        children.add(const SizedBox(height: 6));
                        children.add(
                          InkWell(
                            onTap: () {
                              final url = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${m.lat},${m.lng}');
                              launchUrl(url);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.place, size: 16),
                                SizedBox(width: 4),
                                Text('Voir sur la carte'),
                              ],
                            ),
                          ),
                        );
                      }

                      if (m.body.isNotEmpty) {
                        children.add(
                          Container(
                            margin: EdgeInsets.only(
                                top: ((m.attachmentUrl ?? '').isNotEmpty ||
                                        (m.lat != null && m.lng != null))
                                    ? 6
                                    : 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: mine
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m.body,
                              style: TextStyle(
                                color: mine
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: mine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!mine) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: (conv
                                          ?.clientAvatarUrl.isNotEmpty ??
                                      false)
                                  ? NetworkImage(conv!.clientAvatarUrl)
                                  : (conv?.peerAvatarUrl.isNotEmpty ?? false)
                                      ? NetworkImage(conv!.peerAvatarUrl)
                                      : null,
                              child: ((conv?.clientAvatarUrl.isEmpty ?? true) &&
                                      (conv?.peerAvatarUrl.isEmpty ?? true))
                                  ? const Icon(Icons.person, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: messageContent(),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _fmtTime(m.createdAt),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (mine) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        m.readAt != null
                                            ? Icons.done_all_rounded
                                            : Icons.done_rounded,
                                        size: 16,
                                        color: m.readAt != null
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                    ]
                                  ],
                                )
                              ],
                            ),
                          ),
                          if (mine) ...[
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: (auth.user?['avatar_url']
                                          ?.toString()
                                          .isNotEmpty ??
                                      false)
                                  ? NetworkImage(
                                      auth.user!['avatar_url'].toString())
                                  : null,
                              child: (auth.user?['avatar_url']
                                          ?.toString()
                                          .isEmpty ??
                                      true)
                                  ? const Icon(Icons.person, size: 14)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erreur: $e')),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sending ? null : _send(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message…',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.attach_file_rounded,
                    onTap: _sending ? null : _showAttachSheet,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.send_rounded,
                    onTap: _sending ? null : _send,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _absUrl(String url) {
  if (url.startsWith('http')) return url;
  // Base backend par défaut (voir ApiClient.baseUrl)
  final base = 'https://fidest.ci';
  if (!url.startsWith('/')) return '$base/$url';
  return '$base$url';
}

String _fileNameFromUrl(String url) {
  final u = Uri.parse(_absUrl(url));
  final path = u.path;
  final idx = path.lastIndexOf('/');
  return idx >= 0 ? path.substring(idx + 1) : path;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const _ActionButton({required this.icon, this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon,
            size: 22, color: color ?? theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
