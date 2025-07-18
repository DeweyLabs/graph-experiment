namespace :experiment do
  desc "Run search efficiency benchmark comparing O(N) vs O(E+T) approaches"
  task :search_efficiency, [:doc_count, :question_count] => :environment do |task, args|
    doc_count = (args[:doc_count] || 100).to_i
    question_count = (args[:question_count] || 100).to_i
    
    puts "🧪 Search Efficiency Experiment"
    puts "=" * 50
    puts "Dataset: #{doc_count} documents, #{question_count} questions"
    puts "Comparing Traditional O(N) vs Graph O(E+T) search"
    puts ""
    
    # Setup test organization
    org = Organization.find_or_create_by(name: "Experiment Org") do |o|
      o.subdomain = "experiment-#{SecureRandom.hex(4)}"
    end
    
    source = Source.find_or_create_by(organization: org, name: "Test Source") do |s|
      s.adapter_type = "github"
      s.status = "active"
      s.config = { api_key: "test_key_#{SecureRandom.hex(8)}" }
      s.sync_state = {}
    end
    
    # Clear existing data
    puts "🧹 Clearing existing test data..."
    org.clear_graph_data!
    org.documents.destroy_all
    org.question_answers.destroy_all
    
    # Entity and topic pools for realistic relationships
    entities = [
      "Ruby on Rails", "PostgreSQL", "Neo4j", "ActiveRecord", "ActiveGraph",
      "API", "REST", "GraphQL", "Authentication", "Authorization",
      "Docker", "Kubernetes", "AWS", "Redis", "Sidekiq",
      "React", "JavaScript", "HTML", "CSS", "Bootstrap",
      "Testing", "RSpec", "Capybara", "FactoryBot", "CI/CD",
      "Git", "GitHub", "Code Review", "Deployment", "DevOps",
      "Security", "Encryption", "SSL", "HTTPS", "OAuth",
      "Performance", "Optimization", "Caching", "Monitoring", "Logging",
      "Machine Learning", "AI", "Embeddings", "Vector Search", "RAG"
    ]
    
    topics = [
      "Web Development", "Backend Development", "Frontend Development",
      "Database Design", "API Design", "System Architecture",
      "DevOps", "Security", "Performance", "Testing",
      "Machine Learning", "Data Science", "Cloud Computing",
      "Software Engineering", "Project Management", "Documentation"
    ]
    
    # Generate test data
    puts "📝 Generating #{doc_count} documents..."
    documents = []
    doc_count.times do |i|
      doc = Document.create!(
        organization: org,
        source: source,
        external_id: "doc_#{i}",
        title: "Document #{i}: #{Faker::Lorem.words(number: 3).join(' ').titleize}",
        content: Faker::Lorem.paragraphs(number: 3).join("\n\n"),
        embedding_status: "completed"
      )
      
      # Create graph node and add realistic relationships
      doc.create_or_update_graph_node
      
      # Add 3-8 entities per document with some overlap
      doc_entities = entities.sample(rand(3..8))
      doc.sync_entities_to_graph(doc_entities)
      
      # Add 1-3 topics per document with some overlap  
      doc_topics = topics.sample(rand(1..3))
      doc.sync_topics_to_graph(doc_topics)
      
      documents << doc
      
      print "." if i % 10 == 0
    end
    puts ""
    
    puts "❓ Generating #{question_count} questions..."
    questions = []
    question_count.times do |i|
      qa = QuestionAnswer.create!(
        organization: org,
        question: "Question #{i}: #{Faker::Lorem.question}",
        answer: Faker::Lorem.paragraphs(number: 2).join("\n\n"),
        confidence_score: rand(0.7..0.95)
      )
      
      # Create graph node and add relationships
      qa.create_or_update_graph_node
      
      # Add overlapping entities/topics to create realistic connections
      qa_entities = entities.sample(rand(2..6))
      qa.sync_entities_to_graph(qa_entities)
      
      qa_topics = topics.sample(rand(1..3))
      qa.sync_topics_to_graph(qa_topics)
      
      questions << qa
      
      print "." if i % 10 == 0
    end
    puts ""
    
    # Run traditional O(N) simulation
    puts "🐌 Simulating Traditional O(N) Approach..."
    traditional_start = Time.current
    traditional_operations = 0
    traditional_matches = []
    
    # For each document, check against all questions
    documents.each do |doc|
      questions.each do |qa|
        traditional_operations += 1
        
        # Simulate similarity calculation (we'll use entity overlap as proxy)
        doc_entities = doc.graph_node&.entities&.pluck(:name) || []
        qa_entities = qa.graph_node&.entities&.pluck(:name) || []
        shared_entities = doc_entities & qa_entities
        
        # Consider it a match if they share 2+ entities
        if shared_entities.length >= 2
          traditional_matches << [doc.id, qa.id]
        end
      end
    end
    traditional_time = Time.current - traditional_start
    
    puts "   Operations: #{traditional_operations.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "   Matches found: #{traditional_matches.length}"
    puts "   Time: #{traditional_time.round(3)}s"
    puts ""
    
    # Run graph O(E+T) approach
    puts "🚀 Running Graph O(E+T) Approach..."
    graph_start = Time.current
    graph_operations = 0
    graph_matches = []
    
    documents.each do |doc|
      next unless doc.graph_node
      
      # Count traversal operations
      entity_count = doc.graph_node.entities.count
      topic_count = doc.graph_node.topics.count
      graph_operations += entity_count + topic_count
      
      # Find affected questions via graph
      affected_question_nodes = doc.graph_node&.affected_questions || []
      
      affected_question_nodes.each do |qa_node|
        # qa_node is a QuestionNode, convert to QuestionAnswer using global_id
        if qa_node.global_id && qa_node.global_id.include?('QuestionAnswer/')
          qa_id = qa_node.global_id.split('/').last.to_i
          if qa = QuestionAnswer.find_by(id: qa_id)
            # Verify it's a real match (2+ shared entities)
            doc_entities = doc.graph_node.entities.pluck(:name)
            qa_entities = qa_node.entities.pluck(:name)
            shared_entities = doc_entities & qa_entities
            
            if shared_entities.length >= 2
              graph_matches << [doc.id, qa.id]
            end
          end
        end
      end
    end
    graph_time = Time.current - graph_start
    
    puts "   Operations: #{graph_operations.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "   Matches found: #{graph_matches.length}"  
    puts "   Time: #{graph_time.round(3)}s"
    puts ""
    
    # Calculate results
    speedup = traditional_operations.to_f / graph_operations
    time_speedup = traditional_time / graph_time
    efficiency_gain = ((traditional_operations - graph_operations).to_f / traditional_operations * 100)
    
    # Verify accuracy
    traditional_set = Set.new(traditional_matches)
    graph_set = Set.new(graph_matches)
    accuracy = if traditional_matches.empty?
      100.0
    else
      (traditional_set & graph_set).size.to_f / traditional_set.size * 100
    end
    
    puts "📊 RESULTS"
    puts "=" * 50
    puts "Traditional O(N):   #{traditional_operations.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} operations in #{traditional_time.round(3)}s"
    puts "Graph O(E+T):       #{graph_operations.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} operations in #{graph_time.round(3)}s"
    puts ""
    puts "🚀 PERFORMANCE GAINS:"
    puts "   Operation Reduction: #{speedup.round(1)}x (#{efficiency_gain.round(2)}% fewer operations)"
    puts "   Time Speedup:        #{time_speedup.round(1)}x faster"
    puts "   Accuracy:            #{accuracy.round(1)}% (#{(traditional_set & graph_set).size}/#{traditional_set.size} matches)"
    puts ""
    
    # Scaling projections
    puts "📈 SCALING PROJECTIONS:"
    [1_000, 10_000, 100_000, 1_000_000].each do |scale|
      traditional_ops = scale * scale
      graph_ops = graph_operations * (scale.to_f / doc_count)
      projected_speedup = traditional_ops / graph_ops
      
      puts "   #{scale.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse.rjust(8)} docs: #{projected_speedup.round(0).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}x speedup"
    end
    puts ""
    
    # Graph statistics
    puts "📋 GRAPH STATISTICS:"
    stats = org.graph_statistics
    puts "   Document nodes: #{stats[:document_nodes]}"
    puts "   Question nodes: #{stats[:question_nodes]}"
    puts "   Entity nodes:   #{stats[:entities]}"
    puts "   Topic nodes:    #{stats[:topics]}"
    puts "   Total nodes:    #{stats.values.sum}"
    puts ""
    
    puts "✅ Experiment completed successfully!"
    puts "   Run with different sizes: rails experiment:search_efficiency[1000,1000]"
    
    # Cleanup
    puts "🧹 Cleaning up test data..."
    org.clear_graph_data!
    org.documents.destroy_all
    org.question_answers.destroy_all
    org.sources.destroy_all
    org.destroy!
  end
  
  desc "Quick performance test with small dataset"
  task :quick_test => :environment do
    Rake::Task["experiment:search_efficiency"].invoke("10", "10")
  end
  
  desc "Medium performance test" 
  task :medium_test => :environment do
    Rake::Task["experiment:search_efficiency"].invoke("100", "100")
  end
  
  desc "Large performance test"
  task :large_test => :environment do
    Rake::Task["experiment:search_efficiency"].invoke("1000", "1000")
  end
end