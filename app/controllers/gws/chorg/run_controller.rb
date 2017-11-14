class Gws::Chorg::RunController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :prepend_current_view_path
  before_action :append_view_paths
  before_action :set_revision
  before_action :set_task
  before_action :set_item

  model Gws::Chorg::RunParams

  navi_view 'gws/main/conf_navi'
  menu_view 'chorg/run/menu'

  private

  def set_crumbs
    @crumbs << [t('modules.gws/chorg'), controller: :revisions, action: :index]
    @crumbs << [t("chorg.views.run/confirmation.#{params[:type]}.run_button"), action: :confirmation]
  end

  def set_revision
    @revision = Gws::Chorg::Revision.find params[:rid]
  end

  def set_task
    @task ||= begin
      criteria = Gws::Chorg::Task.site(@cur_site)
      criteria = criteria.and_revision(@revision)
      criteria = criteria.where(name: "gws:chorg:#{params[:type]}_task")
      criteria.first_or_create
    end

    if @task.running?
      redirect_to({ controller: :revisions, action: :index }, { notice: '実行中または実行準備中です。' })
      return
    end
  end

  def set_item
    @item = @model.new
  end

  public

  def confirmation
  end

  def run
    @item.attributes = get_params
    if @item.valid?
      begin
        job_class = Gws::Chorg::Runner.job_class params[:type]
        job_class = job_class.bind(site_id: @cur_site, user_id: @cur_user, task_id: @task)
        job_class = job_class.set(wait_until: @item.reservation) if @item.reservation

        @job = job_class.perform_later(@revision.name, false)
        @revision.add_to_set(job_ids: @job.job_id)
      rescue => e
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        @item.errors.add(:base, e.to_s)
      end
    end

    if @item.errors.blank?
      respond_to do |format|
        format.html do
          if @item.reservation
            notice = t('chorg.messages.job_reserved')
          else
            notice = t('chorg.messages.job_started')
          end
          redirect_to({ controller: :revisions, action: :show, id: @revision },
                      { notice: notice })
        end
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render file: :confirmation, status: :unprocessable_entity }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
end
