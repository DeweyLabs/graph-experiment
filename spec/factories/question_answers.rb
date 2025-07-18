FactoryBot.define do
  factory :question_answer do
    organization
    document { build(:document, organization: organization) }
    question { "#{Faker::Lorem.question} about #{document&.title || "this topic"}?" }
    answer { Faker::Lorem.paragraph(sentence_count: 5) }
    context { Faker::Lorem.paragraph(sentence_count: 3) }
    confidence_score { rand(0.5..1.0).round(2) }
    metadata { {} }
    pinecone_id { nil }
    source_type { "document" }

    trait :high_confidence do
      confidence_score { rand(0.85..0.95).round(2) }
    end

    trait :low_confidence do
      confidence_score { rand(0.3..0.5).round(2) }
    end

    trait :with_pinecone do
      pinecone_id { "qa_#{organization.id}_#{SecureRandom.hex(8)}" }
    end

    trait :with_source_chunks do
      metadata do
        {
          source_chunks: ["chunk_1", "chunk_2", "chunk_3"],
          search_scores: [0.95, 0.89, 0.82]
        }
      end
    end

    trait :from_query do
      document { nil }
      source_type { "query" }
      question { Faker::Lorem.question }
      metadata do
        {
          user_id: SecureRandom.uuid,
          session_id: SecureRandom.hex(16),
          query_timestamp: Time.current.iso8601
        }
      end
    end

    trait :from_chat do
      document { nil }
      source_type { "chat" }
      question { Faker::Lorem.question }
      metadata do
        {
          conversation_id: SecureRandom.uuid,
          message_count: rand(1..20),
          chat_timestamp: Time.current.iso8601
        }
      end
    end
  end
end
