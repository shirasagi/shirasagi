module Rdf::ObjectsFilter
  extend ActiveSupport::Concern
  include Cms::BaseFilter
  include Cms::CrudFilter

  included do
    navi_view "cms/main/navi"
  end

  private
    def set_vocab
      return if @vocab.present?
      @vocab = Rdf::Vocab.site(@cur_site).find(params[:vocab_id])
      raise "404" unless @vocab
    end

    def fix_params
      set_vocab
      { vocab_id: @vocab.id }
    end

    def set_crumbs
      set_vocab
      @crumbs << [:"rdf.vocabs", rdf_vocabs_path]
      @crumbs << [@vocab.labels.preferred_value, controller: :vocabs, action: :show, id: @vocab]
    end

    def set_item
      set_vocab
      @item = @model.vocab(@vocab).find(params[:id])
      @item.attributes = fix_params
    end

    def set_categories
      # TODO: 後で修正するつもりだが、いいアイデアがない
      node = Opendata::Node::Category.site(@cur_site).and_public.first
      if node.blank?
        @categories = []
        return
      end
      node = node.parent while node.parent.present?

      @categories = [node.becomes_with_route]
    end

  public
    def index
      set_vocab
      raise "403" unless @vocab.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      set_categories
      @items = @model.vocab(@vocab).
          search(params[:s]).
          order_by(_id: 1).
          page(params[:page]).per(50)
    end

    def show
      set_vocab
      raise "403" unless @vocab.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
      set_categories
      render
    end

    def new
      set_vocab
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      set_categories
    end

    def create
      set_vocab
      @item = @model.new get_params
      raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render_create @item.save
    end

    def edit
      set_vocab
      raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      set_categories
      render
    end

    def update
      set_vocab
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render_update @item.update
    end

    def delete
      set_vocab
      raise "403" unless @vocab.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
      render
    end

    def destroy
      set_vocab
      raise "403" unless @vocab.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
      render_destroy @item.destroy
    end
end
