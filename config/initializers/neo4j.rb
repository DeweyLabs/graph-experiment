# ActiveGraph Configuration for Neo4j
require "active_graph"

# Configure ActiveGraph for Neo4j
ActiveGraph::Base.on_establish_driver do
  # Default to local Neo4j instance
  scheme = ENV.fetch("NEO4J_SCHEME", "bolt")
  host = ENV.fetch("NEO4J_HOST", "localhost")
  port = ENV.fetch("NEO4J_PORT", "7687").to_i
  username = ENV.fetch("NEO4J_USERNAME", "neo4j")
  password = ENV.fetch("NEO4J_PASSWORD", "password")

  url = URI::Generic.build(scheme: scheme, host: host, port: port).to_s
  auth_token = Neo4j::Driver::AuthTokens.basic(username, password)

  Neo4j::Driver::GraphDatabase.driver(url, auth_token)
end

# Disable schema validation completely for now
ActiveGraph::Config[:fail_on_pending_migrations] = false

Rails.logger&.info "ActiveGraph configured for Neo4j"
