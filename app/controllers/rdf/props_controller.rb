class Rdf::PropsController < ApplicationController
  include Rdf::ObjectsFilter
  helper Opendata::FormHelper

  model Rdf::Prop

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :unlink]
  before_action :set_class

  private
    def set_class
      class_id = params[:class_id]
      class_id = class_id.to_i if class_id.present? && class_id.respond_to?(:to_i)
      @rdf_class = Rdf::Class.find(class_id) if class_id.present?
    end

    def fix_params
      params = super
      params.merge!({ class_ids: [ @rdf_class.id ] }) if @rdf_class
      params
    end

    def vocab_options
      vocabs = Rdf::Vocab.site(@cur_site).each.select do |vocab|
        vocab.allowed?(:read, @cur_user, site: @cur_site)
      end
      vocabs.reduce([]) do |ret, vocab|
        ret << [ vocab.labels.preferred_value, vocab.id ]
      end.to_a
    end

  public
    def index
      if @rdf_class.present?
        set_vocab
        raise "403" unless @vocab.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

        @items = @model.rdf_class(@rdf_class).
          search(params[:s]).
          order_by(_id: 1).
          page(params[:page]).per(50)
      else
        super
      end
    end

    def unlink
      return render unless request.post?

      copy_class_ids = Array.new(@item.class_ids)
      copy_class_ids.delete(@rdf_class.id)
      @item.class_ids = copy_class_ids

      render_destroy @item.update, render: { file: :unlink }
    end

    def import
      unless request.post?
        @vocab_options = vocab_options
        params[:s] ||= {}
        params[:s][:vocab] ||= "#{@vocab.id}"
        @items = @model.
          search(params[:s]).
          order_by(_id: 1).
          page(params[:page]).per(50)
        render
        return
      end

      params[:item][:ids].map(&:to_i).each do |prop_id|
        prop = @model.site(@cur_site).find(prop_id)
        copy_class_ids = Array.new(prop.class_ids || [])
        copy_class_ids << @rdf_class.id
        copy_class_ids.uniq!
        prop.class_ids = copy_class_ids
        prop.save!
      end

      respond_to do |format|
        format.html { redirect_to({ action: :index }, { notice: t("rdf.notice.imported_props") }) }
        format.json { head :no_content }
      end
    end
end
