module Gws::Workload::Importer
  class Category < Base
    def model
      Gws::Workload::Category
    end

    def headers
      %w(id name year order member_group_id).map { |head| model.t(head) }
    end

    # export
    def export_items
      items = model.site(site).search(year: year).to_a
      items.sort_by do |item|
        group_name = item.member_group.try(:name) || ""
        [group_name, item.order, item.id]
      end
    end

    def item_to_csv(item)
      csv = []
      csv << item.id
      csv << item.name
      csv << item.year
      csv << item.order
      csv << item.member_group.try(:name)
      csv
    end

    private

    def update_row(row, index)
      row_id = row[model.t("id")].to_s.strip
      row_name = row[model.t("name")].to_s.strip
      row_year = row[model.t("year")].to_s.strip
      row_order = row[model.t("order")].to_s.strip
      row_group = row[model.t("member_group_id")].to_s.strip

      if row_id.present?
        item = model.unscoped.site(site).where(id: row_id, year: row_year).first
        if item.blank?
          errors.add :base, :not_found, year: row_year, line_no: index, id: row_id
          return nil
        end
      else
        item = model.new
      end

      member_group = Gws::Group.in_group(site).where(name: row_group).first
      if row_group.present? && member_group.blank?
        errors.add :base, :not_found_group, name: row_group, line_no: index, id: row_id
        return
      end

      item.cur_site = site
      item.cur_user = user
      item.name = row_name
      item.year = row_year
      item.order = row_order
      item.member_group = member_group

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end
  end
end
