FactoryBot.define do
  factory :question_answer do
    organization { nil }
    document { nil }
    question { "MyText" }
    answer { "MyText" }
    context { "MyText" }
    confidence_score { 1.5 }
    metadata { "" }
    pinecone_id { "MyString" }
  end
end
