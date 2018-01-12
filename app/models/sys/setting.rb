class Sys::Setting
  include SS::Document
  include Sys::Permission

  set_permission_name "sys_settings", :edit

  field :menu_file_state, type: String, default: 'show'
  field :menu_connection_state, type: String, default: 'show'

  permit_params :menu_file_state,
    :menu_connection_state

  def menu_state_options
    %w(show hide).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  alias menu_file_state_options menu_state_options
  alias menu_connection_state_options menu_state_options

  def menu_file_visible?
    menu_file_state == 'show'
  end

  def menu_connection_visible?
    menu_connection_state == 'show'
  end
end
