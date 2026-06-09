module Gws::Tabular::FilesHelper
  # 適用中の検索条件を「チップ」表示するための要素を列挙する。
  # search: 検索パラメータ（OpenStruct もしくは Hash）、model: ファイルモデル
  ##
  # 適用中の検索条件をチップ形式の配列として返す。
  # @param [Hash, nil] search - 検索条件ハッシュ（`nil` の場合は空配列を返す）
  # @param [Class, Object] model - 検索カラム候補を提供するモデル（`search_column_candidates` を利用可能であることを想定）
  # @return [Array<Hash>] 各要素は `{ label: String, url: String }` のハッシュ。`url` は該当の条件を除外した一覧へのリンク。
  def gws_tabular_applied_search_filters(search, model)
    return [] if search.nil?

    base = gws_tabular_search_base(search)
    gws_tabular_keyword_chips(search, base) + gws_tabular_column_chips(search, model, base)
  end

  ##
  # すべての検索条件を外した一覧ページのURLを返す。
  # @return [String] 検索条件を含まない一覧ページのURL。
  def gws_tabular_clear_search_url
    url_for(action: :index)
  end

  private

  ##
  # Builds a sanitized search base hash containing only present search fields.
  # The resulting hash may include :keyword, :act and a deep-duplicated :col.
  # @param [Hash] search - The original search parameters.
  # @return [Hash] A hash with only the present keys from `search` (`:keyword`, `:act`, and `:col`
  #   where `:col` is deep-duplicated).
  def gws_tabular_search_base(search)
    base = {}
    base[:keyword] = search[:keyword] if search[:keyword].present?
    base[:act] = search[:act] if search[:act].present?
    base[:col] = search[:col].deep_dup if search[:col].present?
    base
  end

  ##
  # Builds an array with a single chip representing the keyword filter and a URL that removes
  # that keyword from the search.
  # @param [Hash] search - Current search parameters (may include :keyword).
  # @param [Hash] base - Sanitized base search hash used as the starting point for the removal URL.
  # @return [Array<Hash>] An array containing one chip hash with keys `:label` and `:url`;
  #   returns an empty array if no keyword is present.
  def gws_tabular_keyword_chips(search, base)
    return [] if search[:keyword].blank?

    new_search = base.deep_dup
    new_search.delete(:keyword)
    [{ label: "#{t('ss.keyword')}: #{search[:keyword]}", url: gws_tabular_search_url(new_search) }]
  end

  ##
  # Builds filter chips for column-based search conditions.
  # For each column candidate with a present value and a `search_filter_chips` implementation,
  # produces one or more chip hashes that remove or adjust that column's filter when visited.
  # @param [Hash] search - The raw search parameters; expected to contain a `:col` hash keyed by column id strings.
  # @param [Class, Object] model - The model or class that may respond to `:search_column_candidates`.
  # @param [Hash] base - A sanitized base search hash (typically produced by `gws_tabular_search_base`)
  #   used as the starting point for generated URLs.
  # @return [Array<Hash>] Array of chips; each chip is a hash with `:label` (String) and `:url` (String).
  #   Empty array if there are no column filters.
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

  ##
  # Build a new search hash with the specified column filter updated or removed.
  # @param [Hash] base - The original search hash to duplicate; may include a `:col` sub-hash.
  # @param [String] column_id - The column identifier whose filter should be changed or removed.
  # @param [Object] remaining - The remaining value for the column filter; if blank, the column filter is removed.
  # @return [Hash] A new search hash reflecting the updated `:col` state; if no column filters remain,
  #   the `:col` key is omitted.
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

  ##
  # Builds the index URL applying the given search parameters when present.
  # @param [Hash, nil] new_search - Search parameters to include as the `s` query parameter;
  #   if `nil` or empty, no search parameters are included.
  # @return [String] The URL for the index action with `s` set to `new_search` when present,
  #   otherwise the index URL without search parameters.
  def gws_tabular_search_url(new_search)
    new_search.present? ? url_for(action: :index, s: new_search) : url_for(action: :index)
  end
end
