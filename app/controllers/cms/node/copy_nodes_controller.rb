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
        target_node_name: params[:target_node_name]
      }
    end

    def task_name
      job_class.task_name
    end

    def set_item
      @item = Cms::CopyNodesTask.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
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
      # TODO: バリデーションの設定 親フォルダーが検索できない、同名のfilenameが存在する
      job_class.bind(job_bindings).perform_later(job_options)
      redirect_to({ action: :index }, { notice: "処理開始、ジョブ実行履歴で内容をご確認下さい #TODO 文言" })
    end
end
