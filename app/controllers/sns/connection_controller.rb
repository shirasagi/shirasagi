class Sns::ConnectionController < ApplicationController
  include Sns::BaseFilter

  private

  def set_crumbs
    @crumbs << [t("sns.connection"), sns_connection_path]
  end

  public

  def index
  end
end
