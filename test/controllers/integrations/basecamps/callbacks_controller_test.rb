require "test_helper"

class Integrations::Basecamps::CallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_url_options = Rails.application.config.action_controller.default_url_options
    Rails.application.config.action_controller.default_url_options = { host: "example.com" }
  end

  teardown do
    Rails.application.config.action_controller.default_url_options = @original_url_options
  end

  test "show enqueues job to set up integration" do
    integration = integrations(:kevins_basecamp)
    integration.update!(data: {})

    state = integration.to_sgid(
      expires_in: Integration::Basecamp::AUTH_URL_STATE_EXPIRATION,
      for: Integration::Basecamp::AUTH_URL_STATE_PURPOSE
    ).to_s

    assert_enqueued_with(job: Integration::Basecamp::SetUpJob, args: [ { code: "test_code", state: state } ]) do
      get basecamp_integration_callback_path, params: { code: "test_code", state: state }
    end

    assert_response :success
  end
end
