class ApplicationInteraction < ActiveInteraction::Base
  # Common interaction functionality

  # Organization context
  object :organization, class: Organization, default: nil

  # Helper method to scope queries to organization
  def organization_scope(model_class)
    return model_class.none unless organization
    model_class.where(organization: organization)
  end

  # Common error handling
  def handle_api_error(error, service_name)
    errors.add(:base, "#{service_name} error: #{error.message}")
    Rails.logger.error("#{service_name} API Error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if error.backtrace
  end
end
