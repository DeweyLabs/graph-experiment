require "rails_helper"

RSpec.describe QuestionAnswer, type: :model do
  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:document) }
  end

  describe "validations" do
    subject { build(:question_answer) }

    it { should validate_presence_of(:question) }
    it { should validate_uniqueness_of(:question).scoped_to(:organization_id) }
    it { should validate_presence_of(:answer) }
    it { should validate_numericality_of(:confidence_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1).allow_nil }
    it { should validate_uniqueness_of(:pinecone_id).allow_nil }
  end

  describe "defaults" do
    let(:qa) { QuestionAnswer.new(question: "Test?", answer: "Answer") }

    it "initializes metadata as empty hash" do
      expect(qa.metadata).to eq({})
    end

    it "sets default confidence_score to 0.0" do
      expect(qa.confidence_score).to eq(0.0)
    end
  end

  describe "scopes" do
    let!(:high_confidence_qa) { create(:question_answer, :high_confidence) }
    let!(:low_confidence_qa) { create(:question_answer, :low_confidence) }

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
  end

  describe "#generate_pinecone_id" do
    let(:qa) { create(:question_answer) }

    it "generates ID with organization and qa prefix" do
      expect(qa.generate_pinecone_id).to match(/^qa_\d+_[a-f0-9]{16}$/)
    end
  end
end
