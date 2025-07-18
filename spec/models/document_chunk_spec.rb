require "rails_helper"

RSpec.describe DocumentChunk, type: :model do
  describe "associations" do
    it { should belong_to(:document) }
    it { should belong_to(:organization) }
  end

  describe "validations" do
    subject { build(:document_chunk) }

    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:chunk_index) }
    it { should validate_uniqueness_of(:chunk_index).scoped_to(:document_id) }
    it { should validate_uniqueness_of(:pinecone_id).allow_nil }
  end

  describe "defaults" do
    let(:organization) { create(:organization) }
    let(:document) { create(:document, organization: organization) }
    let(:chunk) { DocumentChunk.new(document: document, organization: organization, content: "Test content", chunk_index: 0) }

    it "initializes metadata as empty hash" do
      expect(chunk.metadata).to eq({})
    end

    it "generates pinecone_id based on organization, document, and chunk_index" do
      chunk.save!
      expect(chunk.pinecone_id).to eq("#{organization.id}_#{document.id}_0")
    end
  end

  describe "scopes" do
    let!(:chunk_with_embedding) { create(:document_chunk, :with_embedding) }
    let!(:chunk_without_embedding) { create(:document_chunk, embedding: nil) }

    describe ".with_embeddings" do
      it "returns only chunks with embeddings" do
        expect(DocumentChunk.with_embeddings).to contain_exactly(chunk_with_embedding)
      end
    end

    describe ".without_embeddings" do
      it "returns only chunks without embeddings" do
        expect(DocumentChunk.without_embeddings).to contain_exactly(chunk_without_embedding)
      end
    end

    describe ".by_index" do
      let!(:document) { create(:document) }
      let!(:chunk2) { create(:document_chunk, document: document, chunk_index: 2) }
      let!(:chunk0) { create(:document_chunk, document: document, chunk_index: 0) }
      let!(:chunk1) { create(:document_chunk, document: document, chunk_index: 1) }

      it "orders chunks by index" do
        expect(document.document_chunks.by_index).to eq([chunk0, chunk1, chunk2])
      end
    end
  end

  describe "#has_embedding?" do
    it "returns true when embedding is present" do
      chunk = build(:document_chunk, :with_embedding)
      expect(chunk.has_embedding?).to be true
    end

    it "returns false when embedding is nil" do
      chunk = build(:document_chunk, embedding: nil)
      expect(chunk.has_embedding?).to be false
    end
  end

  describe "#embedding_vector" do
    context "with valid embedding" do
      let(:vector) { Array.new(10) { rand(-1.0..1.0) } }
      let(:chunk) { build(:document_chunk, embedding: vector.to_json) }

      it "returns parsed array" do
        expect(chunk.embedding_vector).to eq(vector)
      end
    end

    context "with invalid JSON" do
      let(:chunk) { build(:document_chunk, embedding: "invalid json") }

      it "returns nil" do
        expect(chunk.embedding_vector).to be_nil
      end
    end
  end

  describe "#embedding_vector=" do
    let(:chunk) { build(:document_chunk) }
    let(:vector) { Array.new(10) { rand(-1.0..1.0) } }

    it "stores array as JSON string" do
      chunk.embedding_vector = vector
      expect(chunk.embedding).to eq(vector.to_json)
    end
  end

  describe "#prepare_for_pinecone" do
    let(:chunk) { create(:document_chunk, :with_embedding, :with_metadata) }

    it "returns properly formatted hash for Pinecone" do
      result = chunk.prepare_for_pinecone

      expect(result).to include(
        id: chunk.pinecone_id,
        values: chunk.embedding_vector,
        metadata: hash_including(
          organization_id: chunk.organization_id,
          document_id: chunk.document_id,
          document_title: chunk.document.title,
          source_id: chunk.document.source_id,
          chunk_index: chunk.chunk_index
        )
      )
    end

    it "truncates content to 1000 characters" do
      chunk.update!(content: "x" * 2000)
      result = chunk.prepare_for_pinecone

      expect(result[:metadata][:content].length).to eq(1000)
    end
  end
end
