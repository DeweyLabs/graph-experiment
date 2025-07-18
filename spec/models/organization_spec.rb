require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it { should have_many(:sources).dependent(:destroy) }
    it { should have_many(:documents).dependent(:destroy) }
    it { should have_many(:document_chunks).dependent(:destroy) }
    it { should have_many(:question_answers).dependent(:destroy) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }
    it { should validate_inclusion_of(:status).in_array(%w[active suspended cancelled]) }
    it { should validate_inclusion_of(:plan).in_array(%w[free starter professional enterprise]) }
    
    it 'validates subdomain format' do
      org = Organization.new(name: 'Test', subdomain: 'test-org')
      expect(org).to be_valid
      
      org.subdomain = 'Test_Org'
      expect(org).not_to be_valid
      expect(org.errors[:subdomain]).to include('only allows lowercase letters, numbers and hyphens')
    end
  end
  
  describe 'defaults' do
    let(:org) { Organization.new(name: 'Test', subdomain: 'test') }
    
    it 'sets default status to active' do
      expect(org.status).to eq('active')
    end
    
    it 'sets default plan to free' do
      expect(org.plan).to eq('free')
    end
    
    it 'initializes settings as empty hash' do
      expect(org.settings).to eq({})
    end
  end
  
  describe 'scopes' do
    let!(:active_org) { Organization.create!(name: 'Active', subdomain: 'active', status: 'active') }
    let!(:suspended_org) { Organization.create!(name: 'Suspended', subdomain: 'suspended', status: 'suspended') }
    
    it 'returns only active organizations' do
      expect(Organization.active).to include(active_org)
      expect(Organization.active).not_to include(suspended_org)
    end
  end
end