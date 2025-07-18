class TopicNode < ApplicationNode
  # Topic-specific properties
  property :name, type: String
  property :description, type: String
  property :level, type: Integer, default: 0
  property :metadata, type: String, default: "{}"

  # Relationships
  has_many :in, :documents, type: :COVERS, model_class: :DocumentNode
  has_many :in, :questions, type: :RELATED_TO, model_class: :QuestionNode
  has_many :in, :claims, type: :RELATED_TO, model_class: :ClaimNode
  has_many :out, :subtopics, type: :SUBTOPIC_OF, model_class: :TopicNode
  has_many :in, :parent_topics, type: :SUBTOPIC_OF, model_class: :TopicNode
  has_many :both, :related_topics, type: :RELATED_TO, model_class: :TopicNode

  # Relationship convenience methods
  def covered_by_documents
    documents
  end

  def related_to_questions
    questions
  end

  def related_to_claims
    claims
  end

  def parent_topic
    parent_topics.first
  end

  def child_topics
    subtopics
  end

  # Topic hierarchy methods
  def ancestors
    ancestors = []
    current = self
    while current.parent_topic
      current = current.parent_topic
      ancestors << current
    end
    ancestors
  end

  def descendants
    descendants = []
    subtopics.each do |subtopic|
      descendants << subtopic
      descendants += subtopic.descendants
    end
    descendants
  end

  # Alias for descendants - used in tests
  def all_subtopics
    descendants
  end

  # Alias for ancestors - used in tests
  def all_parent_topics
    ancestors
  end

  def root?
    parent_topics.empty?
  end

  def leaf?
    subtopics.empty?
  end

  # Find all content related to this topic and its subtopics
  def all_related_content
    all_topics = [self] + descendants
    {
      documents: all_topics.flat_map(&:documents).uniq,
      questions: all_topics.flat_map(&:questions).uniq,
      claims: all_topics.flat_map(&:claims).uniq
    }
  end

  # Class method to create a topic hierarchy
  def self.create_hierarchy(parent_name, child_name, organization_id)
    parent = find_or_create_by(
      name: parent_name,
      organization_id: organization_id,
      level: 0
    )
    
    child = find_or_create_by(
      name: child_name,
      organization_id: organization_id,
      level: parent.level + 1
    )
    
    # Create parent-child relationship
    child.parent_topics << parent unless child.parent_topics.include?(parent)
    
    [parent, child]
  end

  # Class method to find or create by unique attributes
  def self.find_or_create_by(attributes)
    node = find_by(attributes)
    node || create!(attributes.merge(global_id: "#{name.downcase}_#{SecureRandom.hex(16)}"))
  end
end
