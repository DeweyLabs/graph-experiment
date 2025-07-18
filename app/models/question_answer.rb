class QuestionAnswer < ApplicationRecord
  # Constants
  SOURCE_TYPES = %w[document query chat].freeze

  # Associations
  belongs_to :organization
  belongs_to :document, optional: true

  # Validations
  validates :question, presence: true, uniqueness: {scope: :organization_id}
  validates :answer, presence: true
  validates :confidence_score, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1}, allow_nil: true
  validates :pinecone_id, uniqueness: true, allow_nil: true
  validates :source_type, inclusion: {in: SOURCE_TYPES}

  # Defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :high_confidence, -> { where("confidence_score >= ?", 0.8) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_confidence, -> { order(confidence_score: :desc) }
  scope :from_documents, -> { where(source_type: "document") }
  scope :from_queries, -> { where(source_type: "query") }
  scope :from_chat, -> { where(source_type: "chat") }
  scope :without_document, -> { where(document_id: nil) }

  # Methods
  def generate_pinecone_id
    "qa_#{organization_id}_#{SecureRandom.hex(8)}"
  end

  def prepare_for_pinecone(embedding_vector)
    {
      id: pinecone_id || generate_pinecone_id,
      values: embedding_vector,
      metadata: {
        organization_id: organization_id,
        document_id: document_id,
        question: question.truncate(500),
        answer: answer.truncate(1000),
        confidence_score: confidence_score,
        type: "question_answer"
      }.merge(metadata || {})
    }
  end

  def update_from_search_results(search_results)
    contexts = search_results.map { |r| r["metadata"]["content"] }.join("\n\n")
    confidence = search_results.first&.dig("score") || 0

    update!(
      context: contexts,
      confidence_score: confidence,
      metadata: (metadata || {}).merge(
        "source_chunks" => search_results.map { |r| r["id"] },
        "search_scores" => search_results.map { |r| r["score"] }
      )
    )
  end

  private

  def set_defaults
    self.metadata ||= {}
    self.confidence_score ||= 0.0
    if source_type.blank?
      self.source_type = document.present? ? "document" : "query"
    end
  end

  # Graph-related methods
  public

  def graph_node
    @graph_node ||= QuestionNode.from_active_record(self)
  end

  def create_or_update_graph_node
    node = QuestionNode.find_by(global_id: to_global_id.to_s)

    if node
      # Update existing node
      node.update!(
        content: question,
        answer: answer,
        answer_confidence: confidence_score,
        answer_updated_at: DateTime.current,
        updated_at: DateTime.current
      )
    else
      # Create new node
      node = QuestionNode.create!(
        global_id: to_global_id.to_s,
        organization_id: organization_id,
        content: question,
        answer: answer,
        answer_confidence: confidence_score,
        answer_updated_at: DateTime.current
      )
    end

    node
  end

  def graph_node
    @graph_node ||= QuestionNode.find_by(global_id: to_global_id.to_s)
  end

  def sync_entities_to_graph(entity_names)
    node = graph_node || create_or_update_graph_node
    node.extract_entities(entity_names)
  end

  def sync_topics_to_graph(topic_names)
    node = graph_node || create_or_update_graph_node
    node.extract_topics(topic_names)
  end

  def find_relevant_documents_via_graph
    return [] unless graph_node

    # Get documents through graph traversal
    document_nodes = graph_node.relevant_documents

    # Convert back to ActiveRecord models
    document_nodes.map do |node|
      Document.find_by(id: node.global_id.split("/").last)
    end.compact
  end

  def should_update_for_document?(document)
    return false unless graph_node && document.graph_node
    graph_node.needs_update?(document.graph_node)
  end

  def link_to_document_in_graph(document)
    return unless graph_node && document.graph_node
    graph_node.uses_document << document.graph_node unless graph_node.uses_document.include?(document.graph_node)
  end
end
