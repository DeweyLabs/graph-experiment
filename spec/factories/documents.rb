FactoryBot.define do
  factory :document do
    source { nil }
    organization { nil }
    external_id { "MyString" }
    title { "MyString" }
    content { "MyText" }
    metadata { "" }
    embedding_status { "MyString" }
    chunk_count { 1 }
    processed_at { "2025-07-18 09:59:26" }
  end
end
