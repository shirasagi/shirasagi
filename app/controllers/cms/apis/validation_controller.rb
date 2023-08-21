class Cms::Apis::ValidationController < ApplicationController
  include SS::ValidationFilter
  include Cms::CrudFilter
  include Cms::ApiFilter

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
