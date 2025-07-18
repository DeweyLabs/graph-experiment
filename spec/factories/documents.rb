FactoryBot.define do
  factory :document do
    source
    organization { source&.organization || build(:organization) }
    external_id { Faker::Alphanumeric.alphanumeric(number: 16) }
    title { Faker::Book.title }
    content { Faker::Lorem.paragraphs(number: 5).join("\n\n") }
    metadata { {author: Faker::Book.author, created_at: 1.week.ago} }
    embedding_status { "pending" }
    chunk_count { 0 }
    processed_at { nil }

    trait :processed do
      embedding_status { "completed" }
      processed_at { 1.hour.ago }
      chunk_count { 5 }

      after(:create) do |document|
        create_list(:document_chunk, 5, document: document, organization: document.organization)
      end
    end

    trait :processing do
      embedding_status { "processing" }
    end

    trait :failed do
      embedding_status { "failed" }
      metadata { {error: "Failed to generate embeddings"} }
    end

    trait :with_long_content do
      content { Faker::Lorem.paragraphs(number: 50).join("\n\n") }
    end
  end
end
