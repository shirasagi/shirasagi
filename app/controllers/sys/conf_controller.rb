class Sys::ConfController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  CONF_PATHS = [
    [ Rails.application.routes.url_helpers.sys_sites_path, Sys::Site ],
    [ Rails.application.routes.url_helpers.sys_groups_path, Sys::Group ],
    [ Rails.application.routes.url_helpers.sys_users_path, SS::User ],
    [ Rails.application.routes.url_helpers.sys_roles_path, Sys::Role ],
    [ Rails.application.routes.url_helpers.sys_info_path, nil ],
  ].freeze

  def index
    path, model = CONF_PATHS.find do |path, model|
      model.nil? ? true : model.allowed?(:edit, @cur_user)
    end

    redirect_to path
  end
end
