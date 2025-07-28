class Cms::Apis::BacklinkCheckController < ApplicationController
  include Cms::BaseFilter

  def check
    enabled = true
    enabled = false if params.dig(:item, :submit) == 'branch_save'

    checker = Cms::BacklinkChecker.new(cur_site: @cur_site, cur_user: @cur_user)
    checker.attributes = params.require(:item).permit(:id, :submit)
    checker.validate if enabled

    render json: { addon: t("cms.backlink_check"), errors: checker.errors.full_messages.presence }, status: :ok
  end
end
