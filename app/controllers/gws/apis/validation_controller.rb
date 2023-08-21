class Gws::Apis::ValidationController < ApplicationController
  include SS::ValidationFilter
  include Gws::CrudFilter
  include Gws::ApiFilter

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
