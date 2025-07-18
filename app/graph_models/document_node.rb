class DocumentNode < ApplicationNode
  # Document-specific properties
  property :name, type: String
  property :source_id, type: String
  property :version, type: Integer, default: 1
  property :content_hash, type: String
  property :url, type: String
  property :metadata, type: String, default: "{}"

  # Relationships
  has_many :out, :entities, type: :MENTIONS, model_class: :EntityNode
  has_many :out, :topics, type: :COVERS, model_class: :TopicNode
  has_many :out, :claims, type: :EXTRACTED_FROM, model_class: :ClaimNode
  has_many :out, :evidence, type: :FROM_DOCUMENT, model_class: :EvidenceNode
  has_many :in, :questions, type: :USES_DOCUMENT, model_class: :QuestionNode
  has_many :out, :previous_versions, type: :PREVIOUS_VERSION, model_class: :DocumentNode
  has_many :in, :next_versions, type: :PREVIOUS_VERSION, model_class: :DocumentNode

  # Relationship convenience methods
  def contains_claims
    claims
  end

  def provides_evidence
    evidence
  end

  def mentions_entity
    entities
  end

  def covers_topic
    topics
  end

  def answers_questions
    questions
  end

  def previous_version
    previous_versions.first
  end

  def next_version
    next_versions.first
  end

  # Version tracking
  def create_new_version(new_content_hash)
    new_version = self.class.create!(
      name: name,
      source_id: source_id,
      organization_id: organization_id,
      version: version + 1,
      content_hash: new_content_hash,
      url: url,
      metadata: metadata,
      global_id: "#{self.class.name.downcase}_#{SecureRandom.hex(16)}"
    )

    new_version.previous_versions << self
    new_version
  end

  # Complex graph traversal for finding affected questions using ActiveGraph queries
  def affected_questions
    # Direct question usage
    direct_questions = questions.to_a

    # Questions through shared entities
    entity_questions = entities.flat_map { |entity| entity.questions }.uniq

    # Questions through shared topics
    topic_questions = topics.flat_map { |topic| topic.questions }.uniq

    (direct_questions + entity_questions + topic_questions).uniq(&:global_id)
  end

  # Extract and link entities using ActiveGraph associations
  def extract_entities(entity_names)
    entity_names.each do |entity_name|
      entity = EntityNode.find_or_create_by(
        name: entity_name,
        organization_id: organization_id
      )

      # Add entity if not already connected
      entities << entity unless entities.include?(entity)
    end
  end

  # Extract and link topics using ActiveGraph associations
  def extract_topics(topic_names)
    topic_names.each do |topic_name|
      topic = TopicNode.find_or_create_by(
        name: topic_name,
        organization_id: organization_id
      )

      # Add topic if not already connected
      topics << topic unless topics.include?(topic)
    end
  end

  # Class method to find or create by unique attributes
  def self.find_or_create_by(attributes)
    node = find_by(attributes)
    node || create!(attributes.merge(global_id: "#{name.downcase}_#{SecureRandom.hex(16)}"))
  end
end
