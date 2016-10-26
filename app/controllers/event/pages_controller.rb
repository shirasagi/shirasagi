class Event::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Event::Page

  append_view_path "app/views/cms/pages"
  navi_view "event/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def import_csv
      return if request.get?
      @item = @model.new

      begin
        file = params[:item].try(:[], :file)
        if file.nil? || ::File.extname(file.original_filename) != ".csv"
          raise I18n.t("errors.messages.invalid_csv")
        end
        CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')

        # save csv to use in job
        ss_file = SS::File.new
        ss_file.in_file = file
        ss_file.model = "event/import"
        ss_file.save

        # call job
        Event::Page::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)
        flash.now[:notice] = I18n.t("views.notice.import")
      rescue => e
        @item.errors.add :base, e.to_s
      end
    end
end
