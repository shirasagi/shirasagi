class Cms::GenerateNodesController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  navi_view "cms/main/navi"

  def index
    respond_to do |format|
      format.html { render }
      format.json { render json: @item.to_json(methods: :head_logs) }
    end
  end

  private

  def job_class
    Cms::Node::GenerateJob
  end

  def job_bindings
    {
      site_id: @cur_site.id,
    }
  end

  def job_options
    @key.present? ? { generate_key: @key } : {}
  end

  def task_name
    job_class.task_name
  end

  def set_key
    @keys = SS.config.cms.generate_keys
    return if @keys.blank?

    @key = params[:key]
    @key = nil if !@keys.include?(@key)
  end

  def set_item
    set_key
    @item = Cms::GenerateTask.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: nil, generate_key: @key
  end
end
