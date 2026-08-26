class Guide::Apis::QuestionsController < ApplicationController
  include Cms::ApiFilter

  model Guide::Question

  private

  def set_items
    return @items if instance_variable_defined?(:@items)

    @node = Cms::Node.site(@cur_site).where(id: params[:nid]).first
    @id = params[:id].to_i

    unless @node
      @items = @model.none
      return
    end

    @items = @model.site(@cur_site).
      node(@node).
      ne(id: @id).
      allow(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    @multi = params[:single].blank?

    set_items
    @items = @items.
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
