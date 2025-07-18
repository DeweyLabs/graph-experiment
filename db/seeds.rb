# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Clear existing data in development environment
if Rails.env.development?
  puts "Clearing existing data..."
  QuestionAnswer.destroy_all
  DocumentChunk.destroy_all
  Document.destroy_all
  Source.destroy_all
  Organization.destroy_all
end

# Create Organizations
puts "Creating organizations..."

acme_corp = Organization.create!(
  name: "Acme Corporation",
  subdomain: "acme-corp",
  status: "active",
  plan: "enterprise",
  settings: {
    feature_flags: ["advanced_search", "api_access", "custom_models"],
    max_users: 100,
    max_sources: 50
  }
)

startup_inc = Organization.create!(
  name: "Startup Inc",
  subdomain: "startup-inc",
  status: "active",
  plan: "starter",
  settings: {
    feature_flags: ["basic_search"],
    max_users: 5,
    max_sources: 3
  }
)

demo_org = Organization.create!(
  name: "Demo Organization",
  subdomain: "demo",
  status: "active",
  plan: "free",
  settings: {
    feature_flags: [],
    max_users: 1,
    max_sources: 1
  }
)

# Create Sources
puts "Creating sources..."

# Acme Corp sources
acme_gdrive = Source.create!(
  organization: acme_corp,
  name: "Company Drive",
  adapter_type: "google_drive",
  status: "active",
  config: {
    folder_id: "1234567890",
    service_account_key: "encrypted_key_here"
  },
  sync_state: {
    last_cursor: "cursor_123",
    documents_synced: 150,
    last_error: nil
  },
  last_sync_at: 2.hours.ago
)

acme_notion = Source.create!(
  organization: acme_corp,
  name: "Engineering Wiki",
  adapter_type: "notion",
  status: "active",
  config: {
    workspace_id: "notion_workspace_123",
    api_key: "encrypted_api_key"
  },
  sync_state: {
    last_cursor: nil,
    documents_synced: 75,
    last_error: nil
  },
  last_sync_at: 1.day.ago
)

acme_slack = Source.create!(
  organization: acme_corp,
  name: "Team Slack",
  adapter_type: "slack",
  status: "error",
  config: {
    workspace_id: "slack_workspace_456",
    bot_token: "encrypted_bot_token"
  },
  sync_state: {
    last_cursor: "ts_1234567890",
    documents_synced: 500,
    last_error: "Rate limit exceeded",
    error_count: 3
  },
  last_sync_at: 3.days.ago
)

# Startup Inc sources
startup_github = Source.create!(
  organization: startup_inc,
  name: "Code Repository",
  adapter_type: "github",
  status: "active",
  config: {
    repo_owner: "startup-inc",
    repo_name: "main-app",
    access_token: "encrypted_github_token"
  },
  sync_state: {
    last_cursor: "commit_sha_abc123",
    documents_synced: 25,
    last_error: nil
  },
  last_sync_at: 6.hours.ago
)

# Demo org source
demo_dropbox = Source.create!(
  organization: demo_org,
  name: "Demo Files",
  adapter_type: "dropbox",
  status: "paused",
  config: {
    access_token: "encrypted_dropbox_token",
    root_folder: "/Demo"
  },
  sync_state: {
    last_cursor: nil,
    documents_synced: 10,
    last_error: nil
  },
  last_sync_at: 1.week.ago
)

# Create Documents
puts "Creating documents..."

# Sample document content
engineering_handbook_content = <<~CONTENT
  # Engineering Handbook

  ## Code Review Process

  All code changes must go through our peer review process before being merged into the main branch. 
  This ensures code quality, knowledge sharing, and maintains our engineering standards.

  ### Review Requirements
  - At least one approving review from a team member
  - All automated tests must pass
  - Code coverage must not decrease
  - No unresolved comments

  ### Best Practices
  1. Keep pull requests small and focused
  2. Write descriptive commit messages
  3. Include tests for new functionality
  4. Update documentation as needed
  5. Respond to feedback constructively

  ## Deployment Process

  We follow a continuous deployment model with staged rollouts:

  1. **Development**: Automatic deployment on merge to develop branch
  2. **Staging**: Daily deployment from develop, manual trigger
  3. **Production**: Weekly deployment window, requires approval

  ### Pre-deployment Checklist
  - Database migrations reviewed
  - Feature flags configured
  - Monitoring alerts set up
  - Rollback plan documented

  ## On-Call Responsibilities

  Each engineer participates in our on-call rotation to ensure 24/7 system reliability.

  ### Primary Responsibilities
  - Monitor system alerts and dashboards
  - Respond to incidents within SLA
  - Escalate critical issues
  - Document incident resolution

  ### Tools
  - PagerDuty for alerting
  - Datadog for monitoring
  - Slack for communication
  - Jira for incident tracking
