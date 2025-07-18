# Neo4j Graph Database Integration

## Overview

This document describes the Neo4j graph database integration for the Dewey AI-powered SaaS platform. The graph database solves the "brute force problem" of O(N) similarity searches by enabling efficient O(E+T) graph traversal through entity and topic connections.

**Status**: ✅ **Successfully integrated ActiveGraph 12.0.0.beta.5 with Rails 8** - All tests passing, migrations working, full ActiveGraph DSL support enabled.

## Architecture

### Multi-Database Design

The system uses a hybrid database architecture:
- **PostgreSQL**: Primary application data (organizations, sources, documents, chunks)
- **Neo4j**: Graph relationships for knowledge discovery
- **Pinecone**: Vector embeddings for semantic search (separate integration)

### Cross-Database References

Neo4j nodes reference PostgreSQL records using Rails GlobalID:
- Format: `gid://dewey/ModelName/id`
- Example: `gid://dewey/Document/123`
- Enables bidirectional navigation between databases

## Graph Schema

### Node Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                           GRAPH NODES                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐         │
│  │ DocumentNode│     │QuestionNode │     │  ClaimNode  │         │
│  │─────────────│     │─────────────│     │─────────────│         │
│  │ global_id   │     │ global_id   │     │ global_id   │         │
│  │ name        │     │ content     │     │ content     │         │
│  │ source_id   │     │ answer      │     │ confidence  │         │
│  │ content_hash│     │ confidence  │     │ metadata    │         │
│  │ metadata    │     │ metadata    │     │             │         │
│  └─────────────┘     └─────────────┘     └─────────────┘         │
│                                                                     │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐         │
│  │ EntityNode  │     │  TopicNode  │     │EvidenceNode │         │
│  │─────────────│     │─────────────│     │─────────────│         │
│  │ global_id   │     │ global_id   │     │ global_id   │         │
│  │ name        │     │ name        │     │ content     │         │
│  │ normalized  │     │ description │     │ start_pos   │         │
│  │ aliases     │     │ parent_id   │     │ end_pos     │         │
│  │ entity_type │     │             │     │ weight      │         │
│  └─────────────┘     └─────────────┘     └─────────────┘         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Relationship Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RELATIONSHIPS                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Document ─[MENTIONS]─> Entity <─[MENTIONS]─ Question              │
│     │                      │                      │                 │
│     │                      │                      │                 │
│  [COVERS]               [RELATED_TO]          [RELATED_TO]         │
│     │                      │                      │                 │
│     ▼                      ▼                      ▼                 │
│   Topic <──────────────[RELATED_TO]────────────> Topic             │
│     │                                             │                 │
│  [SUBTOPIC_OF]                              [PARENT_OF]            │
│     │                                             │                 │
│     ▼                                             ▼                 │
│   Topic                                         Topic               │
│                                                                     │
│  Question ─[USES_DOCUMENT]─> Document                              │
│                                                                     │
│  Claim ─[EXTRACTED_FROM]─> Document                                │
│     │                                                              │
│  [SUPPORTS/CONTRADICTS]                                            │
│     │                                                              │
│     ▼                                                              │
│   Claim                                                            │
│                                                                     │
│  Evidence ─[FROM_DOCUMENT]─> Document                              │
│     │                                                              │
│  [SUPPORTS]                                                        │
│     │                                                              │
│     ▼                                                              │
│   Claim                                                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Implementation Details

### ActiveGraph 12.0.0.beta.5 Integration

We successfully integrated ActiveGraph 12.0.0.beta.5 with Rails 8, providing a clean Ruby DSL for Neo4j operations:

```ruby
# config/initializers/neo4j.rb
require 'active_graph'

ActiveGraph::Base.driver = ActiveGraph::Core::Driver.new(
  "bolt://#{ENV.fetch('NEO4J_HOST', 'localhost')}:#{ENV.fetch('NEO4J_PORT', '7687')}",
  ActiveGraph::Core::AuthToken.basic(
    ENV.fetch('NEO4J_USERNAME', 'neo4j'),
    ENV.fetch('NEO4J_PASSWORD', 'password')
  ),
  encryption: false
)
```

### Base Node Class

All graph nodes inherit from `ApplicationNode` which uses ActiveGraph:

