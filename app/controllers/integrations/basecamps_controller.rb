class Integrations::BasecampsController < ApplicationController
  def new
  end

  def create
    integration = Integration::Basecamp.find_or_create_by(owner: Current.user)

    unless integration.setup?
      redirect_to integration.authorization_url, allow_other_host: true
    end
  end
end
