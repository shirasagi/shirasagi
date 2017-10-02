class Gws::StaffRecord::PublicUserHistoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::PublicYearlyFilter

  model Gws::StaffRecord::User

  before_action :set_target_user

  private

  def set_crumbs
    @crumbs << [t("gws/staff_record.user_histories"), action: :index]
  end

  def set_target_user
    @user = Gws::StaffRecord::User.find(params[:user])
  end

  public

  def index
    raise "403" unless @user.readable?(@cur_user)

    @items = @model.show_staff_records.
      where(code: @user.code).
      search(params[:s]).
      reorder(year_code: -1, order: 1).
      all
  end
end
