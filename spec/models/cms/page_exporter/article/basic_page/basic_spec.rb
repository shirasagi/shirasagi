require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "basic" do
      let!(:layout1) { create_cms_layout cur_site: site }
      let!(:body_layout) { create(:cms_body_layout, cur_site: site) }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, layout: layout1, body_layout: body_layout,
          basename: unique_id, name: unique_id, index_name: unique_id, order: rand(10), redirect_link: "/#{unique_id}")
      end

      before do
        site.update(redirect_link_state: "enabled")
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page1.basename
            expect(csv_row[Article::Page.t(:name)]).to eq page1.name
            expect(csv_row[Article::Page.t(:index_name)]).to eq page1.index_name
            expect(csv_row[Article::Page.t(:layout)]).to eq "#{layout1.name} (#{layout1.filename})"
            expect(csv_row[Article::Page.t(:body_layout_id)]).to eq body_layout.name
            expect(csv_row[Article::Page.t(:form_id)]).to be_blank
            expect(csv_row[Article::Page.t(:order)]).to eq page1.order.to_s
            expect(csv_row[Article::Page.t(:redirect_link)]).to eq page1.redirect_link
            expect(csv_row[Article::Page.t(:size)]).to eq page1.size.to_s
            expect(csv_row[Article::Page.t(:full_url)]).to eq page1.full_url
          end
        end
      end
    end
  end
end
