require "test_helper"

class Integration::BasecampTest < ActiveSupport::TestCase
  setup do
    @integration = integrations(:kevins_basecamp)
    @original_url_options = Rails.application.config.action_controller.default_url_options
    Rails.application.config.action_controller.default_url_options = { host: "example.com" }
  end

  teardown do
    Rails.application.config.action_controller.default_url_options = @original_url_options
  end

  test "setup?" do
    assert @integration.setup?

    @integration.access_token = nil
    @integration.refresh_token = nil

    assert_not @integration.setup?
  end

  test "authorization_url" do
    url = @integration.authorization_url

    assert_match %r{launchpad\.localhost:3011/authorization/new}, url
    assert_match(/client_id=/, url)
    assert_match(/redirect_uri=/, url)
    assert_match(/state=/, url)
    assert_match(/type=web_server/, url)
  end

  test "refresh_tokens" do
    credentials = Rails.application.credentials.integrations.basecamp

    stub_request(:post, "#{credentials[:oauth_server_url]}/authorization/token")
      .to_return(
        status: 200,
        body: { access_token: "refreshed_access_token" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    @integration.refresh_tokens

    assert_equal "refreshed_access_token", @integration.access_token

    @integration.update!(data: { access_token: "original_token" })
    @integration.refresh_tokens
    assert_equal "original_token", @integration.reload.access_token
  end

  test "set_up_later" do
    state = @integration.to_sgid(
      expires_in: Integration::Basecamp::AUTH_URL_STATE_EXPIRATION,
      for: Integration::Basecamp::AUTH_URL_STATE_PURPOSE
    ).to_s

    assert_enqueued_with(job: Integration::Basecamp::SetUpJob, args: [ { code: "code", state: state } ]) do
      Integration::Basecamp.set_up_later(code: "code", state: state)
    end
  end

  test "set_up" do
    @integration.update!(data: {})
    credentials = Rails.application.credentials.integrations.basecamp

    state = @integration.to_sgid(
      expires_in: Integration::Basecamp::AUTH_URL_STATE_EXPIRATION,
      for: Integration::Basecamp::AUTH_URL_STATE_PURPOSE
    ).to_s

    stub_request(:post, "#{credentials[:oauth_server_url]}/authorization/token")
      .to_return(
        status: 200,
        body: {
          access_token: "new_access_token",
          refresh_token: "new_refresh_token"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    Integration::Basecamp.set_up(code: "code", state: state)

    assert @integration.reload.setup?
    assert_equal "new_access_token", @integration.access_token
    assert_equal "new_refresh_token", @integration.refresh_token

    state = @integration.to_sgid(
      expires_in: Integration::Basecamp::AUTH_URL_STATE_EXPIRATION,
      for: Integration::Basecamp::AUTH_URL_STATE_PURPOSE
    ).to_s

    original_access_token = @integration.access_token

    Integration::Basecamp.set_up(code: "code", state: state)

    assert_equal original_access_token, @integration.reload.access_token, "Set up is skipped if the integration already is setup"
  end
end
