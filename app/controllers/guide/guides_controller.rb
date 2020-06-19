class Guide::GuidesController < ApplicationController
  include Cms::BaseFilter

  def index
    redirect_to guide_questions_path
  end
end
