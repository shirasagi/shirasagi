module Gws::Workload::Importer
  class Cycle < Base
    def model
      Gws::Workload::Cycle
    end

    def headers
      %w(id name year order).map { |head| model.t(head) }
    end

    # export
    def export_items
      model.site(site).search(year: year).to_a
    end

    def item_to_csv(item)
      csv = []
      csv << item.id
      csv << item.name
      csv << item.year
      csv << item.order
      csv
    end

    private

    def update_row(row, index)
      row_id = row[model.t("id")].to_s.strip
      row_name = row[model.t("name")].to_s.strip
      row_year = row[model.t("year")].to_s.strip
      row_order = row[model.t("order")].to_s.strip

      if row_id.present?
        item = model.unscoped.site(site).where(id: row_id, year: row_year).first
        if item.blank?
          errors.add :base, :not_found, year: row_year, line_no: index, id: row_id
          return nil
        end
      else
        item = model.new
      end

      item.cur_site = site
      item.cur_user = user
      item.name = row_name
      item.year = row_year
      item.order = row_order

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end
  end
end
