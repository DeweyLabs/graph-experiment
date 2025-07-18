# Base class for all Neo4j nodes using ActiveGraph
class ApplicationNode
  include ActiveGraph::Node

  # Common properties for all nodes
  property :global_id, type: String
  property :organization_id, type: Integer
  property :created_at, type: DateTime
  property :updated_at, type: DateTime

  # Callbacks
  before_create :set_timestamps, :ensure_global_id
  before_save :set_updated_at

  # Cross-database reference to ActiveRecord model
  def active_record_model
    GlobalID::Locator.locate(global_id) if global_id
  end

  # Create node from ActiveRecord model
  def self.from_active_record(ar_model)
    return nil unless ar_model

    node = find_by(global_id: ar_model.to_global_id.to_s)
    node || create_from_active_record(ar_model)
  end

  def self.create_from_active_record(ar_model)
    create!(
      global_id: ar_model.to_global_id.to_s,
      organization_id: ar_model.organization_id
    )
  end

  # Multi-tenancy scoping
  scope :for_organization, ->(org_id) { where(organization_id: org_id) }

  private

  def set_timestamps
    self.created_at ||= DateTime.current
    self.updated_at ||= DateTime.current
  end

  def set_updated_at
    self.updated_at = DateTime.current
  end

  def ensure_global_id
    self.global_id ||= "#{self.class.name.underscore}_#{SecureRandom.hex(16)}"
  end
end
