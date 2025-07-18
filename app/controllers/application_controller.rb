class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :set_current_organization
  
  private
  
  def set_current_organization
    # This is a placeholder - in a real app, you'd get this from:
    # - subdomain (current_organization = Organization.find_by(subdomain: request.subdomain))
    # - authenticated user (current_organization = current_user.organization)
    # - API token (current_organization = api_token.organization)
    # For now, we'll use a session-based approach
    
    @current_organization = if session[:organization_id].present?
      Organization.find_by(id: session[:organization_id])
    end
  end
  
  def current_organization
    @current_organization
  end
  helper_method :current_organization
  
  def require_organization!
    redirect_to root_path, alert: "Please select an organization" unless current_organization
  end
end
