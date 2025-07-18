class EntityNode < ApplicationNode
  # Entity-specific properties
  property :name, type: String
  property :entity_type, type: String
  property :normalized_name, type: String
  property :aliases, type: String, default: "[]"
  property :metadata, type: String, default: "{}"

  # Relationships
  has_many :in, :documents, type: :MENTIONS, model_class: :DocumentNode
  has_many :in, :questions, type: :MENTIONS, model_class: :QuestionNode
  has_many :in, :claims, type: :MENTIONS, model_class: :ClaimNode
  has_many :out, :children, type: :PARENT_OF, model_class: :EntityNode
  has_many :in, :parents, type: :PARENT_OF, model_class: :EntityNode
  has_many :out, :defines, type: :DEFINES, model_class: :EntityNode
  has_many :in, :defined_by, type: :DEFINES, model_class: :EntityNode
  has_many :out, :causes, type: :CAUSES, model_class: :EntityNode
  has_many :in, :caused_by, type: :CAUSES, model_class: :EntityNode
  has_many :both, :related_entities, type: :RELATED_TO, model_class: :EntityNode

  # Callbacks
  before_save :normalize_name

  # Relationship convenience methods
  def mentioned_in_claims
    claims
  end

  def mentioned_in_documents
    documents
  end

  def mentioned_in_questions
    questions
  end

  def hierarchical_parent
    parents.first
  end

  def hierarchical_children
    children
  end

  def related_to
    related_entities
  end

  # Entity-specific methods
  def add_alias(alias_name)
    normalized_alias = self.class.normalize_string(alias_name)
    current_aliases = JSON.parse(aliases || "[]")
    unless current_aliases.include?(normalized_alias)
      current_aliases << normalized_alias
      self.aliases = current_aliases.to_json
      save!
    end
  end

  def merge_with(other_entity)
    # Merge another entity into this one
    return false if other_entity.global_id == global_id

    # Transfer all relationships using ActiveGraph
    other_entity.claims.each { |claim| claim.entities << self unless claim.entities.include?(self) }
    other_entity.documents.each { |doc| doc.entities << self unless doc.entities.include?(self) }
    other_entity.questions.each { |question| question.entities << self unless question.entities.include?(self) }

    # Merge aliases
    other_aliases = JSON.parse(other_entity.aliases || "[]")
    other_aliases.each { |alias_name| add_alias(alias_name) }
    add_alias(other_entity.name) if other_entity.name != name

    # Delete the other entity
    other_entity.destroy

    true
  end

  # Class methods
  def self.find_or_create_normalized(name, organization_id, entity_type = nil)
    normalized = normalize_string(name)

    entity = find_by(normalized_name: normalized, organization_id: organization_id)

    entity || create!(
      name: name,
      normalized_name: normalized,
      organization_id: organization_id,
      entity_type: entity_type,
      global_id: "#{self.name.downcase}_#{SecureRandom.hex(16)}"
    )
  end

  def self.normalize_string(str)
    str.downcase.strip.gsub(/[^a-z0-9\s]/, "").gsub(/\s+/, " ")
  end

  def self.find_or_create_by(attributes)
    # If name is provided, use normalized search
    if attributes[:name] && attributes[:organization_id]
      find_or_create_normalized(attributes[:name], attributes[:organization_id], attributes[:entity_type])
    else
      node = find_by(attributes)
      node || create!(attributes.merge(global_id: "#{name.downcase}_#{SecureRandom.hex(16)}"))
    end
  end

  private

  def normalize_name
    self.normalized_name = self.class.normalize_string(name) if name
  end
end
