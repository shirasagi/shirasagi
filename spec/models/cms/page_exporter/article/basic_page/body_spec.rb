require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "body" do
      let!(:page1) do
        html = <<~HTML
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        HTML
        create(:article_page, cur_site: site, cur_node: node, html: html)
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          expect(csv_table.headers).to include(Article::Page.t(:body_part))
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:html)]).to eq page1.html
            expect(csv_row[Article::Page.t(:body_part)]).to be_blank
          end
        end
      end
    end
  end
end
