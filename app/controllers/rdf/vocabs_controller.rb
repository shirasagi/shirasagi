class Rdf::VocabsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rdf::Vocab

  navi_view "cms/main/navi"

  before_action :set_extra_crumbs, only: [:show, :edit, :update, :delete, :destroy]

  private
    def fix_params
      { cur_site: @cur_site }
    end

    def set_crumbs
      @crumbs << [:"rdf.vocabs", action: :index]
    end

    def set_extra_crumbs
      set_item
      @crumbs << [@item.label, action: :show, id: @item] if @item.present?
    end

    def save_file
      temp_file = SS::TempFile.new
      temp_file.cur_user = @cur_user
      temp_file.in_file = @item.in_file
      temp_file.state = "private"
      temp_file.save!
      temp_file
    end

    def extract_errors(e)
      if e.respond_to?(:document)
        e.document.errors.full_messages
      else
        [ e.to_s ]
      end
    end

  public
    def import
      @item = OpenStruct.new
      return render unless request.post?

      @item = OpenStruct.new(params.require(:item).permit(:prefix, :order, :owner, :in_file))
      @file = save_file
      @item.in_file.try(:delete)

      Rdf::VocabImportJob.call_async(@cur_site.host, @item.prefix, @file.id, @item.owner, @item.order) do |job|
        job.site_id = @cur_site.id
      end
      SS::RakeRunner.run_async "job:run", "RAILS_ENV=#{Rails.env}"

      respond_to do |format|
        format.html { redirect_to({ action: :index }, { notice: t("rdf.notices.start_import_job") }) }
        format.json { render json: @item.to_json, status: :created }
      end
    rescue => e
      logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @item.in_file.try(:delete)
      @errors = extract_errors(e)
      respond_to do |format|
        format.html { render }
        format.json { render json: @errors, status: :unprocessable_entity }
      end
    end
end
