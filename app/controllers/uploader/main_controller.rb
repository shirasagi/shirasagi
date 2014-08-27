# coding: utf-8
class Uploader::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to uploader_files_path }, only: :index

  public
    def index
      # redirect
    end
end
