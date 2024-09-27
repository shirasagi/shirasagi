class Guide::Apis::QuestionsController < ApplicationController
  include Cms::ApiFilter

  model Guide::Question

  def index
    @multi = params[:single].blank?
    @node = Cms::Node.where(id: params[:nid]).first
    @id = params[:id].to_i

    unless @node
      @items = @model.none
      return
    end

    @items = @model.site(@cur_site).
      node(@node).
      ne(id: @id).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
