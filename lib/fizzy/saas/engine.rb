require_relative "transaction_pinning"
require_relative "signup"

module Fizzy
  module Saas
    class Engine < ::Rails::Engine
      # moved from config/initializers/queenbee.rb
      Queenbee.host_app = Fizzy

      initializer "fizzy.saas.mount" do |app|
        app.routes.append do
          mount Fizzy::Saas::Engine => "/", as: "saas"
        end
      end

      initializer "fizzy_saas.transaction_pinning" do |app|
        app.config.middleware.insert_after(ActiveRecord::Middleware::DatabaseSelector, TransactionPinning::Middleware)
      end

      initializer "fizzy_saas.solid_queue" do
        SolidQueue.on_start do
          Process.warmup
          Yabeda::Prometheus::Exporter.start_metrics_server!
        end
      end

      initializer "fizzy_saas.logging.session" do |app|
        ActiveSupport.on_load(:action_controller_base) do
          before_action do
            if Current.identity.present?
              logger.struct(authentication: { identity: { id: Current.identity.id } })
            end

            if Current.account.present?
              logger.struct(account: { queenbee_id: Current.account.external_account_id })
            end
          end
        end
      end

      # Load test mocks automatically in test environment
      initializer "fizzy_saas.test_mocks", after: :load_config_initializers do
        if Rails.env.test?
          require "fizzy/saas/testing"
        end
      end

      initializer "fizzy_saas.sentry" do
        if !Rails.env.local? && ENV["SKIP_TELEMETRY"].blank?
          Sentry.init do |config|
            config.dsn = ENV["SENTRY_DSN"]
            config.breadcrumbs_logger = %i[ active_support_logger http_logger ]
            config.send_default_pii = false
            config.release = ENV["GIT_REVISION"]
            config.excluded_exceptions += [ "ActiveRecord::ConcurrentMigrationError" ]
          end
        end
      end

      initializer "fizzy_saas.yabeda" do
        require "prometheus/client/support/puma"

        Prometheus::Client.configuration.logger = Rails.logger
        Prometheus::Client.configuration.pid_provider = Prometheus::Client::Support::Puma.method(:worker_pid_provider)
        Yabeda::Rails.config.controller_name_case = :camel
        Yabeda::Rails.config.ignore_actions = %w[
          Rails::HealthController#show
        ]

        Yabeda::ActiveJob.install!

        require "yabeda/solid_queue"
        Yabeda::SolidQueue.install!

        Yabeda::ActionCable.configure do |config|
          config.channel_class_name = "ActionCable::Channel::Base"
        end

        require_relative "metrics"
      end

      config.to_prepare do
        ::Signup.prepend(Fizzy::Saas::Signup)

        Queenbee::Subscription.short_names = Subscription::SHORT_NAMES

        # Default to local dev QB token if not set
        Queenbee::ApiToken.token = ENV.fetch("QUEENBEE_API_TOKEN") { "69a4cfb8705913e6323f7b4c0c0cff9bd8df37da532f4375b85e9655b8100bb023591b48d308205092aa0a04dd28cb6c62d6798364a6f44cc1e675814eb148a1" } # gitleaks:allow development-only token

        Subscription::SHORT_NAMES.each do |short_name|
          const_name = "#{short_name}Subscription"
          ::Object.send(:remove_const, const_name) if ::Object.const_defined?(const_name)
          ::Object.const_set const_name, Subscription.const_get(short_name, false)
        end
      end
    end
  end
end