CONTENT

api_documentation_content = <<~CONTENT
  # API Documentation

  ## Authentication

  Our API uses OAuth 2.0 for authentication. All requests must include a valid access token.

  ### Obtaining Access Token
  ```
  POST /oauth/token
  Content-Type: application/json

  {
    "grant_type": "client_credentials",
    "client_id": "your_client_id",
    "client_secret": "your_client_secret"
  }
  ```

  ### Using Access Token
  Include the token in the Authorization header:
  ```
  Authorization: Bearer your_access_token
  ```

  ## Endpoints

  ### Users Endpoint
  - GET /api/v1/users - List all users
  - GET /api/v1/users/:id - Get specific user
  - POST /api/v1/users - Create new user
  - PUT /api/v1/users/:id - Update user
  - DELETE /api/v1/users/:id - Delete user

  ### Organizations Endpoint
  - GET /api/v1/organizations - List organizations
  - GET /api/v1/organizations/:id - Get organization details
  - POST /api/v1/organizations - Create organization
  - PUT /api/v1/organizations/:id - Update organization

  ## Rate Limiting

  API requests are limited to:
  - 1000 requests per hour for authenticated requests
  - 60 requests per hour for unauthenticated requests

  Rate limit information is included in response headers:
  - X-RateLimit-Limit
  - X-RateLimit-Remaining
  - X-RateLimit-Reset

  ## Error Handling

  The API returns standard HTTP status codes:
  - 200 OK - Request successful
  - 201 Created - Resource created
  - 400 Bad Request - Invalid parameters
  - 401 Unauthorized - Invalid authentication
  - 404 Not Found - Resource not found
  - 429 Too Many Requests - Rate limit exceeded
  - 500 Internal Server Error - Server error
CONTENT

product_roadmap_content = <<~CONTENT
  # Product Roadmap 2024

  ## Q1 Goals

  ### Search Enhancement
  Improve search accuracy and speed by implementing vector-based semantic search.

  **Key Features:**
  - Implement embedding generation for all documents
  - Set up Pinecone vector database
  - Create similarity search endpoints
  - Add search result ranking

  ### Multi-tenancy
  Full isolation of customer data with organization-based access control.

  **Implementation:**
  - Add organization scoping to all models
  - Implement subdomain routing
  - Create organization management UI
  - Add usage tracking per organization

  ## Q2 Goals

  ### AI-Powered Q&A
  Automatically extract and answer questions from ingested documents.

  **Components:**
  - Question extraction using LLM
  - Answer generation with RAG
  - Confidence scoring
  - Feedback loop for improvement

  ### Additional Integrations
  Expand our source adapter library:
  - Confluence integration
  - Microsoft Teams
  - Salesforce Knowledge
  - Custom API adapter

  ## Q3 Goals

  ### Analytics Dashboard
  Provide insights into knowledge base usage and effectiveness.

  **Metrics:**
  - Search query analytics
  - Most viewed documents
  - Question answer accuracy
  - User engagement metrics

  ### Enterprise Features
  - SSO integration (SAML, OIDC)
  - Advanced access controls
  - Audit logging
  - Compliance reporting

  ## Q4 Goals

  ### Performance Optimization
  - Implement caching strategies
  - Optimize database queries
  - Add CDN for static assets
  - Improve indexing speed

  ### Mobile Applications
  - iOS app for document access
  - Android app development
  - Offline document sync
  - Push notifications
CONTENT

