require "test_helper"

class Account::LimitedTest < ActiveSupport::TestCase
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

  test "detect nearing storage limit" do
    account = accounts(:initech)

    # Not near limit (more than 500MB remaining of 1GB)
    account.override_limits bytes_used: 524.megabytes
    assert_not account.nearing_plan_storage_limit?

    # Near limit (less than 500MB remaining of 1GB)
    account.override_limits bytes_used: 525.megabytes
    assert account.nearing_plan_storage_limit?
  end

  test "detect exceeding storage limit" do
    account = accounts(:initech)

    # Under limit
    account.override_limits bytes_used: 1.gigabyte - 1
    assert_not account.exceeding_storage_limit?

    # Over limit
    account.override_limits bytes_used: 1.gigabyte + 1
    assert account.exceeding_storage_limit?
  end

  test "override cards count" do
    account = accounts(:initech)
    account.update_column(:cards_count, 1001)

    assert account.exceeding_card_limit?
    assert_equal 1001, account.billed_cards_count

    account.override_limits card_count: 500
    assert_not account.exceeding_card_limit?
    assert_equal 500, account.billed_cards_count
    assert_equal 1001, account.cards_count # original unchanged

    account.reset_overridden_limits
    assert account.exceeding_card_limit?
    assert_equal 1001, account.billed_cards_count
  end

  test "override bytes used" do
    account = accounts(:initech)
    actual_bytes = account.bytes_used

    assert_equal actual_bytes, account.billed_bytes_used

    account.override_limits bytes_used: 10_000
    assert_equal 10_000, account.billed_bytes_used
    assert_equal actual_bytes, account.bytes_used # original unchanged

    account.reset_overridden_limits
    assert_equal actual_bytes, account.billed_bytes_used
  end

  test "comped accounts are never limited" do
    account = accounts(:initech)
    account.update_column(:cards_count, 1_000_000)

    assert account.exceeding_card_limit?
    assert account.nearing_plan_cards_limit?

    account.comp

    assert_not account.exceeding_card_limit?
    assert_not account.nearing_plan_cards_limit?
  end

  test "uncomping an account restores limits" do
    account = accounts(:initech)
    account.update_column(:cards_count, 1_000_000)
    account.comp

    assert_not account.exceeding_card_limit?

    account.uncomp

    assert account.exceeding_card_limit?
  end
end
