require "test_helper"

class Account::BillingTest < ActiveSupport::TestCase
  test "active subscription" do
    account = Account.create!(name: "Test")

    # No subscription
    assert_nil account.active_subscription

    # Subscription but it is not active
    account.create_subscription!(plan_key: "monthly_v1", status: "canceled", stripe_customer_id: "cus_test")
    assert_nil account.active_subscription

    # Active subscription exists
    account.subscription.update!(status: "active")
    assert_equal account.subscription, account.active_subscription
  end

  test "detect nearing card limit" do
    # Paid plans are never limited
    accounts(:"37s").update_column(:cards_count, 1_000_000)
    assert_not accounts(:"37s").nearing_plan_cards_limit?

    # Free plan not near limit
    accounts(:initech).update_column(:cards_count, 899)
    assert_not accounts(:initech).nearing_plan_cards_limit?

    # Free plan near limit
    accounts(:initech).update_column(:cards_count, 900)
    assert_not accounts(:initech).nearing_plan_cards_limit?

    accounts(:initech).update_column(:cards_count, 901)
    assert accounts(:initech).nearing_plan_cards_limit?
  end

  test "detect exceeding card limit" do
    # Paid plans are never limited
    accounts(:"37s").update_column(:cards_count, 1_000_000)
    assert_not accounts(:"37s").exceeding_card_limit?

    # Free plan under limit
    accounts(:initech).update_column(:cards_count, 999)
    assert_not accounts(:initech).exceeding_card_limit?

    # Free plan over limit
    accounts(:initech).update_column(:cards_count, 1001)
    assert accounts(:initech).exceeding_card_limit?
  end
end
