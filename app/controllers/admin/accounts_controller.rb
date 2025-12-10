class Admin::AccountsController < AdminController
  layout "public"

  before_action :set_account, only: %i[ edit update ]

  def index
  end

  def edit
  end

  def update
    @account.update!(account_params)
    redirect_to saas.edit_admin_account_path(@account.external_account_id), notice: "Account updated"
  end

  private
    def set_account
      @account = Account.find_by!(external_account_id: params[:id])
    end

    def account_params
      params.expect(account: [ :cards_count ])
    end
end
