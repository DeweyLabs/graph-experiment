require "rails_helper"

RSpec.describe Source, type: :model do
  describe "associations" do
    it { should belong_to(:organization) }
    it { should have_many(:documents).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:source) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:adapter_type) }
    it { should validate_inclusion_of(:adapter_type).in_array(%w[google_drive dropbox notion slack github confluence]) }
    it { should validate_inclusion_of(:status).in_array(%w[active paused error]) }
  end

  describe "defaults" do
    let(:source) { build(:source) }

    it "sets default status to active" do
      new_source = Source.new(name: "Test", adapter_type: "dropbox")
      expect(new_source.status).to eq("active")
    end

    it "initializes config as empty hash" do
      new_source = Source.new(name: "Test", adapter_type: "dropbox")
      expect(new_source.config).to eq({})
    end

    it "initializes sync_state as empty hash" do
      new_source = Source.new(name: "Test", adapter_type: "dropbox")
      expect(new_source.sync_state).to eq({})
    end
  end

  describe "scopes" do
    let!(:active_source) { create(:source, status: "active") }
    let!(:paused_source) { create(:source, status: "paused") }
    let!(:error_source) { create(:source, :with_error) }
    let!(:recently_synced) { create(:source, :recently_synced) }
    let!(:never_synced) { create(:source, last_sync_at: nil) }
    let!(:old_sync) { create(:source, last_sync_at: 2.hours.ago) }

    describe ".active" do
      it "returns only active sources" do
        expect(Source.active).to contain_exactly(active_source, recently_synced, never_synced, old_sync)
      end
    end

    describe ".with_errors" do
      it "returns only sources with errors" do
        expect(Source.with_errors).to contain_exactly(error_source)
      end
    end

    describe ".ready_for_sync" do
      it "returns active sources that have never synced or synced more than 1 hour ago" do
        expect(Source.ready_for_sync).to contain_exactly(active_source, never_synced, old_sync)
      end
    end
  end

  describe "#sync_in_progress?" do
    it "returns true when sync is in progress" do
      source = build(:source, :syncing)
      expect(source.sync_in_progress?).to be true
    end

    it "returns false when sync is not in progress" do
      source = build(:source)
      expect(source.sync_in_progress?).to be false
    end

    it "returns false when sync_state is nil" do
      source = build(:source, sync_state: nil)
      expect(source.sync_in_progress?).to be false
    end
  end

  describe "#mark_sync_started!" do
    let(:source) { create(:source) }

    it "updates sync_state to in_progress" do
      freeze_time do
        source.mark_sync_started!
        expect(source.sync_state["in_progress"]).to be true
        expect(source.sync_state["started_at"]).to eq(Time.current.as_json)
      end
    end
  end

  describe "#mark_sync_completed!" do
    let(:source) { create(:source, :syncing) }

    it "updates sync_state and last_sync_at" do
      freeze_time do
        source.mark_sync_completed!

        expect(source.sync_state["in_progress"]).to be false
        expect(source.sync_state["completed_at"]).to eq(Time.current.as_json)
        expect(source.last_sync_at).to eq(Time.current)
        expect(source.status).to eq("active")
      end
    end
  end

  describe "#mark_sync_failed!" do
    let(:source) { create(:source, :syncing) }

    it "updates sync_state with error and sets status to error" do
      freeze_time do
        error_message = "API rate limit exceeded"
        source.mark_sync_failed!(error_message)

        expect(source.sync_state["in_progress"]).to be false
        expect(source.sync_state["error"]).to eq(error_message)
        expect(source.sync_state["failed_at"]).to eq(Time.current.as_json)
        expect(source.status).to eq("error")
      end
    end
  end

  describe "organization scoping" do
    let(:org1) { create(:organization) }
    let(:org2) { create(:organization) }
    let!(:source1) { create(:source, organization: org1) }
    let!(:source2) { create(:source, organization: org2) }

    it "scopes sources to organization" do
      expect(org1.sources).to contain_exactly(source1)
      expect(org2.sources).to contain_exactly(source2)
    end
  end
end
