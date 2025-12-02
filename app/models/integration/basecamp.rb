class Integration::Basecamp < Integration
  AUTH_URL_STATE_EXPIRATION = 30.minutes
  AUTH_URL_STATE_PURPOSE = "setup-basecamp-integration".freeze

  store_accessor :data, :access_token, :refresh_token

  class << self
    def set_up_later(code:, state:)
      if locate_by_state(state)
        Integration::Basecamp::SetUpJob.perform_later(code: code, state: state)
      end
    end

    def set_up(code:, state:)
      with_tenant_from_state(state) do
        integration = locate_by_state(state)
        integration.set_up(code) unless integration.setup?
      end
    end

    private
      def locate_by_state(state)
        GlobalID::Locator.locate_signed(state, for: AUTH_URL_STATE_PURPOSE)
      end

      def with_tenant_from_state(state, &block)
        sgid = SignedGlobalID.parse(state, for: AUTH_URL_STATE_PURPOSE)
        with_tenant(sgid.tenant, &block)
      end
  end

  def authorization_url
    oauth_client
      .auth_code
      .authorize_url(
        redirect_uri: return_url,
        state: as_state
      )
      .sub("response_type=code", "type=web_server")
  end

  def set_up(authorization_code)
    access_token = oauth_client.auth_code.get_token(authorization_code, token_method: :post, redirect_uri: return_url, type: :web_server)

    self.access_token = access_token.token
    self.refresh_token = access_token.refresh_token

    save!
  end

  def setup?
    access_token.present? && refresh_token.present?
  end

  def refresh_tokens
    if refresh_token.present?
      response = oauth_client.request(
        :post,
        "/authorization/token",
        body: {
          refresh_token: refresh_token,
          type: "refresh",
          client_id: credentials[:client_id],
          client_secret: credentials[:client_secret]
        }
      ).parsed

      self.access_token = response["access_token"]

      save!
    end
  end

  private
    def oauth_client
      @oauth_client ||= OAuth2::Client.new(
        credentials[:client_id],
        credentials[:client_secret],
        site: credentials[:oauth_server_url],
        authorize_url: "/authorization/new",
        token_url: "/authorization/token",
        auth_scheme: :request_body
      )
    end

    def credentials
      Rails.application.credentials.integrations.basecamp
    end

    def return_url
      options = Rails.application.config.action_controller.default_url_options.merge(script_name: nil)
      Rails.application.routes.url_helpers.basecamp_integration_callback_url(**options)
    end

    def as_state
      to_sgid(expires_in: AUTH_URL_STATE_EXPIRATION, for: AUTH_URL_STATE_PURPOSE).to_s
    end
end
