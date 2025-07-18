#!/usr/bin/env ruby
# Test ActiveGraph integration

# Find or create a test organization
timestamp = Time.now.to_f.to_s.delete(".")
org = Organization.find_or_create_by(subdomain: "test-activegraph-#{timestamp}") do |o|
  o.name = "Test Org ActiveGraph"
end
puts "Organization created: " + org.name

# Generate unique IDs for this test
timestamp = Time.now.to_f.to_s.delete(".")

# Test creating a DocumentNode
doc = DocumentNode.create!(
  global_id: "doc_test_#{timestamp}",
  organization_id: org.id,
  name: "Test Document",
  source_id: "src_001",
  content_hash: "hash123"
)
puts "DocumentNode created: " + doc.name

# Test creating an EntityNode
entity = EntityNode.create!(
  global_id: "entity_test_#{timestamp}",
  organization_id: org.id,
  name: "Test Entity",
  normalized_name: "test entity"
)
puts "EntityNode created: " + entity.name

# Test relationship
doc.entities << entity
puts "Relationship created between document and entity"

# Test scopes
puts "Documents for organization: " + DocumentNode.for_organization(org.id).count.to_s
puts "Entities for organization: " + EntityNode.for_organization(org.id).count.to_s

# Test graph statistics
begin
  puts "Graph statistics:"
  puts org.graph_statistics
rescue => e
  puts "Graph statistics error: #{e.message}"
end

# Clean up
doc.destroy
entity.destroy
org.destroy
puts "Test completed and cleaned up"
