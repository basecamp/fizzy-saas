require "test_helper"

class Link::BasecampUnfurlerTest < ActiveSupport::TestCase
  test "unfurls?" do
    assert Link::BasecampUnfurler.unfurls?(URI.parse("https://3.basecamp.com/123/projects/456"))
    assert Link::BasecampUnfurler.unfurls?(URI.parse("https://classic.basecamp.com/999/todos/123"))
    assert Link::BasecampUnfurler.unfurls?(URI.parse("https://3.basecamp.localhost:3001/test"))

    assert_not Link::BasecampUnfurler.unfurls?(URI.parse("https://example.com/page"))
    assert_not Link::BasecampUnfurler.unfurls?(URI.parse("https://notbasecamp.com/page"))
  end

  test "unfurl" do
    url = "https://3.basecamp.com/123/projects/456"
    user_with_basecamp_integration = users(:kevin)
    integration = user_with_basecamp_integration.integrations.with_basecamp
    user_without_basecamp_integration = users(:jz)

    stub_request(:head, url)
      .with(headers: { "Authorization" => "Bearer #{integration.access_token}" })
      .to_return(status: 200, headers: { "Content-Type" => "text/html" })

    stub_request(:get, url)
      .with(headers: { "Authorization" => "Bearer #{integration.access_token}" })
      .to_return(status: 200, body: <<~HTML)
        <html>
          <head>
            <title>Basecamp Project</title>
          </head>
        </html>
      HTML

    metadata = Link::BasecampUnfurler.new(URI.parse(url), user: user_with_basecamp_integration).unfurl

    assert_equal "Basecamp Project", metadata.title

    assert_raises(Link::BasecampUnfurler::MissingIntegrationError) do
      Link::BasecampUnfurler.new(URI.parse(url), user: user_without_basecamp_integration).unfurl
    end
  end

  test "unfurl with an expired access token" do
    url = "https://3.basecamp.com/123/projects/456"
    user = users(:kevin)
    integration = user.integrations.with_basecamp
    original_token = integration.access_token

    stub_request(:head, url)
      .with(headers: { "Authorization" => "Bearer #{original_token}" })
      .to_return(status: 401)

    stub_request(:head, url)
      .with(headers: { "Authorization" => "Bearer refreshed_token" })
      .to_return(status: 200, headers: { "Content-Type" => "text/html" })

    stub_request(:get, url)
      .with(headers: { "Authorization" => "Bearer refreshed_token" })
      .to_return(status: 200, body: <<~HTML)
        <html>
          <head>
            <title>Refreshed Access</title>
          </head>
        </html>
      HTML

    Integration::Basecamp.any_instance.expects(:refresh_tokens).once.with do |a|
      Integration::Basecamp.any_instance.stubs(:access_token).returns("refreshed_token")
      true
    end

    metadata = Link::BasecampUnfurler.new(URI.parse(url), user: user).unfurl

    assert_equal "Refreshed Access", metadata.title
  end
end
