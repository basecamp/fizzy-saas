class Link::BasecampUnfurler < Link::OpenGraphUnfurler
  class MissingIntegrationError < StandardError; end

  def self.unfurls?(uri)
    uri.host.ends_with?(".basecamp.com") || uri.host.ends_with?(".basecamp.localhost")
  rescue URI::InvalidURIError
    false
  end

  def unfurl
    if integration.present?
      fetch_metadata
    else
      raise MissingIntegrationError
    end
  end

  private
    def fetch_metadata
      retrying = false

      begin
        fetch = Link::Fetch.new(uri, headers: headers)

        if fetch.http_url? && fetch.html_content?
          document = Nokogiri::HTML5(fetch.content)
          Link::Metadata.new(**extract_metadata_from_document(document))
        end
      rescue Link::Fetch::UnsuccesfulRequestError => e
        if retrying
          raise
        elsif e.response.is_a?(Net::HTTPUnauthorized)
          integration.refresh_tokens
          retrying = true
          retry
        end
      end
    end

    def headers
      { "Authorization" => "Bearer #{integration.access_token}" }
    end

    def integration
      @integration ||= begin
        integration = user.integrations.with_basecamp
        raise(MissingIntegrationError) if integration.nil? || !integration.setup?
        integration
      end
    end
end
