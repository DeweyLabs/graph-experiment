FactoryBot.define do
  factory :document_chunk do
    document
    organization { document&.organization || build(:organization) }
    content { Faker::Lorem.paragraph(sentence_count: 10) }
    sequence(:chunk_index) { |n| n }
    embedding { nil }
    pinecone_id { nil }
    metadata { {} }

    trait :with_embedding do
      embedding { Array.new(1536) { rand(-1.0..1.0) }.to_json }
      pinecone_id { "#{organization.id}_#{document.id}_#{chunk_index}" }
    end

    trait :with_metadata do
      metadata do
        {
          start_position: chunk_index * 1000,
          end_position: (chunk_index + 1) * 1000,
          length: content.length
        }
      end
    end
  end
end
