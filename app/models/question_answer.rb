class QuestionAnswer < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :document

  # Validations
  validates :question, presence: true, uniqueness: {scope: :organization_id}
  validates :answer, presence: true
  validates :confidence_score, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1}, allow_nil: true
  validates :pinecone_id, uniqueness: true, allow_nil: true

  # Defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :high_confidence, -> { where("confidence_score >= ?", 0.8) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_confidence, -> { order(confidence_score: :desc) }

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
  end
end
