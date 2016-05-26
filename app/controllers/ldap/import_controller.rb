class Ldap::ImportController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "ldap/main/navi"

  model Ldap::Import

  before_action :set_item, only: [ :show, :delete, :destroy, :sync_confirmation, :sync, :results ]

  # delete unnecessary Cms::CrudFilter methods
  undef_method :new, :create, :edit, :update

  private
    def fix_params
      { cur_site: @cur_site }
    end

    def set_crumbs
      @crumbs << [:"ldap.import", action: :index]
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
      @items = @model.site(@cur_site).order_by(id: -1).page(params[:page]).per(50)
    end

    def import_confirmation
    end

    def import
      Ldap::ImportJob.bind(site_id: @cur_site, user_id: @cur_user).
        perform_later(@cur_site.id, @cur_user.id, session[:user]["password"])
      respond_to do |format|
        format.html { redirect_to({ action: :index }, { notice: t("ldap.messages.import_started") }) }
        format.json { head :no_content }
      end
    end

    def sync_confirmation
    end

    def sync
      @job = Ldap::SyncJob.bind(site_id: @cur_site, user_id: @cur_user).
        perform_now(@cur_site.root_group.id, @item.id)
      @item.results = @job.results
      @item.save!
      respond_to do |format|
        format.html { redirect_to({ action: :results }) }
        format.json { head :no_content }
      end
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise if e.to_s =~ /^\d+$/
      @errors = @item.errors.empty? ? [ e.to_s ] : @item.errors.full_messages
      respond_to do |format|
        format.html { render file: :import, status: :unprocessable_entity }
        format.json { render json: @errors, status: :unprocessable_entity }
      end
    end

    def results
    end
end
