class Opendata::Dataset::Csv2rdfSettingsController < ApplicationController
  include Cms::BaseFilter
  helper Opendata::Csv2rdfSettingsHelper

  ACTION_SEQUENCE = [:header_size, :rdf_class, :column_types, :confirmation].freeze

  model Opendata::Csv2rdfSetting

  navi_view "cms/main/navi"

  prepend_view_path "app/views/opendata/dataset/csv2rdf_settings"
  append_view_path "app/views/ss/crud"
  append_view_path "app/views/cms/crud"

  before_action :set_item
  before_action :set_rdf_class

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_dataset: @cur_dataset, cur_resource: @cur_resource }
    end

    def pre_params
      {}
    end

    def permit_fields
      @model.permitted_fields
    end

    def get_params
      params.require(:item).permit(permit_fields).merge(fix_params)
    end

    def set_item
      @cur_dataset = Opendata::Dataset.site(@cur_site).node(@cur_node).find(params[:dataset_id])
      @cur_resource = @cur_dataset.resources.find(params[:resource_id])

      actual_rows = @cur_resource.parse_tsv.size
      if actual_rows <= 2
        redirect_to opendata_dataset_resource_path(id: @cur_resource),
                    flash: { notice: t('opendata.messages.require_at_least_two_rows') }
        return
      end

      @item = @model.site(@cur_site).resource(@cur_resource).first
      @item ||= @model.create(pre_params.merge(fix_params))
      @item.attributes = fix_params

      params[:s] ||= {}
      params[:s][:category_ids] ||= [ "false" ]
    end

    def set_rdf_class
      @cur_class = Rdf::Class.site(@cur_site).where(_id: @item.class_id).first if @item.class_id.present?
      params[:s] ||= {}
      if params[:s][:vocab].blank?
        if @cur_class.present?
          params[:s][:vocab] = @cur_class.vocab.id
        else
          default_vocab = Rdf::Vocab.site(@cur_site).first
          params[:s][:vocab] = default_vocab.id if default_vocab.present?
        end
      end
    end

    def render_with(opts)
      unless request.post?
        if opts.key?(:file)
          render(file: opts[:file])
        else
          render
        end
        return
      end

      @item.attributes = get_params
      @item.send("validate_#{params[:action]}")
      if @item.errors.blank? && @item.update
        respond_to do |format|
          format.html { redirect_to action: opts[:action] }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html do
            if opts.key?(:file)
              render(file: opts[:file])
            else
              render
            end
          end
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end

    def render_update(result, opts = {})
      if result
        respond_to do |format|
          format.html { redirect_to({ action: :column_types }, { notice: t("views.notice.saved") }) }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { render }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
        end
      end
    end

  public
    def header_size
      render_with(file: "wizards", action: :rdf_class)
    end

    def rdf_class
      render_with(action: :column_types)
    end

    def column_types
      render_with(file: "wizards", action: :confirmation)
    end

    def confirmation
      return render(file: "wizards") unless request.post?

      Opendata::Csv2rdfConverter::Job.call_async(@cur_site.host, @cur_user.name,
                                                 @cur_node.id, @cur_dataset.id, @cur_resource.id) do |job|
        job.site_id = @cur_site.id
        job.user_id = @cur_user.id
      end
      SS::RakeRunner.run_async "job:run", "RAILS_ENV=#{Rails.env}"
      respond_to do |format|
        format.html do
          redirect_to({ controller: :resources, action: :show, id: @cur_resource },
                      { notice: t("opendata.notice.started_building_rdf_job") })
        end
        format.json { head :no_content }
      end
    end

    def rdf_class_preview
      @rdf_class = Rdf::Class.site(@cur_site).find(params[:rdf_cid])
      @item = @item.dup
      @item.class_id = @rdf_class.id
      @item.column_types = @item.search_column_types(class: @rdf_class)
      render
    end

    def rdf_prop_select
      @column_index = params[:column_index].to_i
      @header_labels = @item.header_labels[@column_index]
      @column_type = @item.column_types[@column_index]
      @rdf_class = @item.rdf_class
      @csv = @item.resource.parse_tsv
      @samples = []
      @csv[@item.header_rows..19].each do |row|
        @samples << row[@column_index]
      end
      unless request.post?
        render
        return
      end

      copy = Array.new(@item.column_types)
      prop_id = params[:item][:prop_id]
      case prop_id
      when "endemic:string"
        copy[@column_index] = {"classes" => ["xsd:string"]}
      when "endemic:integer"
        copy[@column_index] = {"classes" => ["xsd:integer"]}
      when "endemic:decimal"
        copy[@column_index] = {"classes" => ["xsd:decimal"]}
      when "false"
        copy[@column_index] = {"classes" => [false]}
      else
        prop_id = prop_id.split(",").map(&:strip)
        found = @item.rdf_class.flattern_properties.select do |prop|
          prop[:properties] == prop_id
        end
        found = found.first
        if found.blank?
          @item.errors.add(:base, t("opendata.errors.messages.property_not_selected"))
          render
          return
        end
        copy[@column_index] = found
      end

      @item.attributes = { column_types: copy }
      render_update @item.update
    end
end
