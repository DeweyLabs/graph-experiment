class EvidenceNode < ApplicationNode
  # Evidence-specific properties
  property :text_span, type: String
  property :start_position, type: Integer
  property :end_position, type: Integer
  property :context_window, type: String
  property :confidence_score, type: Float
  property :extraction_method, type: String
  property :weight, type: Float, default: 1.0

  # Relationships
  has_many :out, :documents, type: :FROM_DOCUMENT, model_class: :DocumentNode
  has_many :out, :claims, type: :SUPPORTS, model_class: :ClaimNode
  has_many :out, :questions, type: :SUPPORTED_BY, model_class: :QuestionNode

  # Relationship convenience methods
  def from_document
    documents.first
  end

  def supports_claims
    claims
  end

  def supports_questions
    questions
  end

  # Evidence analysis methods
  def strength
    confidence_score * weight
  end

  def is_strong?
    strength >= 0.7
  end

  def is_weak?
    strength < 0.3
  end

  def source_document
    documents.first
  end

  def excerpt_with_context
    return text_span unless context_window

    # If we have context window, show the evidence within it
    if start_position && end_position
      before = context_window[0...start_position] || ""
      evidence = context_window[start_position...end_position] || text_span
      after = context_window[end_position..] || ""

      "#{before}**#{evidence}**#{after}"
    else
      text_span
    end
  end

  # Class method to create evidence from document
  def self.create_from_document(document_node, text_span, start_pos, end_pos, weight = 1.0)
    create!(
      global_id: "#{name.downcase}_#{SecureRandom.hex(16)}",
      organization_id: document_node.organization_id,
      text_span: text_span,
      start_position: start_pos,
      end_position: end_pos,
      weight: weight,
      extraction_method: "manual"
    ).tap do |evidence|
      evidence.documents << document_node
    end
  end

  # Class method to find or create by unique attributes
  def self.find_or_create_by(attributes)
    node = find_by(attributes)
    node || create!(attributes.merge(global_id: "#{name.downcase}_#{SecureRandom.hex(16)}"))
  end
end