meeting_notes_content = <<~CONTENT
  # Engineering Team Meeting - March 15, 2024

  **Attendees:** Sarah Chen (CTO), Mike Johnson (Lead Dev), Lisa Park (Backend), Tom Williams (Frontend), Amy Rodriguez (DevOps)

  ## Agenda

  ### 1. Sprint Retrospective

  **What went well:**
  - Completed user authentication feature ahead of schedule
  - Improved test coverage to 85%
  - Successfully migrated to new CI/CD pipeline

  **What needs improvement:**
  - Communication between frontend and backend teams
  - Documentation updates lagging behind code changes
  - Need better error handling in API responses

  **Action items:**
  - @Mike: Schedule weekly sync between frontend and backend teams
  - @Lisa: Create documentation template for API changes
  - @Tom: Implement global error handler for API calls

  ### 2. Technical Debt Discussion

  **Identified Issues:**
  - Legacy authentication code needs refactoring
  - Database queries in reports module are slow
  - Inconsistent coding standards across repositories

  **Prioritization:**
  1. Database optimization (affecting users)
  2. Authentication refactor (security concern)
  3. Coding standards (can be gradual)

  ### 3. Upcoming Features

  **Search Enhancement Project:**
  - Lisa to lead backend implementation
  - 3-week timeline estimated
  - Need to evaluate vector database options

  **Decision:** Go with Pinecone for initial implementation

  ### 4. Team Updates

  - Amy: Kubernetes cluster upgrade scheduled for next weekend
  - Tom: New component library ready for review
  - Mike: Interviewing 3 candidates for senior backend position

  ## Next Meeting

  - Date: March 22, 2024
  - Focus: Search enhancement technical design
  - Pre-work: Review Pinecone documentation
CONTENT

troubleshooting_guide_content = <<~CONTENT
  # Troubleshooting Guide

  ## Common Issues and Solutions

  ### Application Won't Start

  **Symptoms:**
  - Server fails to start
  - Port already in use error
  - Database connection errors

  **Solutions:**
  1. Check if port 3000 is already in use: `lsof -i :3000`
  2. Verify database is running: `pg_isready`
  3. Check environment variables are set correctly
  4. Run database migrations: `rails db:migrate`

  ### Authentication Errors

  **401 Unauthorized**
  - Verify API token is valid and not expired
  - Check token is included in Authorization header
  - Ensure user has necessary permissions

  **403 Forbidden**
  - User lacks required role or permission
  - Organization subscription may have expired
  - Feature flag might be disabled

  ### Performance Issues

  **Slow API Responses**
  1. Check database query performance
     - Run EXPLAIN ANALYZE on slow queries
     - Add missing indexes
     - Consider query optimization

  2. Monitor memory usage
     - Check for memory leaks
     - Adjust worker pool size
     - Enable caching where appropriate

  3. Review application logs
     - Look for N+1 queries
     - Check for excessive API calls
     - Monitor external service latency

  ### Data Sync Problems

  **Documents Not Syncing**
  - Verify source credentials are valid
  - Check source API rate limits
  - Review sync job logs for errors
  - Ensure background workers are running

  **Duplicate Documents**
  - Check external_id uniqueness constraint
  - Verify source adapter deduplication logic
  - Review sync timestamp handling

  ## Debugging Tools

  ### Rails Console
  Access production data (use with caution):
  ```ruby
  rails console
  Organization.find_by(subdomain: 'acme-corp')
  Source.active.where(adapter_type: 'slack')
  ```

  ### Log Analysis
  Search for errors:
  ```bash
  grep ERROR log/production.log | tail -100
  grep -i "timeout" log/sidekiq.log
  ```

  ### Database Queries
  Find slow queries:
  ```sql
  SELECT query, calls, mean_time
  FROM pg_stat_statements
  ORDER BY mean_time DESC
  LIMIT 10;
  ```

  ## Contact Support

  If issues persist:
  1. Collect relevant logs
  2. Note steps to reproduce
  3. Include environment details
  4. Submit ticket to support@dewey.ai
CONTENT

# Create documents for each organization
docs = []

# Acme Corp documents
docs << Document.create!(
  organization: acme_corp,
  source: acme_gdrive,
  external_id: "gdrive_001",
  title: "Engineering Handbook",
  content: engineering_handbook_content,
  embedding_status: "completed",
  processed_at: 1.hour.ago,
  metadata: {
    url: "https://drive.google.com/file/d/abc123",
    author: "Sarah Chen",
    last_modified: "2024-03-10",
    file_type: "document",
    tags: ["engineering", "process", "handbook"]
  }
)

