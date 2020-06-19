class Guide::DiagramController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/node/main/navi"

  def index
    @item = Guide::QuestionDiagram.new(@cur_node)
  end
end
