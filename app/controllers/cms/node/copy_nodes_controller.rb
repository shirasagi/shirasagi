class Cms::Node::CopyNodesController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  navi_view "cms/node/main/navi"
  model Cms::CopyNodesTask

  private
    def job_class
      Cms::Node::CopyNodesJob
    end

    def job_bindings
      {
        site_id: @cur_site.id,
        node_id: @cur_node.id
      }
    end

    def job_options
      {
        target_node_name: params[:item][:target_node_name]
      }
    end

    def task_name
      job_class.task_name
    end

    def set_item
      @item = Cms::CopyNodesTask.find_or_initialize_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
    end

    def get_params
      params.require(:item).permit(@model.permitted_fields).merge({})
    end

  public
    def index
      set_item

      respond_to do |format|
        format.html { render }
        format.json { render json: @item.to_json }
      end
    end

    def run
      set_item
      @item.attributes = get_params

      if @item.save
        job_class.bind(job_bindings).perform_later(job_options)

        respond_to do |format|
          format.html { redirect_to({ action: :index }, { notice: I18n.t('cms.copy_nodes.started_job') }) }
          format.json { render json: @item.to_json, status: :created, content_type: json_content_type }
        end
      else
        respond_to do |format|
          format.html { render action: :index }
          format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
        end
      end
    end
end
