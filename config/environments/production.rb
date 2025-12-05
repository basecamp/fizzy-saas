Rails.application.configure do
  config.active_storage.service = :purestorage
  config.structured_logging.logger = ActiveSupport::Logger.new(STDOUT)

  config.action_controller.default_url_options = { host: "app.fizzy.do", protocol: "https" }
  config.action_mailer.default_url_options     = { host: "app.fizzy.do", protocol: "https" }
  config.action_mailer.smtp_settings = { domain: "app.fizzy.do", address: "smtp-outbound", port: 25, enable_starttls_auto: false }

  # Content Security Policy: report-only mode, to Sentry
  config.x.content_security_policy.report_only = true
  config.x.content_security_policy.report_uri = "https://o33603.ingest.us.sentry.io/api/4510481339187200/security/?sentry_key=9f126ba30d5f703451a13a2929bb5a10"
end
