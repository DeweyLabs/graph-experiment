#!/usr/bin/env ruby
# Setup Neo4j schema constraints and indexes

puts "Setting up Neo4j schema with essential constraints..."

# Essential constraints only
constraints = [
  "CREATE CONSTRAINT application_uuid IF NOT EXISTS FOR (n:ApplicationNode) REQUIRE n.uuid IS UNIQUE",
  "CREATE CONSTRAINT document_global_id IF NOT EXISTS FOR (n:DocumentNode) REQUIRE n.global_id IS UNIQUE",
  "CREATE CONSTRAINT entity_global_id IF NOT EXISTS FOR (n:EntityNode) REQUIRE n.global_id IS UNIQUE",
  "CREATE CONSTRAINT question_global_id IF NOT EXISTS FOR (n:QuestionNode) REQUIRE n.global_id IS UNIQUE",
  "CREATE CONSTRAINT claim_global_id IF NOT EXISTS FOR (n:ClaimNode) REQUIRE n.global_id IS UNIQUE",
  "CREATE CONSTRAINT evidence_global_id IF NOT EXISTS FOR (n:EvidenceNode) REQUIRE n.global_id IS UNIQUE",
  "CREATE CONSTRAINT topic_global_id IF NOT EXISTS FOR (n:TopicNode) REQUIRE n.global_id IS UNIQUE"
]

# Essential indexes only
indexes = [
  "CREATE INDEX document_org_id IF NOT EXISTS FOR (n:DocumentNode) ON (n.organization_id)",
  "CREATE INDEX entity_org_id IF NOT EXISTS FOR (n:EntityNode) ON (n.organization_id)",
  "CREATE INDEX question_org_id IF NOT EXISTS FOR (n:QuestionNode) ON (n.organization_id)",
  "CREATE INDEX claim_org_id IF NOT EXISTS FOR (n:ClaimNode) ON (n.organization_id)",
  "CREATE INDEX evidence_org_id IF NOT EXISTS FOR (n:EvidenceNode) ON (n.organization_id)",
  "CREATE INDEX topic_org_id IF NOT EXISTS FOR (n:TopicNode) ON (n.organization_id)"
]

begin
  # Create constraints
  constraints.each do |constraint|
    ActiveGraph::Base.query(constraint)
    puts "✓ Created constraint: #{constraint.split(' ')[2]}"
  end

  # Create indexes
  indexes.each do |index|
    ActiveGraph::Base.query(index)
    puts "✓ Created index: #{index.split(' ')[2]}"
  end

  puts "\n✅ Neo4j schema setup complete!"
rescue => e
  puts "\n❌ Error setting up Neo4j schema: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end