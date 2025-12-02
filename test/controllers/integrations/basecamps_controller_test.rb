require "test_helper"

class Integrations::BasecampsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
    @original_url_options = Rails.application.config.action_controller.default_url_options
    Rails.application.config.action_controller.default_url_options = { host: "example.com" }
  end

  teardown do
    Rails.application.config.action_controller.default_url_options = @original_url_options
  end

  test "new" do
    get new_basecamp_integration_path
    assert_response :success
  end

  test "create" do
    sign_in_as :kevin

    assert_no_difference "Integration::Basecamp.count" do
      post basecamp_integration_path
    end

    assert_response :success, "Renders the 'integration already setup' screen"

    users(:kevin).integrations.delete_all

    assert_difference "Integration::Basecamp.count", 1 do
      post basecamp_integration_path
    end

    integration = Integration::Basecamp.last
    assert_equal users(:kevin), integration.owner
    assert_response :redirect, "Redirects to launchpad"
    assert_match %r{launchpad\.localhost:3011/authorization/new}, response.redirect_url
  end
end
