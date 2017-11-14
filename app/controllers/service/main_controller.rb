class Service::MainController < ApplicationController
  include Service::BaseFilter

  def index
    redirect_to(service_my_accounts_path)
  end
end
