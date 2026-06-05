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

    def search_keyword(params)
      return all if params[:keyword].blank?
      all.keyword_in(params[:keyword], *keyword_fields)
    end

    # 検索ボックス右レールに表示する、絞り込み可能な項目（列挙型・日付型など）を返す。
    def search_column_candidates
      return [] if released_columns.blank?
      released_columns.select do |column|
        column.respond_to?(:search_input_type) && column.search_input_type.present?
      end
    end

    # 右レールで選択された項目（params[:s][:col]）を使って一覧を絞り込む。
    # 列挙型は完全一致（$in）、日付型は from / to の範囲で絞り込む。
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

    def search_act(params)
      Gws::Tabular::File::ActQuery.call(self, all, **params.to_h.slice(:cur_site, :cur_user, :cur_form, :act))
    end
  end
end
