class ClaimNode < ApplicationNode
  # Claim-specific properties
  property :content, type: String
  property :confidence_score, type: Float
  property :extraction_metadata, type: String, default: "{}"
  property :semantic_embedding, type: String, default: "[]"
  property :version, type: Integer, default: 1

  # Relationships
  has_many :out, :documents, type: :EXTRACTED_FROM, model_class: :DocumentNode
  has_many :out, :entities, type: :MENTIONS, model_class: :EntityNode
  has_many :out, :topics, type: :RELATED_TO, model_class: :TopicNode
  has_many :out, :supported_claims, type: :SUPPORTS, model_class: :ClaimNode
  has_many :in, :supporting_claims, type: :SUPPORTS, model_class: :ClaimNode
  has_many :out, :contradicted_claims, type: :CONTRADICTS, model_class: :ClaimNode
  has_many :in, :contradicting_claims, type: :CONTRADICTS, model_class: :ClaimNode
  has_many :out, :refined_claims, type: :REFINES, model_class: :ClaimNode
  has_many :in, :refining_claims, type: :REFINES, model_class: :ClaimNode
  has_many :out, :questions, type: :ANSWERED_BY, model_class: :QuestionNode
  has_many :in, :evidence, type: :SUPPORTS, model_class: :EvidenceNode

  # Relationship convenience methods
  def extracted_from
    documents
  end

  def mentions_entity
    entities
  end

  def related_to_topic
    topics
  end

  def supports
    supported_claims
  end

  def supported_by
    supporting_claims
  end

  def contradicts
    contradicted_claims
  end

  def contradicted_by
    contradicting_claims
  end

  def refines
    refined_claims
  end

  def refined_by
    refining_claims
  end

  def answers_questions
    questions
  end

  def supported_by_evidence
    evidence
  end

  # Claim analysis methods
  def conflicting_claims
    contradicted_claims + contradicting_claims
  end

  def related_claims
    supported_claims + supporting_claims + refined_claims + refining_claims
  end

  def evidence_strength
    evidence.sum(&:weight) / evidence.count if evidence.any?
  end

  def is_well_supported?
    supporting_claims.count >= 2 && evidence.count >= 1
  end

  def is_controversial?
    contradicting_claims.any?
  end

  # Add entity relationship
  def add_entity(entity_name)
    entity = EntityNode.find_or_create_by(
      name: entity_name,
      organization_id: organization_id
    )
    entities << entity unless entities.include?(entity)
  end

  # Add topic relationship
  def add_topic(topic_name)
    topic = TopicNode.find_or_create_by(
      name: topic_name,
      organization_id: organization_id
    )
    topics << topic unless topics.include?(topic)
  end

  # Class method to find or create by unique attributes
  def self.find_or_create_by(attributes)
    node = find_by(attributes)
    node || create!(attributes.merge(global_id: "#{name.downcase}_#{SecureRandom.hex(16)}"))
  end
end
