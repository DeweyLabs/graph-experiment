FactoryBot.define do
  factory :source do
    organization
    name { "#{Faker::Company.name} #{adapter_type.humanize}" }
    adapter_type { %w[google_drive dropbox notion slack github confluence].sample }
    config { {api_key: Faker::Alphanumeric.alphanumeric(number: 32)} }
    status { "active" }
    last_sync_at { nil }
    sync_state { {} }

    trait :with_error do
      status { "error" }
      sync_state { {error: "API rate limit exceeded", failed_at: 1.hour.ago} }
    end

    trait :syncing do
      sync_state { {in_progress: true, started_at: 5.minutes.ago} }
    end

    trait :recently_synced do
      last_sync_at { 30.minutes.ago }
      sync_state { {in_progress: false, completed_at: 30.minutes.ago} }
    end

    trait :with_documents do
      after(:create) do |source|
        create_list(:document, 3, source: source, organization: source.organization)
      end
    end
  end
end
