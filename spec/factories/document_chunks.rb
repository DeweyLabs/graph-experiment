FactoryBot.define do
  factory :document_chunk do
    document { nil }
    organization { nil }
    content { "MyText" }
    chunk_index { 1 }
    embedding { "MyText" }
    pinecone_id { "MyString" }
    metadata { "" }
  end
end
