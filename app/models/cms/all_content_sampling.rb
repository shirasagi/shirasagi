class Cms::AllContentSampling < Cms::PageExporter
  include ActiveModel::Model

  SAMPLE_COUNT = 10

  def initialize(site:)
    super(mode: "all", site: site, criteria: new_enumerator)
  end

  private

  def new_enumerator
    Enumerator.new do |y|
      each_page do |content|
        y << content
      end
      each_node do |content|
        y << content
      end
    end
  end

  def each_page(&block)
    public_pages = Cms::Page.all.site(site).and_public.only(:_id, :route, :layout_id, :form_id).to_a
    grouped_pages = public_pages.group_by { |page| [ page.route, page.layout_id, page.try(:form_id) ] }
    all_sample_pages = []
    grouped_pages.keys.each do |key|
      all_sample_pages += grouped_pages[key].sample(SAMPLE_COUNT)
    end

    all_page_ids = all_sample_pages.map(&:id)
    all_page_criteria = Cms::Page.site(site).all
    all_page_ids.each_slice(20) do |page_ids|
      all_page_criteria.in(id: page_ids).to_a.each(&block)
    end
  end

  def each_node(&block)
    public_nodes = Cms::Node.all.site(site).and_public.only(:_id, :route, :layout_id).to_a
    grouped_nodes = public_nodes.group_by { |node| [ node.route, node.layout_id ] }
    all_sample_nodes = []
    grouped_nodes.keys.each do |key|
      all_sample_nodes += grouped_nodes[key].sample(SAMPLE_COUNT)
    end

    all_node_ids = all_sample_nodes.map(&:id)
    all_node_criteria = Cms::Node.site(site).all
    all_node_ids.each_slice(20) do |node_ids|
      all_node_criteria.in(id: node_ids).to_a.each(&block)
    end
  end
end
