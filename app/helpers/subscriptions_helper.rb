module SubscriptionsHelper
  def subscription_period_end_action(subscription)
    if subscription.to_be_canceled?
      "Your Fizzy subscription ends on"
    elsif subscription.canceled?
      "Your Fizzy subscription ended on"
    else
      "Your next payment of <b>$#{ subscription.plan.price }</b> will be billed on".html_safe
    end
  end
end
