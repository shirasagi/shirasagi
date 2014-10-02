# coding: utf-8
class Facility::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to facility_facilities_path }, only: :index

  public
    def index
      # redirect
    end
end