```ruby
class ApplicationNode
  include ActiveGraph::Node

  # Common properties for all nodes
  property :global_id, type: String
  property :organization_id, type: Integer
  property :created_at, type: DateTime
  property :updated_at, type: DateTime

  # Callbacks
  before_create :set_timestamps, :ensure_global_id
  before_save :set_updated_at

  private

  def ensure_global_id
    self.global_id ||= "#{self.class.name.underscore}_#{SecureRandom.hex(16)}"
  end
end
```

### Key Design Patterns

1. **ActiveGraph DSL**: Clean Ruby syntax for relationships and queries
2. **Automatic UUID Generation**: All nodes get unique global_id on creation
3. **Multi-tenancy**: All nodes include `organization_id` for data isolation
4. **JSON Serialization**: Complex properties (hashes, arrays) stored as JSON strings
5. **ActiveGraph Migrations**: Schema management through migration files

## Usage Examples

### Document → Questions Traversal

When a new document arrives, find affected questions:

```ruby
# O(E+T) graph traversal instead of O(N) similarity search
doc = Document.find(123)

# Create or sync the graph node
doc.create_or_update_graph_node
doc.sync_entities_to_graph(["Rails", "PostgreSQL", "API"])
doc.sync_topics_to_graph(["Web Development", "Backend"])

# Find affected questions via graph
affected_questions = doc.affected_questions_from_graph

# Implementation traverses:
# 1. Direct document usage: doc.graph_node.questions
# 2. Shared entities: doc.graph_node.entities.flat_map(&:questions)
# 3. Related topics: doc.graph_node.topics.flat_map(&:questions)
```

### Question → Documents Discovery

When a new question is asked, find relevant documents:

```ruby
qa = QuestionAnswer.find(456)

# Create graph node and sync relationships
qa.create_or_update_graph_node
qa.sync_entities_to_graph(["Rails", "Authentication"])
qa.sync_topics_to_graph(["Security", "Web Development"])

# Find relevant documents via graph
relevant_docs = qa.find_relevant_documents_via_graph

# Traverses through entities and topics using ActiveGraph relationships
```

### Entity-Based Discovery

Find all questions about a specific entity:

```ruby
# Using ActiveGraph DSL
entity = EntityNode.where(name: "Code Review", organization_id: 1).first
questions = entity.questions.to_a  # via MENTIONS relationship
documents = entity.documents.to_a  # via MENTIONS relationship

# Or using normalized search
entity = EntityNode.find_or_create_normalized("Code Review", organization_id)
related_entities = entity.related_entities  # RELATED_TO relationships
```

### Topic Hierarchy Navigation

Navigate topic hierarchies using ActiveGraph:

```ruby
# Create topic hierarchy
parent, child = TopicNode.create_hierarchy("Engineering", "Backend Development", org.id)

# Navigate up and down the hierarchy
all_subtopics = parent.all_subtopics    # Get all descendants
all_parents = child.all_parent_topics   # Get all ancestors

# Find all related content in topic tree
content = parent.all_related_content
# Returns: { documents: [...], questions: [...], claims: [...] }
```

## ActiveGraph Migrations

### Migration Commands

```bash
# Generate new migration
rails generate neo4j:migration MigrationName

# Run pending migrations
rails neo4j:migrate

# Check migration status
rails neo4j:migrate:status

# Rollback migrations
rails neo4j:rollback
rails neo4j:rollback STEP=n
```

### Other Neo4j Tasks

```bash
# Show database statistics
rails neo4j:stats

# Test connection
rails neo4j:test_connection

# Migrate existing PostgreSQL data to Neo4j
rails neo4j:migrate_existing

# Drop all Neo4j data (DANGER!)
rails neo4j:drop_all
```

### Example Migration

```ruby
class SetupInitialSchema < ActiveGraph::Migrations::Base
  def up
    # Create unique constraints
    add_constraint :DocumentNode, :global_id, type: :unique
    add_constraint :EntityNode, :global_id, type: :unique
    add_constraint :QuestionNode, :global_id, type: :unique
    
    # Create indexes for performance
    add_index :DocumentNode, :organization_id
    add_index :EntityNode, :normalized_name
    add_index :TopicNode, :name
  end
  
  def down
    drop_constraint :DocumentNode, :global_id
    drop_constraint :EntityNode, :global_id
    drop_constraint :QuestionNode, :global_id
    
    drop_index :DocumentNode, :organization_id
    drop_index :EntityNode, :normalized_name
    drop_index :TopicNode, :name
  end
end
```

## Performance Benefits

### Traditional Approach (O(N))
- For each new document: Check similarity against ALL N questions
- For each new question: Check similarity against ALL N documents
- Cost grows linearly with data size

