# class Rdf::Owl::RestrictionsController < ApplicationController
#   include Cms::BaseFilter
#   include Cms::CrudFilter
#
#   model Rdf::Owl::Restriction
#
#   navi_view "cms/main/navi"
#
#   before_action :set_class
#
#   private
#     def set_vocab
#       return if @vocab.present?
#       @vocab = Rdf::Vocab.site(@cur_site).find(params[:vid])
#       raise "404" unless @vocab
#     end
#
#     def set_class
#       set_vocab
#       return if @rdf_class.present?
#       @rdf_class = Rdf::Class.vocab(@vocab).find(params[:class_id])
#       raise "404" unless @rdf_class
#     end
#
#     def fix_params
#       set_vocab
#       set_class
#       { in_vocab: @vocab, in_class: @rdf_class }
#     end
#
#     def set_crumbs
#       set_vocab
#       set_class
#       @crumbs << [:"rdf.vocabs", rdf_vocabs_path]
#       @crumbs << [@vocab.labels.preferred_value, rdf_vocab_path(id: @vocab)]
#       @crumbs << [@rdf_class.name, rdf_classes_class_path(vid: @vocab, id: @rdf_class)]
#     end
#
#     def set_item
#       set_vocab
#       set_class
#       @item = @rdf_class.properties.find(params[:id])
#       @item.attributes = fix_params
#     end
#
#   public
#     def index
#       set_vocab
#       set_class
#       raise "403" unless @vocab.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
#
#       @items = @rdf_class.properties.search(params[:s]).order_by(_id: 1).page(params[:page]).per(50)
#     end
#
#     def show
#       raise "403" unless @vocab.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
#       render
#     end
#
#     def new
#       @item = @rdf_class.properties.new pre_params.merge(fix_params)
#       raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
#     end
#
#     def create
#       @item = @rdf_class.properties.create get_params
#       render_create @item.valid?
#     end
#
#     def edit
#       raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
#       render
#     end
#
#     def update
#       @item.attributes = get_params
#       @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
#       raise "403" unless @vocab.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
#       render_update @item.update
#     end
#
#     def delete
#       raise "403" unless @vocab.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
#       render
#     end
#
#     def destroy
#       raise "403" unless @vocab.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
#       render_destroy @item.destroy
#     end
# end
