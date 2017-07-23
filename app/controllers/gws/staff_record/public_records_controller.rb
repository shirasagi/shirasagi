class Gws::StaffRecord::PublicRecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::StaffRecord::User

  private

  def set_crumbs
    @crumbs << [t("gws/staff_record.staff_records"), action: :index]
  end

  public

  def index
    render
  end

  def show
    render
  end
end
