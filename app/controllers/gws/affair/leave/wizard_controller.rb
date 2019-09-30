class Gws::Affair::Leave::WizardController < ApplicationController
  include Gws::ApiFilter
  include Gws::Affair::WizardFilter

  private

  def set_model
    @model = Gws::Affair::LeaveFile
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
