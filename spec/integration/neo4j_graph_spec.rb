require "rails_helper"

RSpec.describe "Neo4j Graph Integration", type: :integration do
  let(:organization) { create(:organization, name: "Test Org") }
  let(:source) { create(:source, organization: organization) }

  before(:each) do
    # Clear any existing graph data for the test organization
    organization.clear_graph_data!
  end

  after(:each) do
    # Clean up after tests
    organization.clear_graph_data!
  end

  describe "Document to Graph synchronization" do
    let(:document) { create(:document, organization: organization, source: source, title: "Test Document") }

    it "creates a document node in the graph" do
      expect {
        document.create_or_update_graph_node
      }.to change { DocumentNode.where(organization_id: organization.id).count }.by(1)

      node = document.graph_node
      expect(node).to be_present
      expect(node.name).to eq("Test Document")
      expect(node.organization_id).to eq(organization.id)
    end

    it "syncs entities to the graph" do
      document.create_or_update_graph_node

      expect {
        document.sync_entities_to_graph(["Ruby on Rails", "PostgreSQL", "API"])
      }.to change { EntityNode.where(organization_id: organization.id).count }.by(3)

      entities = document.graph_node.mentions_entity.pluck(:name)
      expect(entities).to match_array(["Ruby on Rails", "PostgreSQL", "API"])
    end

    it "syncs topics to the graph" do
      document.create_or_update_graph_node

      expect {
        document.sync_topics_to_graph(["Web Development", "Backend", "Database"])
      }.to change { TopicNode.where(organization_id: organization.id).count }.by(3)

      topics = document.graph_node.covers_topic.pluck(:name)
      expect(topics).to match_array(["Web Development", "Backend", "Database"])
    end
  end

  describe "Question to Graph synchronization" do
    let(:question_answer) { create(:question_answer, organization: organization, question: "How to deploy?") }

    it "creates a question node in the graph" do
      expect {
        question_answer.create_or_update_graph_node
      }.to change { QuestionNode.where(organization_id: organization.id).count }.by(1)

      node = question_answer.graph_node
      expect(node).to be_present
      expect(node.content).to eq("How to deploy?")
      expect(node.answer).to eq(question_answer.answer)
    end

    it "links questions to documents in the graph" do
      document = create(:document, organization: organization, source: source)
      question_answer.update!(document: document)

      document.create_or_update_graph_node
      question_answer.create_or_update_graph_node
      question_answer.link_to_document_in_graph(document)

      expect(question_answer.graph_node.uses_document.count).to eq(1)
      expect(question_answer.graph_node.uses_document.first).to eq(document.graph_node)
    end
  end

  describe "Graph traversal for affected questions" do
    let!(:doc1) { create(:document, organization: organization, source: source, title: "Rails Guide") }
    let!(:doc2) { create(:document, organization: organization, source: source, title: "API Docs") }
    let!(:qa1) { create(:question_answer, organization: organization, question: "How to use Rails?") }
    let!(:qa2) { create(:question_answer, organization: organization, question: "What is the API endpoint?") }
    let!(:qa3) { create(:question_answer, organization: organization, question: "How to authenticate?") }

    before do
      # Set up graph nodes
      doc1.create_or_update_graph_node
      doc2.create_or_update_graph_node
      qa1.create_or_update_graph_node
      qa2.create_or_update_graph_node
      qa3.create_or_update_graph_node

      # Set up entities and relationships
      doc1.sync_entities_to_graph(["Rails", "Ruby"])
      doc1.sync_topics_to_graph(["Web Framework", "Backend"])

      doc2.sync_entities_to_graph(["API", "REST", "Authentication"])
      doc2.sync_topics_to_graph(["API", "Security"])

      qa1.sync_entities_to_graph(["Rails", "Ruby"])
      qa1.sync_topics_to_graph(["Web Framework"])

      qa2.sync_entities_to_graph(["API", "REST"])
      qa2.sync_topics_to_graph(["API"])

      qa3.sync_entities_to_graph(["Authentication", "API"])
      qa3.sync_topics_to_graph(["Security", "API"])
    end

    it "finds questions affected by document updates through entities" do
      affected = doc1.affected_questions_from_graph

      expect(affected.map(&:id)).to include(qa1.id)
      expect(affected.map(&:id)).not_to include(qa2.id, qa3.id)
    end

    it "finds questions affected by API document through multiple paths" do
      affected = doc2.affected_questions_from_graph

      expect(affected.map(&:id)).to include(qa2.id, qa3.id)
      expect(affected.map(&:id)).not_to include(qa1.id)
    end

    it "finds relevant documents for a question" do
      relevant = qa3.find_relevant_documents_via_graph

      expect(relevant.map(&:id)).to include(doc2.id)
      expect(relevant.map(&:id)).not_to include(doc1.id)
    end

    it "determines if a question needs updating for a new document" do
      expect(qa1.should_update_for_document?(doc1)).to be true
      expect(qa1.should_update_for_document?(doc2)).to be false

      expect(qa3.should_update_for_document?(doc2)).to be true
      expect(qa3.should_update_for_document?(doc1)).to be false
    end
  end

  describe "Entity relationships" do
    it "creates and links entities correctly" do
      entity1 = EntityNode.find_or_create_normalized("Ruby on Rails", organization.id, "framework")
      entity2 = EntityNode.find_or_create_normalized("ruby on rails", organization.id, "framework")

      # Should be the same entity due to normalization
      expect(entity1.id).to eq(entity2.id)

      entity3 = EntityNode.find_or_create_normalized("Ruby", organization.id, "language")
      entity1.related_to << entity3

      expect(entity1.related_to.count).to eq(1)
      expect(entity1.related_to.first).to eq(entity3)
    end

    it "merges duplicate entities" do
      entity1 = EntityNode.create!(
        name: "PostgreSQL",
        normalized_name: "postgresql",
        organization_id: organization.id
      )

      entity2 = EntityNode.create!(
        name: "Postgres",
        normalized_name: "postgres",
        organization_id: organization.id
      )

      entity2.add_alias("pg")

      expect {
        entity1.merge_with(entity2)
      }.to change { EntityNode.where(organization_id: organization.id).count }.by(-1)

      expect(entity1.aliases).to include("postgres", "pg")
    end
  end

  describe "Topic hierarchy" do
    it "creates topic hierarchies correctly" do
      parent, child = TopicNode.create_hierarchy("Engineering", "Backend Development", organization.id)

      expect(parent.subtopics.count).to eq(1)
      expect(parent.subtopics.first).to eq(child)
      expect(child.parent_topics.first).to eq(parent)
      expect(child.level).to eq(parent.level + 1)
    end

    it "traverses topic hierarchies" do
      root = TopicNode.create!(name: "Technology", organization_id: organization.id, level: 0)
      eng = TopicNode.create!(name: "Engineering", organization_id: organization.id, level: 1)
      backend = TopicNode.create!(name: "Backend", organization_id: organization.id, level: 2)
      api = TopicNode.create!(name: "API Design", organization_id: organization.id, level: 3)

      eng.parent_topics << root
      backend.parent_topics << eng
      api.parent_topics << backend

      expect(root.all_subtopics.map(&:name)).to match_array(["Engineering", "Backend", "API Design"])
      expect(api.all_parent_topics.map(&:name)).to match_array(["Backend", "Engineering", "Technology"])
    end
  end

  describe "Claims and evidence" do
    let(:document) { create(:document, organization: organization, source: source) }

    before do
      document.create_or_update_graph_node
    end

    it "creates claims from documents" do
      claim = ClaimNode.create!(
        global_id: "claim_test_123",
        organization_id: organization.id,
        content: "Rails uses MVC architecture",
        confidence_score: 0.95
      )

      claim.extracted_from << document.graph_node
      claim.add_entity("Rails")
      claim.add_entity("MVC")
      claim.add_topic("Architecture")

      expect(claim.extracted_from.first).to eq(document.graph_node)
      expect(claim.mentions_entity.pluck(:name)).to match_array(["Rails", "MVC"])
      expect(claim.related_to_topic.pluck(:name)).to include("Architecture")
    end

    it "creates evidence supporting claims" do
      claim = ClaimNode.create!(
        global_id: "claim_test_456",
        organization_id: organization.id,
        content: "Testing is important",
        confidence_score: 0.90
      )

      evidence = EvidenceNode.create_from_document(
        document.graph_node,
        "All tests must pass",
        100,
        119,
        50
      )

      evidence.supports_claims << claim

      expect(evidence.from_document).to eq(document.graph_node)
      expect(evidence.supports_claims.first).to eq(claim)
      expect(evidence.text_span).to eq("All tests must pass")
    end
  end

  describe "Organization graph statistics" do
    it "provides accurate graph statistics" do
      # Create some test data
      3.times { create(:document, organization: organization, source: source).create_or_update_graph_node }
      2.times { create(:question_answer, organization: organization).create_or_update_graph_node }

      EntityNode.create!(name: "Test Entity", normalized_name: "test entity", organization_id: organization.id)
      TopicNode.create!(name: "Test Topic", organization_id: organization.id)

      stats = organization.graph_statistics

      expect(stats[:document_nodes]).to eq(3)
      expect(stats[:question_nodes]).to eq(2)
      expect(stats[:entities]).to eq(1)
      expect(stats[:topics]).to eq(1)
      expect(stats[:claims]).to eq(0)
      expect(stats[:evidence]).to eq(0)
    end
  end

  describe "Performance optimization" do
    it "efficiently finds affected questions for document updates" do
      # Create a larger dataset
      10.times do |i|
        doc = create(:document, organization: organization, source: source, title: "Doc #{i}")
        doc.create_or_update_graph_node
        doc.sync_entities_to_graph(["Entity#{i}", "Common Entity"])

        qa = create(:question_answer, organization: organization, question: "Question #{i}")
        qa.create_or_update_graph_node
        qa.sync_entities_to_graph(["Entity#{i}", "Common Entity"])
      end

      test_doc = create(:document, organization: organization, source: source, title: "New Doc")
      test_doc.create_or_update_graph_node
      test_doc.sync_entities_to_graph(["Common Entity", "New Entity"])

      # This should be efficient even with many questions
      affected = test_doc.affected_questions_from_graph

      # All questions should be affected due to "Common Entity"
      expect(affected.size).to eq(10)
    end
  end
end
