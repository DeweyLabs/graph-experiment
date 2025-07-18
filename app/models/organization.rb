class Organization < ApplicationRecord
  # Associations
  has_many :sources, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :document_chunks, dependent: :destroy
  has_many :question_answers, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers and hyphens"}
  validates :status, inclusion: {in: %w[active suspended cancelled]}
  validates :plan, inclusion: {in: %w[free starter professional enterprise]}

  # Defaults
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :active, -> { where(status: "active") }

  private

  def set_defaults
    self.status ||= "active"
    self.plan ||= "free"
    self.settings ||= {}
  end

  # Graph-related methods
  public

  def graph_statistics
    {
      entities: EntityNode.for_organization(id).count,
      topics: TopicNode.for_organization(id).count,
      claims: ClaimNode.for_organization(id).count,
      evidence: EvidenceNode.for_organization(id).count,
      document_nodes: DocumentNode.for_organization(id).count,
      question_nodes: QuestionNode.for_organization(id).count
    }
  end

  def clear_graph_data!
    # Clear all graph data for this organization
    # Use with caution!
    query = "MATCH (n) WHERE n.organization_id = $org_id DETACH DELETE n"

    ActiveGraph::Base.query(query, org_id: id)
  end

  def sync_all_to_graph
    # Sync all documents and questions to graph
    documents.find_each do |document|
      document.create_or_update_graph_node
    end

    question_answers.find_each do |qa|
      qa.create_or_update_graph_node
    end
  end
end