docs << Document.create!(
  organization: acme_corp,
  source: acme_gdrive,
  external_id: "gdrive_002",
  title: "API Documentation",
  content: api_documentation_content,
  embedding_status: "completed",
  processed_at: 2.hours.ago,
  metadata: {
    url: "https://drive.google.com/file/d/def456",
    author: "Mike Johnson",
    last_modified: "2024-03-12",
    file_type: "document",
    tags: ["api", "documentation", "technical"]
  }
)

docs << Document.create!(
  organization: acme_corp,
  source: acme_notion,
  external_id: "notion_001",
  title: "Product Roadmap 2024",
  content: product_roadmap_content,
  embedding_status: "pending",
  metadata: {
    url: "https://notion.so/product-roadmap-2024",
    author: "Product Team",
    last_modified: "2024-03-14",
    page_type: "roadmap",
    tags: ["product", "roadmap", "planning"]
  }
)

docs << Document.create!(
  organization: acme_corp,
  source: acme_slack,
  external_id: "slack_msg_001",
  title: "Engineering Team Meeting - March 15",
  content: meeting_notes_content,
  embedding_status: "processing",
  metadata: {
    url: "https://acme.slack.com/archives/C123/p1234567890",
    channel: "engineering",
    participants: ["Sarah Chen", "Mike Johnson", "Lisa Park", "Tom Williams", "Amy Rodriguez"],
    message_type: "meeting_notes",
    timestamp: "2024-03-15T14:00:00Z"
  }
)

# Startup Inc documents
docs << Document.create!(
  organization: startup_inc,
  source: startup_github,
  external_id: "github_readme_001",
  title: "README.md - Main App",
  content: "# Main Application\n\nOur SaaS platform for customer management.\n\n## Installation\n\n1. Clone the repository\n2. Run `bundle install`\n3. Set up the database: `rails db:setup`\n4. Start the server: `rails server`\n\n## Testing\n\nRun the test suite with: `bundle exec rspec`\n\n## Deployment\n\nWe use GitHub Actions for CI/CD. Merging to main automatically deploys to production.",
  embedding_status: "completed",
  processed_at: 3.hours.ago,
  metadata: {
    url: "https://github.com/startup-inc/main-app/blob/main/README.md",
    file_path: "README.md",
    commit_sha: "abc123def456",
    language: "markdown"
  }
)

# Demo org documents
docs << Document.create!(
  organization: demo_org,
  source: demo_dropbox,
  external_id: "dropbox_001",
  title: "Troubleshooting Guide",
  content: troubleshooting_guide_content,
  embedding_status: "completed",
  processed_at: 1.day.ago,
  metadata: {
    url: "https://www.dropbox.com/s/xyz789/troubleshooting.pdf",
    file_size: "245KB",
    file_type: "pdf",
    pages: 12
  }
)

# Create document chunks for documents
puts "Creating document chunks..."

# First, reset completed documents to pending so they can be chunked
docs.select { |d| d.embedding_status == "completed" }.each do |doc|
  doc.update!(embedding_status: "pending")
end

# Now chunk all pending documents
docs.select { |d| d.embedding_status == "pending" }.each do |doc|
  result = Documents::ChunkDocument.run(
    document: doc,
    chunk_size: 800,
    chunk_overlap: 100
  )
  
  if result.valid? && result.result.present?
    puts "  Created #{result.result.size} chunks for: #{doc.title}"
    
    # Simulate embeddings for some chunks
    result.result.sample([3, result.result.size].min).each do |chunk|
      # Generate a fake embedding vector (1536 dimensions for OpenAI ada-002)
      embedding = Array.new(1536) { rand(-1.0..1.0) }
      chunk.update!(
        embedding: embedding.to_json,
        pinecone_id: chunk.generate_pinecone_id
      )
    end
  else
    error_msg = result.errors.present? ? result.errors.full_messages.join(', ') : "No chunks created"
    puts "  Failed to chunk document: #{doc.title} - #{error_msg}"
  end
end

# Create Question/Answer pairs
puts "Creating question/answer pairs..."

