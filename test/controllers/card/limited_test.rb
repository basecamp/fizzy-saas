require "test_helper"

class Card::LimitedTest < ActionDispatch::IntegrationTest
  test "cannot create cards when card limit exceeded" do
    sign_in_as :mike

    accounts(:initech).update_column(:cards_count, 1001)

    assert_no_difference -> { Card.count } do
      post board_cards_path(boards(:miltons_wish_list), script_name: accounts(:initech).slug)
    end

    assert_response :forbidden
  end
end
