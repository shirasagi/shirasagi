class Guide::GuidesController < ApplicationController
  include Cms::BaseFilter

  def index
    redirect_to guide_procedures_path
  end
end
