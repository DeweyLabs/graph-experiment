require "rails_helper"

RSpec.describe QuestionAnswer, type: :model do
  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:document).optional }
  end

  describe "validations" do
    subject { build(:question_answer) }

    it { should validate_presence_of(:question) }
    it { should validate_uniqueness_of(:question).scoped_to(:organization_id) }
    it { should validate_presence_of(:answer) }
    it { should validate_numericality_of(:confidence_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1).allow_nil }
    it { should validate_uniqueness_of(:pinecone_id).allow_nil }
    it { should validate_inclusion_of(:source_type).in_array(%w[document query chat]) }
  end

  describe "defaults" do
    context "with document" do
      let(:doc) { create(:document) }
      let(:qa) { QuestionAnswer.new(question: "Test?", answer: "Answer", organization: doc.organization, document: doc) }

      it "initializes metadata as empty hash" do
        expect(qa.metadata).to eq({})
      end

      it "sets default confidence_score to 0.0" do
        expect(qa.confidence_score).to eq(0.0)
      end

      it "sets source_type to document when document is present" do
        expect(qa.source_type).to eq("document")
      end
    end

    context "without document" do
      let(:org) { create(:organization) }

      it "defaults to document source_type due to database default" do
        qa = QuestionAnswer.new(question: "Test?", answer: "Answer", organization: org)
        expect(qa.source_type).to eq("document")
      end

      it "accepts explicit source_type for query-based Q&As" do
        qa = QuestionAnswer.new(question: "Test?", answer: "Answer", organization: org, source_type: "query")
        expect(qa.source_type).to eq("query")
      end
    end
  end

  describe "scopes" do
    let(:org) { create(:organization) }
    let!(:high_confidence_qa) { create(:question_answer, :high_confidence, organization: org) }
    let!(:low_confidence_qa) { create(:question_answer, :low_confidence, organization: org) }
    let!(:query_qa) { create(:question_answer, organization: org, document: nil, source_type: "query") }
    let!(:chat_qa) { create(:question_answer, organization: org, document: nil, source_type: "chat") }

    describe ".high_confidence" do
      it "returns only high confidence Q&As" do
        expect(QuestionAnswer.high_confidence).to include(high_confidence_qa)
        expect(QuestionAnswer.high_confidence).not_to include(low_confidence_qa)
      end
    end

    describe ".by_confidence" do
      it "orders by confidence score descending" do
        results = QuestionAnswer.by_confidence
        expect(results.first.confidence_score).to be >= results.last.confidence_score
      end
    end

    describe ".from_documents" do
      it "returns only document-sourced Q&As" do
        expect(QuestionAnswer.from_documents).to include(high_confidence_qa, low_confidence_qa)
        expect(QuestionAnswer.from_documents).not_to include(query_qa, chat_qa)
      end
    end

    describe ".from_queries" do
      it "returns only query-sourced Q&As" do
        expect(QuestionAnswer.from_queries).to include(query_qa)
        expect(QuestionAnswer.from_queries).not_to include(high_confidence_qa, chat_qa)
      end
    end

    describe ".from_chat" do
      it "returns only chat-sourced Q&As" do
        expect(QuestionAnswer.from_chat).to include(chat_qa)
        expect(QuestionAnswer.from_chat).not_to include(high_confidence_qa, query_qa)
      end
    end

    describe ".without_document" do
      it "returns only Q&As without document" do
        expect(QuestionAnswer.without_document).to include(query_qa, chat_qa)
        expect(QuestionAnswer.without_document).not_to include(high_confidence_qa, low_confidence_qa)
      end
    end
  end

  describe "#generate_pinecone_id" do
    let(:qa) { create(:question_answer) }

    it "generates ID with organization and qa prefix" do
      expect(qa.generate_pinecone_id).to match(/^qa_\d+_[a-f0-9]{16}$/)
    end
  end
end
