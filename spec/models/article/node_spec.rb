require 'spec_helper'

describe Article::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :article_node_base }
  it_behaves_like "cms_node#spec_detail"
end

describe Article::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :article_node_page }
  it_behaves_like "cms_node#spec_detail"

  describe "validation" do
    it "basename" do
      item = build(:article_node_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end
  end

  describe "becomes_with_route" do
    it do
      node = Cms::Node.find(item.id).becomes_with_route
      expect(node.changed?).to be_falsey
    end
  end

  context 'for member' do
    let!(:page) { create(:article_page, cur_site: cms_site, cur_node: item) }

    it do
      Cms::Node::GenerateJob.bind(site_id: cms_site).perform_now
      expect(File.exist?("#{item.path}/index.html")).to be_truthy
      expect(File.exist?("#{item.path}/rss.xml")).to be_truthy
      expect(File.exist?(page.path)).to be_truthy

      item.for_member_state = 'enabled'
      item.save!

      expect(File.exist?("#{item.path}/index.html")).to be_falsey
      expect(File.exist?("#{item.path}/rss.xml")).to be_falsey
      expect(File.exist?(page.path)).to be_falsey
    end
  end

  describe "what article/node/page exports to liquid" do
    let(:assigns) { { "parts" => SS::LiquidPartDrop.get(cms_site) } }
    let(:registers) { { cur_site: cms_site, cur_node: node, cur_path: node.url } }
    subject { node.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "with Cms::Content" do
      let!(:released) { Time.zone.now.change(min: rand(0..59)) }
      let!(:node) do
        create :article_node_page, cur_node: item, index_name: unique_id, order: rand(1..10), released: released
      end

      it do
        # Cms::Content
        expect(subject.id).to eq node.id
        expect(subject.name).to eq node.name
        expect(subject.index_name).to eq node.index_name
        expect(subject.url).to eq node.url
        expect(subject.full_url).to eq node.full_url
        expect(subject.basename).to eq node.basename
        expect(subject.filename).to eq node.filename
        expect(subject.order).to eq node.order
        expect(subject.date).to eq node.date
        expect(subject.released).to eq node.released
        expect(subject.updated).to eq node.updated
        expect(subject.created).to eq node.created
        expect(subject.parent.id).to eq item.id
        expect(subject.css_class).to eq node.basename.sub(".html", "").dasherize
        expect(subject.current?).to be_truthy
        # undocumented, but supported
        expect(subject.new?).to be_truthy
      end
    end

    context "with Cms::Model::Node" do
      let!(:node) { create :article_node_page, cur_node: item, sort: "order" }
      let!(:sub_node1) { create(:category_node_page, cur_node: node, order: 2) }
      let!(:sub_node2) { create(:category_node_page, cur_node: node, order: 1) }
      let!(:page1) { create(:article_page, cur_node: node, order: 3) }
      let!(:page2) { create(:article_page, cur_node: node, order: 1) }
      let!(:page3) { create(:article_page, cur_node: node, order: 2) }

      it do
        # Cms::Model::Page
        expect(subject.nodes.length).to eq 2
        expect(subject.nodes[0].id).to eq sub_node2.id
        expect(subject.nodes[1].id).to eq sub_node1.id
        expect(subject.pages.length).to eq 3
        expect(subject.pages[0].id).to eq page2.id
        expect(subject.pages[1].id).to eq page3.id
        expect(subject.pages[2].id).to eq page1.id
      end
    end

    context "with Cms::Addon::Meta" do
      let(:summary) { Array.new(2) { "<p>#{unique_id}</p>" }.join("\n") }
      let(:description) { Array.new(2) { unique_id }.join("\n") }
      let!(:node) { create :article_node_page, summary_html: summary, description: description }

      it do
        # Cms::Addon::Meta
        expect(subject.summary).to eq summary
        expect(subject.description).to eq description
      end
    end

    context "with Cms::Addon::GroupPermission" do
      let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", order: 1 }
      let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", order: 2 }
      let!(:node) { create :article_node_page, group_ids: [ group1.id, group2.id ] }

      it do
        # Cms::Addon::GroupPermission
        expect(subject.groups.length).to eq 2
        expect(subject.groups[0].name).to eq group1.name
        expect(subject.groups[1].name).to eq group2.name
      end
    end
  end
end
