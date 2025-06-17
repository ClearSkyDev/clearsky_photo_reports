class AiSummaryReview {
  final String status; // draft, approved, rejected, edited
  final String content;
  final String? editor;
  final DateTime? editedAt;

  AiSummaryReview({
    this.status = 'draft',
    this.content = '',
    this.editor,
    this.editedAt,
  });

  AiSummaryReview copyWith({
    String? status,
    String? content,
    String? editor,
    DateTime? editedAt,
  }) {
    return AiSummaryReview(
      status: status ?? this.status,
      content: content ?? this.content,
      editor: editor ?? this.editor,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'content': content,
      if (editor != null) 'editor': editor,
      if (editedAt != null) 'editedAt': editedAt!.millisecondsSinceEpoch,
    };
  }

  factory AiSummaryReview.fromMap(Map<String, dynamic> map) {
    return AiSummaryReview(
      status: map['status'] as String? ?? 'draft',
      content: map['content'] as String? ?? '',
      editor: map['editor'] as String?,
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
    );
  }
}
