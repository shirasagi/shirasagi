class Chorg::RunController < ApplicationController
  include Cms::BaseFilter
  # include Cms::CrudFilter

  before_action :prepend_current_view_path
  before_action :append_view_paths
  before_action :set_item

  model Chorg::Revision

  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"chorg.revision", controller: :revisions, action: :index]
    end

    def prepend_current_view_path
      prepend_view_path "app/views/#{params[:controller]}"
    end

    def append_view_paths
      append_view_path "app/views/ss/crud"
    end

    def set_item
      @item = @model.find params[:rid]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def add_job_id(array, id)
      if array.blank?
        [id]
      else
        copy = Array.new(array)
        copy << id
        copy
      end
    end

  public
    def confirmation
    end

    def run
      begin
        add_group_to_site = params[:item][:add_newly_created_group_to_site].to_i
        job_class = Chorg::Runner.job_class params[:type]
        @job = job_class.bind(site_id: @cur_site, user_id: @cur_user).
          perform_later(@item.name, add_group_to_site)
        @item.job_ids = add_job_id(@item.job_ids, @job.job_id)
      rescue => e
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        @item.errors.add :base, e.to_s
      end

      if @item.errors.empty? && @item.save
        respond_to do |format|
          format.html do
            redirect_to({ controller: :revisions, action: :show, id: @item.id },
                        { notice: t("chorg.messages.job_started") })
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
