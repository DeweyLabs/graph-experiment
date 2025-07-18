FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    subdomain { Faker::Internet.domain_word.downcase }
    settings { {} }
    plan { "free" }
    status { "active" }

    trait :with_pro_plan do
      plan { "professional" }
    end

    trait :suspended do
      status { "suspended" }
    end

    trait :with_sources do
      after(:create) do |org|
        create_list(:source, 2, organization: org)
      end
    end
  end
end
