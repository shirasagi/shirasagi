return unless ::Rails.env.development?

class Sns::BootstrapController < ApplicationController
  include SS::BaseFilter

  skip_before_action :logged_in?

  def index
    render layout: false
  end
end
