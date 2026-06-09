module Gws::Tabular::File::Search
  extend ActiveSupport::Concern

  module ClassMethods
    def search(params = nil)
      criteria = all
      return criteria if params.blank?

      search_handlers.each do |handler|
        criteria = criteria.send(handler, params)
      rescue => e
        Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end

      criteria
    end

    ##
    # Filters records by `params[:keyword]` across the configured `keyword_fields`.
    # If `params[:keyword]` is blank, returns the unfiltered relation.
    # @param [Hash] params - Parameters hash that may include :keyword.
    # @return [ActiveRecord::Relation] Relation matching the keyword in `keyword_fields`,
    #   or the original relation when no keyword is provided.
    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], *keyword_fields)
    end

    ##
    # 検索ボックス右レールに表示する絞り込み可能な列を返す。
    # released_columns のうち `search_input_type` を持ち、その値が設定されている列だけを返す。
    # @return [Array] 絞り込み候補となる列オブジェクトの配列。
    def search_column_candidates
      return [] if released_columns.blank?
      released_columns.select do |column|
        column.respond_to?(:search_input_type) && column.search_input_type.present?
      end
    end

    # 右レールで選択された項目（params[:s][:col]）を使って一覧を絞り込む。
    ##
    # 指定されたカラム選択値(params[:col])に基づいてファイル検索の絞り込みを順次適用する。
    # 列挙型は完全一致（$in）、日付型は from/to の範囲で絞り込む。
    # @param [Hash] params - 検索パラメータ。キー `:col` にカラムID文字列をキー、選択値を値とするハッシュを含むことを期待する。
    # @return [Object] カラム条件を順次適用した検索用の criteria（元の `all` を基に絞り込みを行ったオブジェクト）。
    def search_columns(params)
      col_params = params[:col]
      return all if col_params.blank?

      criteria = all
      search_column_candidates.each do |column|
        value = col_params[column.id.to_s]
        next if value.blank?

        selector = column.search_file_criteria(value)
        next if selector.blank?

        criteria = criteria.where(selector)
      end
      criteria
    end

    ##
    # Filters records by the requested action context.
    #
    # @param [Hash, ActionController::Parameters] params - Parameters containing the action filter
    #   and current site, user, and form context.
    # @return [Mongoid::Criteria] The filtered search criteria.
    def search_act(params)
      Gws::Tabular::File::ActQuery.call(self, all, **params.to_h.slice(:cur_site, :cur_user, :cur_form, :act))
    end
  end
end
