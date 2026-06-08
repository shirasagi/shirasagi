module Gws::Tabular::FilesHelper
  # 適用中の検索条件を「チップ」表示するための要素を列挙する。
  # search: 検索パラメータ（OpenStruct もしくは Hash）、model: ファイルモデル
  # 返り値: [{ label:, url: }, ...]（url はその条件を外した一覧 URL）
  def gws_tabular_applied_search_filters(search, model)
    return [] if search.nil?

    base = gws_tabular_search_base(search)
    gws_tabular_keyword_chips(search, base) + gws_tabular_column_chips(search, model, base)
  end

  # すべての検索条件を外した一覧 URL（「すべてクリア」用）。
  def gws_tabular_clear_search_url
    url_for(action: :index)
  end

  private

  def gws_tabular_search_base(search)
    base = {}
    base[:keyword] = search[:keyword] if search[:keyword].present?
    base[:act] = search[:act] if search[:act].present?
    base[:col] = search[:col].deep_dup if search[:col].present?
    base
  end

  def gws_tabular_keyword_chips(search, base)
    return [] if search[:keyword].blank?

    new_search = base.deep_dup
    new_search.delete(:keyword)
    [{ label: "#{t('ss.keyword')}: #{search[:keyword]}", url: gws_tabular_search_url(new_search) }]
  end

  def gws_tabular_column_chips(search, model, base)
    col = search[:col]
    return [] if col.blank?

    candidates = model.respond_to?(:search_column_candidates) ? model.search_column_candidates : []
    candidates.flat_map do |column|
      value = col[column.id.to_s]
      next [] if value.blank? || !column.respond_to?(:search_filter_chips)

      column.search_filter_chips(value).map do |chip|
        new_search = gws_tabular_remove_col(base, column.id.to_s, chip[:remaining])
        { label: chip[:label], url: gws_tabular_search_url(new_search) }
      end
    end
  end

  def gws_tabular_remove_col(base, column_id, remaining)
    new_search = base.deep_dup
    new_search[:col] ||= {}
    if remaining.present?
      new_search[:col][column_id] = remaining
    else
      new_search[:col].delete(column_id)
    end
    new_search.delete(:col) if new_search[:col].blank?
    new_search
  end

  def gws_tabular_search_url(new_search)
    new_search.present? ? url_for(action: :index, s: new_search) : url_for(action: :index)
  end
end
