class Sys::Db::MainController < ApplicationController
  include Sys::BaseFilter

  prepend_before_action ->{ redirect_to sys_db_colls_path }, only: :index

  public
    def index
      # redirect
    end
end
