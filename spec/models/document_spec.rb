require "rails_helper"

RSpec.describe Document, type: :model do
  describe "associations" do
    it { should belong_to(:source) }
    it { should belong_to(:organization) }
    it { should have_many(:document_chunks).dependent(:destroy) }
    it { should have_many(:question_answers).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:document) }

    it { should validate_presence_of(:external_id) }
    it { should validate_uniqueness_of(:external_id).scoped_to(:source_id) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_inclusion_of(:embedding_status).in_array(%w[pending processing completed failed]) }
  end

  describe "defaults" do
    let(:document) { Document.new(title: "Test", content: "Content", external_id: "123") }

    it "sets default embedding_status to pending" do
      expect(document.embedding_status).to eq("pending")
    end

    it "initializes metadata as empty hash" do
      expect(document.metadata).to eq({})
    end

    it "sets default chunk_count to 0" do
      expect(document.chunk_count).to eq(0)
    end
  end

  describe "callbacks" do
    describe "before_save :update_chunk_count" do
      let(:document) { create(:document) }

      it "updates chunk_count when status is completed" do
        create_list(:document_chunk, 3, document: document)
        document.embedding_status = "completed"
        document.save!

        expect(document.chunk_count).to eq(3)
      end

      it "does not update chunk_count when status is not completed" do
        create_list(:document_chunk, 3, document: document)
        document.embedding_status = "processing"
        document.save!

        expect(document.chunk_count).to eq(0)
      end
    end
  end

  describe "scopes" do
    let!(:pending_doc) { create(:document, embedding_status: "pending") }
    let!(:processing_doc) { create(:document, :processing) }
    let!(:completed_doc) { create(:document, :processed) }
    let!(:failed_doc) { create(:document, :failed) }

    describe ".pending_embedding" do
      it "returns only pending documents" do
        expect(Document.pending_embedding).to contain_exactly(pending_doc)
      end
    end

    describe ".processed" do
      it "returns only completed documents" do
        expect(Document.processed).to contain_exactly(completed_doc)
      end
    end

    describe ".recent" do
      it "orders documents by created_at desc" do
        # Clear any existing documents to avoid conflicts
        Document.destroy_all

        old_doc = create(:document, created_at: 1.week.ago)
        mid_doc = create(:document, created_at: 1.day.ago)
        new_doc = create(:document, created_at: 1.minute.ago)

        recent_docs = Document.recent.to_a
        expect(recent_docs).to eq([new_doc, mid_doc, old_doc])
      end
    end
  end

  describe "#ready_for_chunking?" do
    it "returns true when content is present and status is pending" do
      document = build(:document, content: "Some content", embedding_status: "pending")
      expect(document.ready_for_chunking?).to be true
    end

    it "returns false when content is blank" do
      document = build(:document, content: "", embedding_status: "pending")
      expect(document.ready_for_chunking?).to be false
    end

    it "returns false when status is not pending" do
      document = build(:document, content: "Some content", embedding_status: "processing")
      expect(document.ready_for_chunking?).to be false
    end
  end

  describe "#mark_processing!" do
    let(:document) { create(:document) }

    it "updates embedding_status to processing" do
      document.mark_processing!
      expect(document.reload.embedding_status).to eq("processing")
    end
  end

  describe "#mark_completed!" do
    let(:document) { create(:document, :processing) }

    it "updates embedding_status to completed and sets processed_at" do
      freeze_time do
        document.mark_completed!
        document.reload

        expect(document.embedding_status).to eq("completed")
        expect(document.processed_at).to eq(Time.current)
      end
    end
  end

  describe "#mark_failed!" do
    let(:document) { create(:document, :processing) }

    it "updates embedding_status to failed" do
      document.mark_failed!
      expect(document.reload.embedding_status).to eq("failed")
    end

    it "stores error message in metadata" do
      document.mark_failed!("Embedding API error")
      expect(document.reload.metadata["error"]).to eq("Embedding API error")
    end

    it "preserves existing metadata" do
      document.update!(metadata: {"key" => "value"})
      document.mark_failed!("Error")

      expect(document.reload.metadata).to eq({
        "key" => "value",
        "error" => "Error"
      })
    end
  end

  describe "unique external_id per source" do
    let(:source1) { create(:source) }
    let(:source2) { create(:source) }

    it "allows same external_id for different sources" do
      create(:document, source: source1, external_id: "ABC123")
      doc2 = build(:document, source: source2, external_id: "ABC123")

      expect(doc2).to be_valid
    end

    it "prevents duplicate external_id for same source" do
      create(:document, source: source1, external_id: "ABC123")
      doc2 = build(:document, source: source1, external_id: "ABC123")

      expect(doc2).not_to be_valid
      expect(doc2.errors[:external_id]).to include("has already been taken")
    end
  end
end
