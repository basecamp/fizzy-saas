require "test_helper"

class Admin::StatsControllerTest < ActionDispatch::IntegrationTest
  def saas
    Fizzy::Saas::Engine.routes.url_helpers
  end

  test "staff can access stats" do
    sign_in_as :david

    untenanted do
      get saas.admin_stats_path
    end

    assert_response :success
  end

  test "non-staff cannot access stats" do
    sign_in_as :jz

    untenanted do
      get saas.admin_stats_path
    end

    assert_response :forbidden
  end
end
