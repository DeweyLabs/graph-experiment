class DocumentChunk < ApplicationRecord
  # Associations
  belongs_to :document
  belongs_to :organization

  # Validations
  validates :content, presence: true
  validates :chunk_index, presence: true, uniqueness: {scope: :document_id}
  validates :pinecone_id, uniqueness: true, allow_nil: true

  # Defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :with_embeddings, -> { where.not(embedding: nil) }
  scope :without_embeddings, -> { where(embedding: nil) }
  scope :by_index, -> { order(:chunk_index) }

  # Methods
  def has_embedding?
    embedding.present?
  end

  def embedding_vector
    return nil unless has_embedding?
    begin
      JSON.parse(embedding)
    rescue
      nil
    end
  end

  def embedding_vector=(vector)
    self.embedding = vector.to_json if vector.is_a?(Array)
  end

  def generate_pinecone_id
    "#{organization_id}_#{document_id}_#{chunk_index}"
  end

  def prepare_for_pinecone
    {
      id: pinecone_id || generate_pinecone_id,
      values: embedding_vector,
      metadata: {
        organization_id: organization_id,
        document_id: document_id,
        document_title: document.title,
        source_id: document.source_id,
        chunk_index: chunk_index,
        content: content.truncate(1000) # Pinecone metadata limit
      }.merge(metadata || {})
    }
  end

  private

  def set_defaults
    self.metadata ||= {}
    self.pinecone_id ||= generate_pinecone_id if document_id.present?
  end
end
