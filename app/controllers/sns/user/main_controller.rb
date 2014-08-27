# coding: utf-8
class Sns::User::MainController < ApplicationController
  include Sns::BaseFilter

  prepend_before_action ->{ redirect_to sns_user_profile_path }, only: :index

  public
    def index
      # redirect
    end
end
