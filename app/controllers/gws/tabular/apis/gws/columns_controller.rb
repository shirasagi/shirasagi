class Gws::Tabular::Apis::Gws::ColumnsController < Gws::Apis::ColumnsController

  private

  def append_view_paths
    append_view_path "app/views/gws/apis/columns"
    super
  end

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def cur_form
    @cur_form ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:form])
    end
  end

  def set_items
    @items ||= Gws::Column::Base.site(@cur_site).where(form_id: cur_form.id)
  end

  def crud_redirect_url
    gws_tabular_frames_gws_column_path(id: @item, ref: ref)
  end
end
