class Gws::SettingsController < ApplicationController
  include Gws::BaseFilter

  public
    def index
      url_lazy = Gws::Setting.plugins.first[1]
      redirect_to instance_exec(&url_lazy)
    end
end