# For Engineering Handbook
qa1 = QuestionAnswer.create!(
  organization: acme_corp,
  document: docs[0],
  question: "What are the requirements for code review approval?",
  answer: "Code review requires at least one approving review from a team member, all automated tests must pass, code coverage must not decrease, and there should be no unresolved comments.",
  context: "All code changes must go through our peer review process before being merged into the main branch. Review Requirements: At least one approving review from a team member, All automated tests must pass, Code coverage must not decrease, No unresolved comments",
  confidence_score: 0.95,
  pinecone_id: "qa_#{acme_corp.id}_#{SecureRandom.hex(8)}",
  metadata: {
    source_type: "extracted",
    extraction_method: "llm",
    extracted_at: 1.hour.ago.iso8601
  }
)

qa2 = QuestionAnswer.create!(
  organization: acme_corp,
  document: docs[0],
  question: "What is our deployment schedule?",
  answer: "We follow a continuous deployment model with Development having automatic deployment on merge to develop branch, Staging with daily deployment from develop (manual trigger), and Production with weekly deployment windows that require approval.",
  context: "We follow a continuous deployment model with staged rollouts: Development: Automatic deployment on merge to develop branch, Staging: Daily deployment from develop, manual trigger, Production: Weekly deployment window, requires approval",
  confidence_score: 0.92,
  pinecone_id: "qa_#{acme_corp.id}_#{SecureRandom.hex(8)}",
  metadata: {
    source_type: "extracted",
    extraction_method: "llm"
  }
)

# For API Documentation
qa3 = QuestionAnswer.create!(
  organization: acme_corp,
  document: docs[1],
  question: "How do I authenticate with the API?",
  answer: "The API uses OAuth 2.0 for authentication. You need to obtain an access token by making a POST request to /oauth/token with your client credentials, then include the token in the Authorization header as 'Bearer your_access_token'.",
  context: "Our API uses OAuth 2.0 for authentication. All requests must include a valid access token. POST /oauth/token with grant_type, client_id, and client_secret. Include the token in the Authorization header: Authorization: Bearer your_access_token",
  confidence_score: 0.98,
  pinecone_id: "qa_#{acme_corp.id}_#{SecureRandom.hex(8)}"
)

qa4 = QuestionAnswer.create!(
  organization: acme_corp,
  document: docs[1],
  question: "What are the API rate limits?",
  answer: "API requests are limited to 1000 requests per hour for authenticated requests and 60 requests per hour for unauthenticated requests. Rate limit information is included in response headers: X-RateLimit-Limit, X-RateLimit-Remaining, and X-RateLimit-Reset.",
  context: "API requests are limited to: 1000 requests per hour for authenticated requests, 60 requests per hour for unauthenticated requests. Rate limit information is included in response headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset",
  confidence_score: 0.96,
  pinecone_id: "qa_#{acme_corp.id}_#{SecureRandom.hex(8)}"
)

# For Troubleshooting Guide
qa5 = QuestionAnswer.create!(
  organization: demo_org,
  document: docs[5],
  question: "What should I do if the application won't start?",
  answer: "Check if port 3000 is already in use with 'lsof -i :3000', verify the database is running with 'pg_isready', ensure environment variables are set correctly, and run database migrations with 'rails db:migrate'.",
  context: "Application Won't Start - Solutions: Check if port 3000 is already in use: lsof -i :3000, Verify database is running: pg_isready, Check environment variables are set correctly, Run database migrations: rails db:migrate",
  confidence_score: 0.94,
  pinecone_id: "qa_#{demo_org.id}_#{SecureRandom.hex(8)}"
)

# Print summary
puts "\nSeeding completed!"
puts "=" * 50
puts "Organizations created: #{Organization.count}"
puts "Sources created: #{Source.count}"
puts "Documents created: #{Document.count}"
puts "Document chunks created: #{DocumentChunk.count}"
puts "Question/Answer pairs created: #{QuestionAnswer.count}"
puts "=" * 50

# Print some example queries to try
puts "\nExample queries to try in rails console:"
puts "  Organization.find_by(subdomain: 'acme-corp')"
puts "  Source.active.count"
puts "  Document.processed.count"
puts "  DocumentChunk.with_embeddings.count"
puts "  QuestionAnswer.high_confidence.count"