class Source < ApplicationRecord
  # Associations
  belongs_to :organization
  has_many :documents, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :adapter_type, presence: true,
            inclusion: { in: %w[google_drive dropbox notion slack github confluence] }
  validates :status, inclusion: { in: %w[active paused error] }
  
  # Defaults
  after_initialize :set_defaults, if: :new_record?
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :with_errors, -> { where(status: 'error') }
  scope :ready_for_sync, -> { active.where('last_sync_at IS NULL OR last_sync_at < ?', 1.hour.ago) }
  
  # Methods
  def sync_in_progress?
    sync_state&.dig('in_progress') == true
  end
  
  def mark_sync_started!
    update!(sync_state: { 'in_progress' => true, 'started_at' => Time.current })
  end
  
  def mark_sync_completed!
    update!(
      sync_state: { 'in_progress' => false, 'completed_at' => Time.current },
      last_sync_at: Time.current,
      status: 'active'
    )
  end
  
  def mark_sync_failed!(error_message)
    update!(
      sync_state: { 'in_progress' => false, 'error' => error_message, 'failed_at' => Time.current },
      status: 'error'
    )
  end
  
  private
  
  def set_defaults
    self.status ||= 'active'
    self.config ||= {}
    self.sync_state ||= {}
  end
end
