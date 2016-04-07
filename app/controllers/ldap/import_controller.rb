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
      Ldap::ImportJob.new.call(@cur_site.id, @cur_user.id, session[:user]["password"])
      respond_to do |format|
        format.html { redirect_to({ action: :index }, { notice: t("ldap.messages.import_success") }) }
        format.json { head :no_content }
      end
    rescue => e
      raise if e.to_s =~ /^\d+$/
      @errors = [ e.to_s ]
      respond_to do |format|
        format.html { render status: :bad_request }
        format.json { render json: @errors, status: :bad_request }
      end
    end

    def sync_confirmation
    end

    def sync
      @job = Ldap::SyncJob.new
      @job.call(@cur_site.root_group.id, @item.id)
      @item.results = @job.results
      @item.save!
      respond_to do |format|
        format.html { redirect_to({ action: :results }) }
        format.json { head :no_content }
      end
    rescue => e
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
