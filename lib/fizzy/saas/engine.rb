require_relative "metrics"
require_relative "transaction_pinning"

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

      # Load test mocks automatically in test environment
      initializer "fizzy_saas.test_mocks", after: :load_config_initializers do
        if Rails.env.test?
          require "fizzy/saas/testing"
        end
      end

      initializer "fizzy_saas.logging.queenbee_id" do |app|
        ActiveSupport.on_load(:action_controller_base) do
          before_action do
            if Current.account.present?
              logger.struct(account: { queenbee_id: Current.account.external_account_id })
            end
          end
        end
      end

      config.to_prepare do
        Queenbee::Subscription.short_names = Subscription::SHORT_NAMES

        # Default to dev QB token if not set
        Queenbee::ApiToken.token = ENV.fetch("QUEENBEE_API_TOKEN") { "69a4cfb8705913e6323f7b4c0c0cff9bd8df37da532f4375b85e9655b8100bb023591b48d308205092aa0a04dd28cb6c62d6798364a6f44cc1e675814eb148a1" }

        Subscription::SHORT_NAMES.each do |short_name|
          const_name = "#{short_name}Subscription"
          ::Object.send(:remove_const, const_name) if ::Object.const_defined?(const_name)
          ::Object.const_set const_name, Subscription.const_get(short_name, false)
        end
      end
    end
  end
end
