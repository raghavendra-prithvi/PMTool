# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include SessionsHelper
    def require_user
      @@user_id = cookies.signed[:remember_token]
      unless @@user_id
        flash[:notice] = "You must be logged in to access this page"
        redirect_to login_path
        return false
      end
    end
end

