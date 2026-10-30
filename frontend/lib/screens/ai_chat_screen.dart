import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session_store.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.session, this.api});

  final Session? session;
  final ApiClient? api;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = <Map<String, String>>[];
  late final ApiClient _api = widget.api ?? ApiClient();
  bool _loading = false;

  Session? get _session => widget.session;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _session == null || _loading) return;

    setState(() {
      _messages.add(<String, String>{'role': 'user', 'text': text});
      _loading = true;
    });
    _controller.clear();

    try {
      final data = await _api.postJson('/api/ai/chat', <String, dynamic>{
        'message': text,
      }, token: _session!.token);
      if (!mounted) return;
      setState(() {
        _messages.add(<String, String>{
          'role': 'ai',
          'text': data['reply'] as String? ?? 'No response received.',
        });
      });
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _messages.add(<String, String>{
          'role': 'ai',
          'text': err.isUnauthorized
              ? 'Your session has expired. Please sign in again.'
              : err.message,
        });
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSignInRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock_outline, size: 64, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Sign in to use the assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The assistant sends messages to the Auxilia server, so it needs '
              'an authenticated session. Your tasks stay on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const HomeScreen(ownerId: 'local'),
                ),
              ),
              child: const Text('Continue offline'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxilia AI Assistant'),
        centerTitle: true,
      ),
      body: session == null
          ? _buildSignInRequired(context)
          : Column(
              children: <Widget>[
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.auto_awesome,
                                size: 64,
                                color: Colors.indigo,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Ask me anything',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final message = _messages[index];
                            final isUser = message['role'] == 'user';
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.75,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.indigo
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                      isUser ? 16 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isUser ? 4 : 16,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  message['text'] ?? '',
                                  style: TextStyle(
                                    color: isUser
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: IconButton(
                            tooltip: 'Send message',
                            onPressed: _loading ? null : _send,
                            icon: const Icon(Icons.send, color: Colors.white),
                          ),
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
