require "rails_helper"

RSpec.describe Organization, type: :model do
  describe "associations" do
    it { should have_many(:sources).dependent(:destroy) }
    it { should have_many(:documents).dependent(:destroy) }
    it { should have_many(:document_chunks).dependent(:destroy) }
    it { should have_many(:question_answers).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:organization) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }
    it { should validate_inclusion_of(:status).in_array(%w[active suspended cancelled]) }
    it { should validate_inclusion_of(:plan).in_array(%w[free starter professional enterprise]) }

    context "subdomain format" do
      it "accepts valid subdomains" do
        valid_subdomains = ["test-org", "company123", "my-company", "abc"]
        valid_subdomains.each do |subdomain|
          org = build(:organization, subdomain: subdomain)
          expect(org).to be_valid, "#{subdomain} should be valid"
        end
      end

      it "rejects invalid subdomains" do
        invalid_subdomains = ["Test_Org", "UPPERCASE", "with spaces", "special@char", "under_score"]
        invalid_subdomains.each do |subdomain|
          org = build(:organization, subdomain: subdomain)
          expect(org).not_to be_valid
          expect(org.errors[:subdomain]).to include("only allows lowercase letters, numbers and hyphens")
        end
      end
    end
  end

  describe "defaults" do
    let(:org) { Organization.new(name: "Test", subdomain: "test") }

    it "sets default status to active" do
      expect(org.status).to eq("active")
    end

    it "sets default plan to free" do
      expect(org.plan).to eq("free")
    end

    it "initializes settings as empty hash" do
      expect(org.settings).to eq({})
    end

    it "preserves explicitly set values" do
      org = Organization.new(
        name: "Test",
        subdomain: "test",
        status: "suspended",
        plan: "enterprise",
        settings: {feature_flags: ["beta"]}
      )

      expect(org.status).to eq("suspended")
      expect(org.plan).to eq("enterprise")
      expect(org.settings).to eq({"feature_flags" => ["beta"]})
    end
  end

  describe "scopes" do
    let!(:active_org) { create(:organization, status: "active") }
    let!(:suspended_org) { create(:organization, :suspended) }
    let!(:cancelled_org) { create(:organization, status: "cancelled") }

    describe ".active" do
      it "returns only active organizations" do
        expect(Organization.active).to contain_exactly(active_org)
      end
    end
  end

  describe "cascading deletes" do
    let(:organization) { create(:organization, :with_sources) }

    before do
      # Create associated records
      source = organization.sources.first
      document = create(:document, source: source, organization: organization)
      create(:document_chunk, document: document, organization: organization)
      create(:question_answer, document: document, organization: organization)
    end

    it "deletes all associated records when organization is destroyed" do
      expect { organization.destroy }.to change {
        [Organization.count, Source.count, Document.count, DocumentChunk.count, QuestionAnswer.count]
      }.from([1, 2, 1, 1, 1]).to([0, 0, 0, 0, 0])
    end
  end
end
