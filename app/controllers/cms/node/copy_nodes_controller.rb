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
      @item ||= Cms::CopyNodesTask.first_or_initialize name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
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
        redirect_to({ action: :index }, { notice: "処理開始、ジョブ実行履歴で内容をご確認下さい #TODO 文言" })
        # TODO: format.json
      else
        respond_to do |format|
          format.html { render action: :index }
        end
      end
    end
end
