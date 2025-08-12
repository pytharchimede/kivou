import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/chat.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/chat_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int conversationId;
  const ChatRoomScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  Timer? _poll;
  final _picker = ImagePicker();
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
      // reload messages
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec d\'envoi du message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_sending) return;
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
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
            .showSnackBar(SnackBar(content: Text('Envoi image: $e')));
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
    // Récupère éventuellement les infos de la conversation pour l'AppBar
    final convsAsync = ref.watch(chatConversationsProvider);
    ChatConversation? conv;
    convsAsync.whenData((list) {
      try {
        conv = list.firstWhere((c) => c.id == widget.conversationId);
      } catch (_) {}
    });
    // Tenter de récupérer le numéro du pair via openOrCreate si manquant
    if (_peerPhone == null && conv != null) {
      _ensurePeerPhone(conv!);
    }
    // Démarre un petit polling tant que l'écran est monté
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
            // Avatar composite: prestataire + mini client
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
                    // Côté client: titre = prestataire; côté prestataire: titre = client
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
          tooltip: 'Fermer',
        ),
        actions: [
          if ((_peerPhone ?? '').isNotEmpty)
            IconButton(
              tooltip: 'Appeler',
              onPressed: () {
                final tel = Uri.parse('tel:${_peerPhone!}');
                launchUrl(tel);
              },
              icon: const Icon(Icons.call_rounded),
            ),
          // Le bouton commande n'est visible que côté client
          if ((conv?.providerId?.isNotEmpty ?? false) &&
              (conv?.providerOwnerUserId == null ||
                  conv!.providerOwnerUserId != myId))
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.icon(
                onPressed: () => context.push('/booking/${conv!.providerId}'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text('Commander'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.when(
              data: (list) {
                // Marquer les messages comme lus pour cet utilisateur
                ref
                    .read(chatServiceProvider)
                    .markRead(widget.conversationId)
                    .catchError((_) {});
                return ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[list.length - 1 - i];
                    final mine = m.isMine(myId);
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if ((m.attachmentUrl ?? '')
                                            .isNotEmpty) ...[
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6,
                                              maxHeight: 280,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    _absUrl(m.attachmentUrl!),
                                                fit: BoxFit.cover,
                                                placeholder: (ctx, _) =>
                                                    Container(
                                                  height: 150,
                                                  color: theme.colorScheme
                                                      .surfaceContainerHighest,
                                                  alignment: Alignment.center,
                                                  child: const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (ctx, _, __) =>
                                                    Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  color: theme.colorScheme
                                                      .errorContainer,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          size: 18),
                                                      SizedBox(width: 6),
                                                      Text(
                                                          'Image indisponible'),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (m.lat != null && m.lng != null) ...[
                                          const SizedBox(height: 6),
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
                                        ],
                                        if (m.body.isNotEmpty) ...[
                                          if ((m.attachmentUrl ?? '')
                                                  .isNotEmpty ||
                                              (m.lat != null && m.lng != null))
                                            const SizedBox(height: 6),
                                          Text(
                                            m.body,
                                            style: TextStyle(
                                              color: mine
                                                  ? theme.colorScheme
                                                      .onPrimaryContainer
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        _fmtTime(m.createdAt),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Joindre une image',
                      onPressed: _sending ? null : _pickAndSendImage,
                      icon: const Icon(Icons.image_rounded),
                    ),
                    IconButton(
                      tooltip: 'Partager ma position',
                      onPressed: _sending ? null : _shareLocation,
                      icon: const Icon(Icons.my_location_rounded),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sending ? null : _send(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Votre message…',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: Icon(Icons.send_rounded,
                          color: _sending
                              ? theme.disabledColor
                              : theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ensurePeerPhone(ChatConversation conv) async {
    try {
      final opened = await ref.read(chatServiceProvider).openOrCreate(
          peerUserId: conv.peerUserId, providerId: conv.providerId);
      if (!mounted) return;
      setState(() {
        _peerPhone = opened.peerPhone;
      });
    } catch (_) {
      // silencieux
    }
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
