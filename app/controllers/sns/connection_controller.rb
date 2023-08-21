class Sns::ConnectionController < ApplicationController
  include Sns::BaseFilter

  helper_method :remote_addr

  private

  def set_crumbs
    @crumbs << [t("sns.connection"), sns_connection_path]
  end

  public

  def index
  end
end
