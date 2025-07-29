class Gws::Tabular::Apis::Gws::ColumnsController < Gws::Apis::ColumnsController

  private

  def append_view_paths
    append_view_path "app/views/gws/apis/columns"
    super
  end

  def crud_redirect_url
    gws_tabular_frames_gws_column_path(id: @item, ref: ref)
  end
end
