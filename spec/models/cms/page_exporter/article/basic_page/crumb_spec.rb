require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "crumb" do
      let(:category1) { create :category_node_page, cur_site: site }
      let(:category2) { create :category_node_page, cur_site: site }
      let!(:page1) do
        create(:article_page, cur_site: site, cur_node: node, parent_crumb_urls: [ category1.url, category2.url ])
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:parent_crumb)]).to eq [ category1.url, category2.url ].join("\n")
          end
        end
      end
    end
  end
end
