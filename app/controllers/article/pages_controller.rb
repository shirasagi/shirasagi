class Article::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter
  include Cms::OpendataRef::PageFilter
  model Article::Page

  append_view_path "app/views/cms/pages"
  navi_view "article/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def download_all
    if request.get?
      return
    end

    csv_params = params.require(:item).permit(:encoding, :form_id)
    csv_params.merge!(fix_params)

    form = nil
    if csv_params[:form_id].present?
      @cur_node = @cur_node.becomes_with_route if @cur_node.class == Cms::Node
      if @cur_node.respond_to?(:st_forms)
        form = @cur_node.st_forms.where(id: csv_params.delete(:form_id)).first
        csv_params[:form] = form
      end
    end

    ctiteria = @model.site(@cur_site).
      node(@cur_node).
      allow(:read, @cur_user, site: @cur_site, node: @cur_node)

    if form.present?
      ctiteria = ctiteria.where(form_id: form)
    else
      ctiteria = ctiteria.exists(form_id: false)
    end

    enumerable = ctiteria.enum_csv(csv_params)

    filename = @model.to_s.tableize.gsub(/\//, "_")
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def import
    @item = @model.new
    return if request.get?

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("errors.messages.invalid_csv")
      end
      if !Article::Page::ImportJob.valid_csv?(file)
        raise I18n.t("errors.messages.malformed_csv")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "article/import"
      ss_file.save

      # call job
      Article::Page::ImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
      flash.now[:notice] = I18n.t("ss.notice.started_import")
    rescue => e
      @item.errors.add :base, e.to_s
    end
  end
end
