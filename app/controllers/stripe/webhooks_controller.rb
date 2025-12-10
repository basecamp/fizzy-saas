class Stripe::WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_account
  skip_before_action :verify_authenticity_token

  def create
    event = verify_webhook_signature
    return head :bad_request unless event

    dispatch_stripe_event(event)

    head :ok
  end

  private
    def dispatch_stripe_event(event)
      case event.type
        when "checkout.session.completed"
          handle_checkout_completed(event.data.object)
        when "customer.subscription.updated"
          handle_subscription_updated(event.data.object)
        when "customer.subscription.deleted"
          handle_subscription_deleted(event.data.object)
        when "invoice.payment_failed"
          handle_payment_failed(event.data.object)
      end
    end

    def verify_webhook_signature
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      Stripe::Webhook.construct_event(payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"])
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe webhook signature verification failed: #{e.message}"
      nil
    end

    def handle_checkout_completed(session)
      return unless session.mode == "subscription"

      subscription = find_subscription_by_customer(session.customer)
      return unless subscription

      stripe_subscription = Stripe::Subscription.retrieve(session.subscription)

      subscription.update! \
        stripe_subscription_id: stripe_subscription.id,
        plan_key: session.metadata["plan_key"],
        status: stripe_subscription.status,
        current_period_end: extract_current_period_end(stripe_subscription)
    end

    def handle_subscription_updated(stripe_subscription)
      if subscription = find_subscription_by_customer(stripe_subscription.customer)
        subscription.update! \
          status: stripe_subscription.status,
          current_period_end: extract_current_period_end(stripe_subscription),
          cancel_at: stripe_subscription.cancel_at ? Time.at(stripe_subscription.cancel_at) : nil
      end
    end

    def handle_subscription_deleted(stripe_subscription)
      if subscription = find_subscription_by_customer(stripe_subscription.customer)
        subscription.update!(status: "canceled", stripe_subscription_id: nil)
      end
    end

    def handle_payment_failed(invoice)
      if subscription = find_subscription_by_customer(invoice.customer)
        subscription.update!(status: "past_due")
      end
    end

    def find_subscription_by_customer(customer_id)
      Account::Subscription.find_by(stripe_customer_id: customer_id)
    end

    def extract_current_period_end(stripe_subscription)
      timestamp = stripe_subscription.items.data.first&.current_period_end
      Time.at(timestamp) if timestamp
    end
end
