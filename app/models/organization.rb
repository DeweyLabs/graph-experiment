class Organization < ApplicationRecord
  # Associations
  has_many :sources, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :document_chunks, dependent: :destroy
  has_many :question_answers, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true, 
            format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers and hyphens" }
  validates :status, inclusion: { in: %w[active suspended cancelled] }
  validates :plan, inclusion: { in: %w[free starter professional enterprise] }
  
  # Defaults
  after_initialize :set_defaults, if: :new_record?
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  
  private
  
  def set_defaults
    self.status ||= 'active'
    self.plan ||= 'free'
    self.settings ||= {}
  end
end
