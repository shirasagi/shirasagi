class Cms::AllContent < Cms::PageExporter
  include ActiveModel::Model

  def initialize(site:, criteria: nil)
    super(mode: "all", site: site, criteria: criteria || new_enumerator)
  end

  private

  def new_enumerator
    Enumerator.new do |y|
      each_content do |content|
        y << content
      end
    end
  end

  def each_content(&block)
    page_criteria = Cms::Page.site(site).all
    all_page_ids = page_criteria.pluck(:id)
    all_page_ids.each_slice(20) do |page_ids|
      page_criteria.in(id: page_ids).to_a.each(&block)
    end

    node_criteria = Cms::Node.site(site).all
    all_node_ids = node_criteria.pluck(:id)
    all_node_ids.each_slice(20) do |node_ids|
      node_criteria.in(id: node_ids).to_a.each(&block)
    end
  end
end
