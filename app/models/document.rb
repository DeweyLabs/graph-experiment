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
end
