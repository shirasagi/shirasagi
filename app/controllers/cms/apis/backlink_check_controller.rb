class Cms::Apis::BacklinkCheckController < ApplicationController
  include Cms::BaseFilter

  def check
    checker = Cms::BacklinkChecker.new(cur_site: @cur_site, cur_user: @cur_user)
    checker.attributes = params.require(:item).permit(:id, :submit)
    checker.validate

    render json: { addon: t("cms.backlink_check"), errors: checker.errors.full_messages.presence }, status: :ok
  end
end
