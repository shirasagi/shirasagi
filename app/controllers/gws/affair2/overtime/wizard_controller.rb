class Gws::Affair2::Overtime::WizardController < ApplicationController
  include Gws::ApiFilter
  include Gws::Workflow::WizardFilter

  private

  def set_model
    @model = Gws::Affair2::Overtime::File
  end

  def set_item
    @item ||= begin
      item = @model.find(params[:id].to_i)
      item.attributes = fix_params
      item
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
