namespace :neo4j do
  desc "Create Neo4j indexes and constraints using ActiveGraph"
  task setup_schema: :environment do
    puts "Setting up Neo4j schema with ActiveGraph..."

    begin
      # ActiveGraph automatically creates constraints and indexes based on model definitions
      # We can also create additional ones manually if needed

      # Use ActiveGraph::Base.query for ActiveGraph 12.0.0.beta.5

      # Create constraints for unique global_id across all node types
      [
        "CREATE CONSTRAINT claim_global_id IF NOT EXISTS FOR (n:ClaimNode) REQUIRE n.global_id IS UNIQUE",
        "CREATE CONSTRAINT document_global_id IF NOT EXISTS FOR (n:DocumentNode) REQUIRE n.global_id IS UNIQUE",
        "CREATE CONSTRAINT question_global_id IF NOT EXISTS FOR (n:QuestionNode) REQUIRE n.global_id IS UNIQUE",
        "CREATE CONSTRAINT entity_global_id IF NOT EXISTS FOR (n:EntityNode) REQUIRE n.global_id IS UNIQUE",
        "CREATE CONSTRAINT topic_global_id IF NOT EXISTS FOR (n:TopicNode) REQUIRE n.global_id IS UNIQUE",
        "CREATE CONSTRAINT evidence_global_id IF NOT EXISTS FOR (n:EvidenceNode) REQUIRE n.global_id IS UNIQUE"
      ].each do |constraint|
        ActiveGraph::Base.query(constraint)
        puts "✓ Created constraint: #{constraint.split(" ")[2]}"
      end

      # Create indexes for efficient lookups
      [
        # Organization-based indexes for multi-tenancy
        "CREATE INDEX claim_org_id IF NOT EXISTS FOR (n:ClaimNode) ON (n.organization_id)",
        "CREATE INDEX document_org_id IF NOT EXISTS FOR (n:DocumentNode) ON (n.organization_id)",
        "CREATE INDEX question_org_id IF NOT EXISTS FOR (n:QuestionNode) ON (n.organization_id)",
        "CREATE INDEX entity_org_id IF NOT EXISTS FOR (n:EntityNode) ON (n.organization_id)",
        "CREATE INDEX topic_org_id IF NOT EXISTS FOR (n:TopicNode) ON (n.organization_id)",
        "CREATE INDEX evidence_org_id IF NOT EXISTS FOR (n:EvidenceNode) ON (n.organization_id)",

        # Entity lookup indexes
        "CREATE INDEX entity_name IF NOT EXISTS FOR (n:EntityNode) ON (n.name)",
        "CREATE INDEX entity_normalized IF NOT EXISTS FOR (n:EntityNode) ON (n.normalized_name)",

        # Topic lookup indexes
        "CREATE INDEX topic_name IF NOT EXISTS FOR (n:TopicNode) ON (n.name)",

        # Document lookup indexes
        "CREATE INDEX document_source IF NOT EXISTS FOR (n:DocumentNode) ON (n.source_id)",
        "CREATE INDEX document_hash IF NOT EXISTS FOR (n:DocumentNode) ON (n.content_hash)",

        # Composite indexes for common queries
        "CREATE INDEX entity_org_normalized IF NOT EXISTS FOR (n:EntityNode) ON (n.organization_id, n.normalized_name)",
        "CREATE INDEX topic_org_name IF NOT EXISTS FOR (n:TopicNode) ON (n.organization_id, n.name)"
      ].each do |index|
        ActiveGraph::Base.query(index)
        puts "✓ Created index: #{index.split(" ")[2]}"
      end

      puts "\n✅ Neo4j schema setup complete!"
    rescue => e
      puts "\n❌ Error setting up Neo4j schema: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end

  desc "Drop all Neo4j data (DANGER!)"
  task drop_all: :environment do
    print "⚠️  This will DELETE ALL Neo4j data! Are you sure? (yes/no): "
    response = $stdin.gets.chomp

    if response.downcase == "yes"
      # Use ActiveGraph::Base.query for ActiveGraph 12.0.0.beta.5
      ActiveGraph::Base.query("MATCH (n) DETACH DELETE n")
      puts "✅ All Neo4j data has been deleted."
    else
      puts "❌ Operation cancelled."
    end
  end

  desc "Show Neo4j statistics"
  task stats: :environment do
    # Use ActiveGraph::Base.query for ActiveGraph 12.0.0.beta.5

    puts "\n📊 Neo4j Database Statistics:"
    puts "=" * 50

    # Count nodes by type
    node_types = %w[ClaimNode DocumentNode QuestionNode EntityNode TopicNode EvidenceNode]

    node_types.each do |node_type|
      result = ActiveGraph::Base.query("MATCH (n:#{node_type}) RETURN count(n) as count")
      count = result.first[:count]
      puts "#{node_type.ljust(20)}: #{count}"
    end

    puts "\n📈 Relationship Statistics:"
    puts "-" * 50

    # Count relationships by type
    relationship_types = %w[
      SUPPORTS CONTRADICTS REFINES GENERALIZES EQUIVALENT_TO
      SUPERSEDES UPDATES EXTRACTED_FROM MENTIONS RELATED_TO
      COVERED_BY ANSWERED_BY SUPPORTED_BY PARENT_OF DEFINES
      CAUSES SUBTOPIC_OF USES_DOCUMENT FROM_DOCUMENT
    ]

    relationship_types.each do |rel_type|
      result = ActiveGraph::Base.query("MATCH ()-[r:#{rel_type}]->() RETURN count(r) as count")
      count = result.first[:count]
      puts "#{rel_type.ljust(20)}: #{count}" if count > 0
    end

    puts "=" * 50
  end

  desc "Test Neo4j connection"
  task test_connection: :environment do
    # Use ActiveGraph::Base.query for ActiveGraph 12.0.0.beta.5

    result = ActiveGraph::Base.query("RETURN 'Connection successful!' as message")
    puts "✅ #{result.first[:message]}"

    # Get Neo4j version
    version_result = ActiveGraph::Base.query("CALL dbms.components() YIELD name, versions RETURN name, versions[0] as version")
    version_result.each do |record|
      puts "   #{record[:name]}: #{record[:version]}"
    end
  rescue => e
    puts "❌ Neo4j connection failed: #{e.message}"
    puts "   Make sure Neo4j is running and accessible at the configured URL"
  end

  desc "Migrate existing data to Neo4j graph"
  task migrate_existing: :environment do
    puts "Starting migration of existing data to Neo4j..."

    Organization.find_each do |org|
      puts "\n📁 Processing organization: #{org.name}"

      # Migrate documents
      document_count = 0
      org.documents.find_each do |doc|
        doc.create_or_update_graph_node
        document_count += 1
      end
      puts "   ✓ Migrated #{document_count} documents"

      # Migrate questions
      question_count = 0
      org.question_answers.find_each do |qa|
        qa.create_or_update_graph_node
        question_count += 1
      end
      puts "   ✓ Migrated #{question_count} questions"
    end

    puts "\n✅ Migration complete!"
  end
end
