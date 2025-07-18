class Document < ApplicationRecord
  # Associations
  belongs_to :source
  belongs_to :organization
  has_many :document_chunks, dependent: :destroy
  has_many :question_answers, dependent: :destroy

  # Validations
  validates :external_id, presence: true, uniqueness: {scope: :source_id}
  validates :title, presence: true
  validates :content, presence: true
  validates :embedding_status, inclusion: {in: %w[pending processing completed failed]}

  # Defaults
  after_initialize :set_defaults, if: :new_record?

  # Callbacks
  before_save :update_chunk_count

  # Scopes
  scope :pending_embedding, -> { where(embedding_status: "pending") }
  scope :processed, -> { where(embedding_status: "completed") }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def ready_for_chunking?
    content.present? && embedding_status == "pending"
  end

  def mark_processing!
    update!(embedding_status: "processing")
  end

  def mark_completed!
    update!(
      embedding_status: "completed",
      processed_at: Time.current
    )
  end

  def mark_failed!(error_message = nil)
    update_columns(
      embedding_status: "failed",
      metadata: (metadata || {}).merge("error" => error_message)
    )
  end

  private

  def set_defaults
    self.embedding_status ||= "pending"
    self.metadata ||= {}
    self.chunk_count ||= 0
  end

  def update_chunk_count
    self.chunk_count = document_chunks.count if embedding_status == "completed"
  end

  # Graph-related methods
  public

  def graph_node
    @graph_node ||= DocumentNode.from_active_record(self)
  end

  def create_or_update_graph_node
    node = DocumentNode.find_by(global_id: to_global_id.to_s)

    if node
      # Update existing node
      node.update!(
        name: title,
        source_id: source_id.to_s,
        content_hash: Digest::SHA256.hexdigest(content),
        metadata: metadata,
        updated_at: DateTime.current
      )
    else
      # Create new node
      node = DocumentNode.create!(
        global_id: to_global_id.to_s,
        organization_id: organization_id,
        name: title,
        source_id: source_id.to_s,
        content_hash: Digest::SHA256.hexdigest(content),
        metadata: metadata
      )
    end

    node
  end

  def graph_node
    @graph_node ||= DocumentNode.find_by(global_id: to_global_id.to_s)
  end

  def sync_entities_to_graph(entity_names)
    node = graph_node || create_or_update_graph_node
    node.extract_entities(entity_names)
  end

  def sync_topics_to_graph(topic_names)
    node = graph_node || create_or_update_graph_node
    node.extract_topics(topic_names)
  end

  def affected_questions_from_graph
    graph_node&.affected_questions&.map(&:active_record_model)&.compact || []
  end

  def find_related_questions_via_graph
    return [] unless graph_node

    # Get questions through graph traversal
    question_nodes = graph_node.affected_questions

    # Convert back to ActiveRecord models
    question_nodes.map do |node|
      QuestionAnswer.find_by(id: node.global_id.split("/").last)
    end.compact
  end
end
