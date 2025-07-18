# Neo4j Graph Database Integration

This document explains how to use the Neo4j graph database integration in the Dewey application.

## Overview

The Neo4j integration solves the "brute force problem" of finding relationships between documents and questions by using graph traversal instead of computing similarity between all documents/questions.

## Setup

### 1. Start Neo4j

```bash
# Using Docker
docker run -d \
  --name neo4j \
  -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/password \
  neo4j:latest

# Or install locally and start the service
```

### 2. Configure Environment Variables

```bash
# .env or .env.development
NEO4J_HOST=localhost
NEO4J_PORT=7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=password
```

### 3. Setup Schema

```bash
# Create indexes and constraints
rails neo4j:setup_schema

# Test connection
rails neo4j:test_connection

# View statistics
rails neo4j:stats
```

### 4. Migrate Existing Data

```bash
# Migrate all existing documents and questions to graph
rails neo4j:migrate_existing
```

## Core Concepts

### Node Types

1. **DocumentNode** - Represents documents in the graph
2. **QuestionNode** - Represents questions/answers
3. **EntityNode** - Named entities (people, places, concepts)
4. **TopicNode** - Thematic categories
5. **ClaimNode** - Atomic assertions from documents
6. **EvidenceNode** - Text spans supporting claims

### Key Relationships

- `MENTIONS` - Documents/Questions mention Entities
- `RELATED_TO` - Questions/Claims related to Topics
- `USES_DOCUMENT` - Questions use Documents
- `EXTRACTED_FROM` - Claims extracted from Documents
- `SUPPORTS/CONTRADICTS` - Claim relationships

## Usage Examples

### Creating Graph Nodes

```ruby
# When a document is created or updated
document = Document.find(123)
document.create_or_update_graph_node

# Extract and sync entities
document.sync_entities_to_graph(["Ruby on Rails", "PostgreSQL", "API"])

# Extract and sync topics
document.sync_topics_to_graph(["Web Development", "Backend"])
```

### Finding Affected Questions

```ruby
# When a new document is added, find questions that might need updating
document = Document.find(123)
affected_questions = document.affected_questions_from_graph

affected_questions.each do |question|
  # Queue for re-answering with new context
  UpdateQuestionAnswerJob.perform_later(question.id)
end
```

### Finding Relevant Documents

```ruby
# When a new question is asked, find relevant documents
question = QuestionAnswer.find(456)
relevant_docs = question.find_relevant_documents_via_graph

# Use these documents as context for answering
```

### Checking Update Necessity

```ruby
# Check if a question needs updating for a new document
question = QuestionAnswer.find(456)
document = Document.find(123)

if question.should_update_for_document?(document)
  # Update the answer with new information
end
```

## Graph Traversal Patterns

### Document → Questions

1. Document has entities/topics
2. Find questions mentioning same entities/topics
3. Return unique set of questions

### Question → Documents

1. Question has entities/topics
2. Find documents mentioning same entities/topics
3. Return unique set of documents

## Performance Benefits

Instead of O(N) similarity searches:
- Document addition: O(E + T) where E=entities, T=topics
- Question addition: O(E + T) entity/topic lookups
- Scales independently of corpus size

## Maintenance

```bash
# View graph statistics
rails neo4j:stats

# Drop all graph data (DANGER!)
rails neo4j:drop_all

# Clear organization's graph data
org = Organization.find_by(subdomain: 'acme-corp')
org.clear_graph_data!
```

## Testing

```bash
# Run Neo4j integration tests
rspec spec/integration/neo4j_graph_spec.rb

# Test in console
rails console

doc = Document.first
doc.create_or_update_graph_node
doc.sync_entities_to_graph(["Test Entity"])
doc.affected_questions_from_graph
```

## Best Practices

1. **Entity Normalization**: Always use consistent entity names
2. **Topic Hierarchy**: Organize topics from general to specific
3. **Incremental Updates**: Update graph as documents/questions are processed
4. **Batch Operations**: Use batch operations for initial data migration
5. **Monitor Performance**: Check `rails neo4j:stats` regularly

## Troubleshooting

### Connection Issues

```ruby
# Test connection
ActiveGraph::Base.driver.session do |session|
  result = session.run("RETURN 1 as test")
  puts result.first[:test]
end
```

### Missing Relationships

```ruby
# Check entity connections
entity = EntityNode.find_by(name: "Rails")
entity.mentioned_in_documents.count
entity.mentioned_in_questions.count
```

### Performance Issues

1. Check indexes: `rails neo4j:setup_schema`
2. Monitor query performance in Neo4j browser
3. Use query profiling: `PROFILE MATCH ...`

## Future Enhancements

1. **Claim Extraction**: Automated claim extraction from documents
2. **Contradiction Detection**: Find conflicting information
3. **Temporal Tracking**: Version history and updates
4. **Confidence Propagation**: Update confidence based on evidence
5. **Graph ML**: Use graph embeddings for better matching