### Graph Approach (O(E+T))
- For each new document: Extract E entities + T topics, traverse connections
- For each new question: Extract entities/topics, find connected documents
- Cost based on entity/topic connections, not total data size

### Real-World Impact
- 10,000 questions × 1,000 documents = 10M comparisons (traditional)
- ~50 entities + ~20 topics = ~70 traversals (graph approach)
- 142,857x reduction in operations

## Database Queries

### Find Questions Affected by Document Update

**ActiveGraph DSL:**
```ruby
def affected_questions_from_graph
  # Direct usage
  directly_used = questions.to_a
  
  # Via shared entities 
  entity_questions = entities.flat_map(&:questions).uniq
  
  # Via shared topics
  topic_questions = topics.flat_map(&:questions).uniq
  
  (directly_used + entity_questions + topic_questions).uniq
end
```

**Equivalent Cypher:**
```cypher
MATCH (doc:DocumentNode {global_id: $doc_id})
WITH doc
MATCH (doc)<-[:USES_DOCUMENT]-(q:QuestionNode)
RETURN DISTINCT q
UNION
MATCH (doc:DocumentNode {global_id: $doc_id})-[:MENTIONS]->(e:EntityNode)<-[:MENTIONS]-(q:QuestionNode)
RETURN DISTINCT q
UNION
MATCH (doc:DocumentNode {global_id: $doc_id})-[:COVERS]->(t:TopicNode)<-[:RELATED_TO]-(q:QuestionNode)
RETURN DISTINCT q
```

### Find Documents Relevant to Question

**ActiveGraph DSL:**
```ruby
def find_relevant_documents_via_graph
  # Via shared entities
  entity_docs = entities.flat_map(&:documents).uniq
  
  # Via shared topics  
  topic_docs = topics.flat_map(&:documents).uniq
  
  (entity_docs + topic_docs).uniq
end
```

**Equivalent Cypher:**
```cypher
MATCH (q:QuestionNode {global_id: $q_id})-[:MENTIONS]->(e:EntityNode)<-[:MENTIONS]-(d:DocumentNode)
RETURN DISTINCT d
UNION
MATCH (q:QuestionNode {global_id: $q_id})-[:RELATED_TO]->(t:TopicNode)<-[:COVERS]-(d:DocumentNode)
RETURN DISTINCT d
```

## Maintenance

### Adding New Node Types

1. Create node class inheriting from `ApplicationNode`
2. Define properties and relationships using ActiveGraph DSL
3. Generate migration to add constraints/indexes
4. Create corresponding methods in ActiveRecord models

```ruby
class MyNewNode < ApplicationNode
  property :name, type: String
  property :description, type: String
  
  has_many :out, :related_documents, type: :RELATED_TO, model_class: :DocumentNode
  has_many :in, :questions, type: :ABOUT, model_class: :QuestionNode
end
```

### Debugging

Enable ActiveGraph query logging:
```ruby
# In config/environments/development.rb
ActiveGraph::Base.logger = Rails.logger
ActiveGraph::Base.query_builder_enabled = true
```

Check Neo4j Browser:
```
http://localhost:7474
```

### Common Issues

1. **Association Proxy Errors**: Use `.pluck(:property)` before set operations like `&` or `|`
2. **Property Type Error**: Store complex types as JSON strings, parse when reading
3. **Migration Timeouts**: Use manual schema setup script for initial constraints
4. **Missing global_id**: Ensure `before_create :ensure_global_id` callback is triggered
5. **Connection Issues**: Check Neo4j is running and environment variables are set

### ActiveGraph-Specific Patterns

```ruby
# WRONG: Association proxies don't support set operations
shared = question.entities & document.entities

# RIGHT: Convert to arrays first
question_entity_ids = question.entities.pluck(:global_id)
document_entity_ids = document.entities.pluck(:global_id)
shared = question_entity_ids & document_entity_ids

# WRONG: Use destroy! (doesn't exist in ActiveGraph)
node.destroy!

# RIGHT: Use destroy
node.destroy
```

## Future Enhancements

1. **Graph Algorithms**: PageRank for entity importance, community detection
2. **Temporal Relationships**: Track how relationships change over time
3. **Confidence Scoring**: Weight relationships based on extraction confidence
4. **Batch Operations**: Optimize bulk imports with UNWIND queries
5. **Graph Embeddings**: Combine with vector search for hybrid retrieval