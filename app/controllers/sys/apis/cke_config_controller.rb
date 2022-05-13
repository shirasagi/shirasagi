class Sys::Apis::CkeConfigController < ApplicationController
  include SS::BaseFilter

  protect_from_forgery except: :index

  def index
    render
  end
end
