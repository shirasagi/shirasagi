class Gws::Apis::CustomGroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::CustomGroup

  def index
    @multi = params[:single].blank?

    super
  end
end
