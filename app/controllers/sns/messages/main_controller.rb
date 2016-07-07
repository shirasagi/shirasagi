class Sns::Messages::MainController < ApplicationController
  include Sns::BaseFilter

  private
    def set_crumbs
      @crumbs << [:"messages", sns_messages_path]
    end

  public
    def index
      #
    end
end
