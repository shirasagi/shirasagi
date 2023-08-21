class Garbage::Node::PageImporter < Garbage::Node::BaseImporter

  private

  def model
    Garbage::Node::Page
  end

  def set_page_attributes(row, item)
    item.name = row[model.t("name")].to_s.strip
    item.index_name = row[model.t("index_name")].to_s.strip
    item.layout = Cms::Layout.site(site).where(name: row[model.t("layout")].to_s.strip).first
    item.order = row[model.t("order")].to_s.strip
    item.remark = row[model.t("remark")].to_s.strip
    item.order  = row[model.t("order")].to_s.strip
    item.kana = row[model.t("kana")].to_s.strip

    set_page_categories(row, item)
    set_page_groups(row, item)

    item
  end

  def set_page_categories(row, item)
    @st_categories ||= node.st_categories.map{ |c| [c.name, c.id] }.to_h
    categories = row[model.t("category_ids")].to_s.strip
    item.category_ids = categories.split("\n").map { |category| @st_categories[category] }
  end
end
