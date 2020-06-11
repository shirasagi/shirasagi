class Sys::Diag::ServersController < ApplicationController
  include Sys::BaseFilter

  navi_view "sys/diag/main/navi"
  menu_view nil

  helper_method :http_key?, :rack_key?, :rails_key?, :other_key?

  private

  def set_crumbs
    @crumbs << ["Server Info", action: :show]
  end

  def http_key?(key)
    /^[A-Z_]+$/.match?(key)
  end

  def rack_key?(key)
    key.starts_with?("rack.")
  end

  def rails_key?(key)
    key.starts_with?("action_dispatch.") || key.starts_with?("action_controller.")
  end

  def other_key?(key)
    return false if http_key?(key)
    return false if rack_key?(key)
    return false if rails_key?(key)

    true
  end

  public

  def show
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end
end
