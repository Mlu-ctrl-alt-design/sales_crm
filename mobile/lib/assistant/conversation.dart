import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'assistant_api.dart';

sealed class ChatEntry {
  const ChatEntry();
}

class UserEntry extends ChatEntry {
  const UserEntry(this.text);
  final String text;
}

class AssistantEntry extends ChatEntry {
  const AssistantEntry(this.text);
  final String text;
}

/// A turn that failed; [retry] is the message to send again.
class ErrorEntry extends ChatEntry {
  const ErrorEntry(this.text, {this.retry});
  final String text;
  final String? retry;
}

enum ActionState { waiting, running, done, cancelled, failed }

/// A proposed write and what became of it.
class ActionEntry extends ChatEntry {
  ActionEntry(this.action);

  final PendingAction action;
  ActionState state = ActionState.waiting;

  /// What the tool returned once confirmed.
  Map<String, dynamic>? result;

  /// The assistant turn in the history that proposed it.
  int? turn;
  String? error;
}

/// The chat on the Assistant tab. Lives with the app shell, so it survives
/// switching tabs; it's gone when the app closes.
///
/// The server keeps no conversation: [history] is sent with every message,
/// as plain text turns, with what happened to each proposed action noted
/// on the assistant's turn so the model knows.
class Conversation extends ChangeNotifier {
  Conversation(this._api);

  final AssistantApi _api;
  final _entries = <ChatEntry>[];
  final _history = <Map<String, Object?>>[];
  bool _thinking = false;

  List<ChatEntry> get entries => List.unmodifiable(_entries);
  bool get thinking => _thinking;
  bool get isEmpty => _entries.isEmpty;

  /// The turns sent to the server, oldest first.
  @visibleForTesting
  List<Map<String, Object?>> get history => List.unmodifiable(_history);

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _thinking) return;
    _entries.removeWhere((e) => e is ErrorEntry);
    _entries.add(UserEntry(message));
    _thinking = true;
    notifyListeners();

    try {
      final reply = await _api.chat(message, List.of(_history));
      switch (reply.status) {
        case ReplyStatus.answered:
        case ReplyStatus.confirmRequired:
          final said = reply.reply.isNotEmpty
              ? reply.reply
              : 'Please confirm the action below.';
          _entries.add(AssistantEntry(said));
          _history
            ..add({'role': 'user', 'content': message})
            ..add({'role': 'assistant', 'content': said});
          if (reply.action case final action?) {
            _entries.add(ActionEntry(action)..turn = _history.length - 1);
          }
        case ReplyStatus.error:
          _entries.add(
            ErrorEntry(
              reply.code == 'permission_denied'
                  ? "You don't have access to that. ${reply.reply}".trim()
                  : reply.reply.isEmpty
                  ? "The assistant couldn't answer that. Try again."
                  : reply.reply,
              retry: reply.code == 'permission_denied' ? null : message,
            ),
          );
      }
    } on ApiException catch (e) {
      _entries.add(ErrorEntry(e.message, retry: message));
    } catch (_) {
      _entries.add(
        ErrorEntry(
          "The assistant sent back something the app couldn't read.",
          retry: message,
        ),
      );
    } finally {
      _thinking = false;
      notifyListeners();
    }
  }

  /// Sends the failed message again.
  Future<void> retry(ErrorEntry entry) async {
    final message = entry.retry;
    if (message == null) return;
    _entries.remove(entry);
    // The failed message is sent again as a new turn.
    final last = _entries.lastOrNull;
    if (last is UserEntry && last.text == message) _entries.removeLast();
    await send(message);
  }

  Future<void> confirm(ActionEntry entry) async {
    if (entry.state != ActionState.waiting &&
        entry.state != ActionState.failed) {
      return;
    }
    entry
      ..state = ActionState.running
      ..error = null;
    notifyListeners();
    try {
      entry.result = await _api.confirm(entry.action.id);
      entry.state = ActionState.done;
      _note(entry, 'The user confirmed and it was done: ${_outcome(entry)}.');
    } on ApiException catch (e) {
      entry
        ..state = ActionState.failed
        ..error = e.message;
    } catch (_) {
      entry
        ..state = ActionState.failed
        ..error = "Couldn't read the answer. Check Desk before trying again.";
    }
    notifyListeners();
  }

  Future<void> cancel(ActionEntry entry) async {
    if (entry.state != ActionState.waiting &&
        entry.state != ActionState.failed) {
      return;
    }
    entry.state = ActionState.cancelled;
    _note(entry, 'The user cancelled it; nothing was done.');
    notifyListeners();
    try {
      await _api.cancel(entry.action.id);
    } on ApiException {
      // It expires on its own; nothing ran either way.
    }
  }

  void clear() {
    _entries.clear();
    _history.clear();
    notifyListeners();
  }

  static String _outcome(ActionEntry entry) {
    final result = entry.result ?? const {};
    final name = result['name'];
    if (entry.action.isSubmit && name is String) {
      return '${result['doctype'] ?? 'document'} $name submitted';
    }
    if (entry.action.isEmail) {
      final to = result['recipients'];
      return 'emailed${to is List ? ' to ${to.join(', ')}' : ''}';
    }
    return 'done';
  }

  /// Adds what happened to the assistant turn that proposed [entry].
  void _note(ActionEntry entry, String note) {
    final i = entry.turn;
    if (i == null || i >= _history.length) return;
    _history[i] = {
      'role': 'assistant',
      'content': '${_history[i]['content']}\n\n[$note]',
    };
  }
}
