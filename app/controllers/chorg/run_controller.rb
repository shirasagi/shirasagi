class Chorg::RunController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :prepend_current_view_path
  before_action :append_view_paths
  before_action :set_revision
  before_action :set_item

  model Chorg::RunParams

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), controller: :revisions, action: :index]
  end

  def set_revision
    @revision = Chorg::Revision.find params[:rid]
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
        job_class = Chorg::Runner.job_class params[:type]
        job_class = job_class.bind(site_id: @cur_site, user_id: @cur_user)
        job_class = job_class.set(wait_until: @item.reservation) if @item.reservation

        @job = job_class.perform_later(@revision.name, @item.add_newly_created_group_to_site)
        @revision.add_to_set(job_ids: @job.job_id)
      rescue => e
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        @item.errors.add(:base, e.to_s)
      end
    end

    if @item.errors.blank?
      respond_to do |format|
        if @item.reservation
          notice = t('chorg.messages.job_reserved')
        else
          notice = t('chorg.messages.job_started')
        end
        format.html do
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
