class QuestionNode < ApplicationNode
  # Question-specific properties
  property :content, type: String
  property :answer, type: String
  property :answer_confidence, type: Float
  property :answer_updated_at, type: DateTime
  property :semantic_embedding, type: String, default: "[]"

  # Relationships
  has_many :in, :answered_by, type: :ANSWERED_BY, model_class: :ClaimNode
  has_many :out, :documents, type: :USES_DOCUMENT, model_class: :DocumentNode
  has_many :out, :entities, type: :MENTIONS, model_class: :EntityNode
  has_many :out, :topics, type: :RELATED_TO, model_class: :TopicNode
  has_many :in, :evidence, type: :SUPPORTED_BY, model_class: :EvidenceNode

  # Relationship convenience methods
  def uses_document
    documents
  end

  def mentions_entity
    entities
  end

  def related_to_topic
    topics
  end

  def supported_by_evidence
    evidence
  end

  # Complex graph traversal for finding relevant documents using ActiveGraph
  def relevant_documents
    # Direct document usage
    direct_docs = documents.to_a

    # Documents through shared entities
    entity_docs = entities.flat_map { |entity| entity.documents }.uniq

    # Documents through shared topics
    topic_docs = topics.flat_map { |topic| topic.documents }.uniq

    (direct_docs + entity_docs + topic_docs).uniq(&:global_id)
  end

  # Check if question needs update based on document changes
  def needs_update?(document_node)
    # Check if this question is connected to the document through entities/topics
    question_entity_ids = entities.pluck(:global_id)
    document_entity_ids = document_node.entities.pluck(:global_id)
    shared_entities = question_entity_ids & document_entity_ids
    
    question_topic_ids = topics.pluck(:global_id)
    document_topic_ids = document_node.topics.pluck(:global_id)
    shared_topics = question_topic_ids & document_topic_ids
    
    shared_entities.any? || shared_topics.any?
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

  # Update answer with confidence and timestamp
  def update_answer!(new_answer, confidence)
    self.answer = new_answer
    self.answer_confidence = confidence
    self.answer_updated_at = DateTime.current
    save!
  end

  # Class method to find or create by unique attributes
  def self.find_or_create_by(attributes)
    node = find_by(attributes)
    node || create!(attributes.merge(global_id: "#{name.downcase}_#{SecureRandom.hex(16)}"))
  end
end
