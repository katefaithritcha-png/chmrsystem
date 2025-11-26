import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/responsive/responsive_helper.dart';
import '../core/responsive/responsive_text.dart';
import '../services/audit_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _activeThreadId;
  String? _activeTitle;
  final _msgCtrl = TextEditingController();
  bool _showArchivedThreads = false;
  bool _handledInitialArgs = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _threadsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('threads')
        .where('participants', arrayContains: uid);
    if (!_showArchivedThreads) {
      q = q.where('archived', isEqualTo: false);
    }
    return q.orderBy('updatedAt', descending: true).limit(200).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream(String threadId) {
    return FirebaseFirestore.instance
        .collection('threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  Future<void> _openThreadFromDoc(
      DocumentSnapshot<Map<String, dynamic>> d) async {
    final data = d.data() ?? const <String, dynamic>{};
    final me = FirebaseAuth.instance.currentUser?.uid;
    String? displayTitle;
    try {
      final parts = List<String>.from(
          (data['participants'] as List<dynamic>? ?? []).map((e) => '$e'));
      final otherId = parts.firstWhere(
        (id) => id != me,
        orElse: () => '',
      );
      if (otherId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherId)
            .get();
        final u = userDoc.data() ?? const <String, dynamic>{};
        displayTitle =
            (u['name'] ?? u['email'] ?? data['title'] ?? 'Conversation')
                .toString();
      }
    } catch (_) {
      // fall back to stored title if lookup fails
    }
    displayTitle ??= (data['title'] ?? 'Conversation') as String;
    if (!mounted) return;
    setState(() {
      _activeThreadId = d.id;
      _activeTitle = displayTitle;
    });
  }

  Future<void> _openOrCreateThreadWith(String otherUserId,
      {String? title}) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || otherUserId.isEmpty) return;
    // Try to find an existing thread where both participants are me and otherUserId
    final q = await FirebaseFirestore.instance
        .collection('threads')
        .where('participants', arrayContains: me)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();
    DocumentSnapshot<Map<String, dynamic>>? found;
    for (final d in q.docs) {
      final parts = List<String>.from(
          (d.data()['participants'] as List<dynamic>? ?? [])
              .map((e) => e.toString()));
      if (parts.contains(otherUserId) && parts.length <= 3) {
        // basic DM match (2 or <=3 for future)
        found = d;
        break;
      }
    }
    if (found != null) {
      await _openThreadFromDoc(found);
      return;
    }
    // Create new
    final now = FieldValue.serverTimestamp();
    final doc = FirebaseFirestore.instance.collection('threads').doc();
    final threadTitle =
        (title == null || title.isEmpty) ? 'Conversation' : title;
    await doc.set({
      'title': threadTitle,
      'participants': [me, otherUserId],
      'lastMessage': '',
      'updatedAt': now,
      'archived': false,
    });
    await AuditService.instance.addEvent(
      actorId: me,
      actorRole: 'user',
      action: 'chat.thread.create',
      target: 'threads/${doc.id}',
      details: 'other=$otherUserId, title=$threadTitle',
      level: 'info',
    );
    final snap = await doc.get();
    await _openThreadFromDoc(snap);
  }

  void _showPatientPicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.people_alt_outlined),
                  SizedBox(width: 8),
                  Text('Patients',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'patient')
                    .limit(200)
                    .snapshots(),
                builder: (ctx2, snap) {
                  if (snap.hasError) {
                    return const Center(child: Text('Failed to load patients'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No patients'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final d = docs[i];
                      final m = d.data();
                      final rawName = (m['name'] ?? '').toString();
                      final email = (m['email'] ?? '').toString();
                      final name = rawName.isNotEmpty
                          ? rawName
                          : email.isNotEmpty
                              ? email
                              : 'Patient';
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.person_outline)),
                        title: Text(name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(email,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openOrCreateThreadWith(d.id, title: name);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    final tid = _activeThreadId;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (text.isEmpty || tid == null || uid == null) return;
    _msgCtrl.clear();
    final now = FieldValue.serverTimestamp();
    final threadRef = FirebaseFirestore.instance.collection('threads').doc(tid);
    await threadRef.collection('messages').add({
      'senderId': uid,
      'senderEmail': user?.email,
      'senderName': user?.displayName,
      'text': text,
      'createdAt': now,
    });
    await threadRef.set({
      'lastMessage': text,
      'updatedAt': now,
    }, SetOptions(merge: true));
    await AuditService.instance.addEvent(
      actorId: uid,
      actorRole: 'user',
      action: 'chat.message.send',
      target: 'threads/$tid',
      details: 'len=${text.length}',
      level: 'info',
    );
  }

  void _toggleArchiveThread(DocumentSnapshot<Map<String, dynamic>> d) async {
    final data = d.data() ?? {};
    final archived = (data['archived'] as bool?) ?? false;
    await d.reference.set({'archived': !archived}, SetOptions(merge: true));
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await AuditService.instance.addEvent(
      actorId: uid,
      actorRole: 'user',
      action: !archived ? 'chat.thread.archive' : 'chat.thread.unarchive',
      target: 'threads/${d.id}',
      level: 'info',
    );
  }

  void _showMessageActions(DocumentSnapshot<Map<String, dynamic>> msgDoc) {
    final data = msgDoc.data() ?? {};
    final flagged = (data['flagged'] as bool?) ?? false;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(flagged ? Icons.flag_outlined : Icons.outlined_flag,
                  color: Colors.red),
              title: Text(flagged ? 'Unflag message' : 'Flag message'),
              onTap: () async {
                Navigator.pop(ctx);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                await msgDoc.reference.set({
                  'flagged': !flagged,
                  if (!flagged)
                    'flags': FieldValue.arrayUnion([
                      {'by': uid, 'at': FieldValue.serverTimestamp()}
                    ])
                }, SetOptions(merge: true));
                await AuditService.instance.addEvent(
                  actorId: uid,
                  actorRole: 'user',
                  action:
                      !flagged ? 'chat.message.flag' : 'chat.message.unflag',
                  target: msgDoc.reference.path,
                  level: !flagged ? 'warning' : 'info',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle navigation with arguments: {'userId': ..., 'patientId': ...}
    if (!_handledInitialArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map &&
          (args['userId'] != null || args['patientId'] != null)) {
        final target = (args['userId'] ?? args['patientId']).toString();
        _handledInitialArgs = true;
        // schedule after first frame to avoid setState during build warnings
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openOrCreateThreadWith(target);
        });
      } else {
        _handledInitialArgs = true;
      }
    }
    final isWide = MediaQuery.of(context).size.width > 900;
    final threadList = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _threadsStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Failed to load threads'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No conversations'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showPatientPicker,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Choose patient'),
                )
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();
            final archived = (data['archived'] as bool?) ?? false;
            final last = (data['lastMessage'] ?? '') as String;
            final me = FirebaseAuth.instance.currentUser?.uid;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              future: (() async {
                try {
                  final parts = List<String>.from(
                      (data['participants'] as List<dynamic>? ?? [])
                          .map((e) => '$e'));
                  final otherId = parts.firstWhere(
                    (id) => id != me,
                    orElse: () => '',
                  );
                  if (otherId.isEmpty) return null;
                  return FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherId)
                      .get();
                } catch (_) {
                  return null;
                }
              })(),
              builder: (context, snapUser) {
                String title = (data['title'] ?? 'Conversation').toString();
                if (snapUser.hasData && snapUser.data != null) {
                  final u = snapUser.data!.data() ?? const <String, dynamic>{};
                  final n = (u['name'] ?? '').toString();
                  final e = (u['email'] ?? '').toString();
                  if (n.isNotEmpty) {
                    title = n;
                  } else if (e.isNotEmpty) {
                    title = e;
                  }
                }

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.forum)),
                  title:
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle:
                      Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: archived ? 'Unarchive' : 'Archive',
                    icon: Icon(
                        archived ? Icons.unarchive : Icons.archive_outlined),
                    onPressed: () => _toggleArchiveThread(d),
                  ),
                  onTap: () {
                    _openThreadFromDoc(d);
                  },
                );
              },
            );
          },
        );
      },
    );

    final messagePane = _activeThreadId == null
        ? const Center(child: Text('Select a conversation'))
        : Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messagesStream(_activeThreadId!),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(
                          child: Text('Failed to load messages'));
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages'));
                    }
                    return ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final msgDoc = docs[i];
                        final m = msgDoc.data();
                        final mine = m['senderId'] == uid;
                        final senderName = (m['senderName'] ?? '') as String;
                        final senderEmail = (m['senderEmail'] ?? '') as String;
                        String senderLabel = senderName.isNotEmpty
                            ? senderName
                            : senderEmail.isNotEmpty
                                ? senderEmail
                                : (mine ? 'You' : 'User');
                        return GestureDetector(
                          onLongPress: () => _showMessageActions(msgDoc),
                          child: Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: mine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (m['text'] ?? '') as String,
                                      style: TextStyle(
                                          color: mine
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Type a message...'),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                        onPressed: _sendMessage, icon: const Icon(Icons.send))
                  ],
                ),
              )
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeTitle ?? 'Messages'),
        actions: [
          IconButton(
              onPressed: _showPatientPicker,
              icon: const Icon(Icons.person_add_alt)),
          IconButton(
            tooltip: _showArchivedThreads ? 'Hide archived' : 'Show archived',
            icon:
                Icon(_showArchivedThreads ? Icons.inbox : Icons.inbox_outlined),
            onPressed: () =>
                setState(() => _showArchivedThreads = !_showArchivedThreads),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                Container(
                  width: 360,
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Conversations',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                            ),
                            IconButton(
                                onPressed: _showPatientPicker,
                                icon: const Icon(Icons.person_add_alt)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Patients Online scroller
                      SizedBox(
                        height: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Text('Patients Online',
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                            ),
                            Expanded(
                              child: StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .where('role', isEqualTo: 'patient')
                                    .limit(30)
                                    .snapshots(),
                                builder: (ctx, snap) {
                                  if (!snap.hasData) {
                                    return const SizedBox();
                                  }
                                  final items = snap.data!.docs;
                                  if (items.isEmpty) return const SizedBox();
                                  return ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (_, i) {
                                      final d = items[i];
                                      final m = d.data();
                                      final name =
                                          (m['name'] ?? 'Patient').toString();
                                      final online = (m['online'] as bool?) ??
                                          false; // if presence exists
                                      return InkWell(
                                        onTap: () => _openOrCreateThreadWith(
                                            d.id,
                                            title: name),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Stack(
                                              children: [
                                                const CircleAvatar(
                                                    radius: 18,
                                                    child: Icon(
                                                        Icons.person_outline)),
                                                if (online)
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .scaffoldBackgroundColor,
                                                            width: 1),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(child: threadList),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: messagePane),
              ],
            )
          : Column(
              children: [
                Expanded(
                    child: _activeThreadId == null ? threadList : messagePane),
              ],
            ),
    );
  }
}
