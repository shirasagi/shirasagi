class Sys::Diag::HttpsController < ApplicationController
  include Sys::BaseFilter

  menu_view "sys/diag/menu"

  private

  def set_crumbs
    @crumbs << ["HTTTP Test", action: :index]
  end

  public

  def index
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
    raise "403" unless Rails.env.development?
  end
end
