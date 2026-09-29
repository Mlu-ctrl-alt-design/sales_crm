import '../api/api_client.dart';

enum ReplyStatus { answered, confirmRequired, error }

/// One `chat` turn's answer.
class AssistantReply {
  const AssistantReply({
    required this.status,
    required this.reply,
    this.action,
    this.code,
  });

  final ReplyStatus status;

  /// The assistant's words; for [ReplyStatus.confirmRequired], its summary
  /// of what it wants to do.
  final String reply;

  /// Set when the assistant proposed a write that needs a tap.
  final PendingAction? action;

  /// For errors: "permission_denied", "max_rounds".
  final String? code;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'answered' => ReplyStatus.answered,
      'confirm_required' => ReplyStatus.confirmRequired,
      _ => ReplyStatus.error,
    };
    return AssistantReply(
      status: status,
      reply: (json['reply'] as String?)?.trim() ?? '',
      code: json['code'] as String?,
      action: status == ReplyStatus.confirmRequired
          ? PendingAction.fromJson(json)
          : null,
    );
  }
}

/// A write the assistant proposed; it only runs if the user confirms.
class PendingAction {
  const PendingAction({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.preview,
  });

  final String id;

  /// `submit_document` or `send_document_email`.
  final String toolName;
  final Map<String, dynamic> arguments;

  /// For a submit: the priced document, as `documents.preview` returns it.
  /// For an email: doctype, name, recipients, subject.
  final Map<String, dynamic>? preview;

  bool get isSubmit => toolName == 'submit_document';
  bool get isEmail => toolName == 'send_document_email';

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
    id: json['pending_action_id'] as String,
    toolName: (json['tool_name'] as String?) ?? '',
    arguments: json['arguments'] is Map<String, dynamic>
        ? json['arguments'] as Map<String, dynamic>
        : const {},
    preview: json['preview'] is Map<String, dynamic>
        ? json['preview'] as Map<String, dynamic>
        : null,
  );
}

/// `daystar_mobile.api.assistant`. The key to the model lives on the
/// server; the phone only sends text.
abstract class AssistantApi {
  /// [history] is the earlier turns, as `{role, content}` messages.
  Future<AssistantReply> chat(
    String message,
    List<Map<String, Object?>> history,
  );

  /// Runs a proposed write; returns what the tool returned. Safe to retry.
  Future<Map<String, dynamic>> confirm(String actionId);

  Future<void> cancel(String actionId);
}

class HttpAssistantApi implements AssistantApi {
  HttpAssistantApi(this._client);

  final ApiClient _client;
  static const _base = 'daystar_mobile.api.assistant';

  @override
  Future<AssistantReply> chat(
    String message,
    List<Map<String, Object?>> history,
  ) async {
    final result = await _client.post('$_base.chat', {
      'message': message,
      'history': history,
    });
    if (result is! Map<String, dynamic>) {
      throw ApiException(
        "The assistant sent back something the app couldn't read.",
        ApiErrorKind.server,
      );
    }
    return AssistantReply.fromJson(result);
  }

  @override
  Future<Map<String, dynamic>> confirm(String actionId) async {
    final result = await _client.post('$_base.confirm_action', {
      'pending_action_id': actionId,
    });
    final map = result is Map<String, dynamic> ? result : const {};
    final value = map['result'];
    return value is Map<String, dynamic> ? value : const {};
  }

  @override
  Future<void> cancel(String actionId) async {
    await _client.post('$_base.cancel_action', {'pending_action_id': actionId});
  }
}
