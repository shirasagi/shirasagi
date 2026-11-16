require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "meta" do
      let!(:page1) do
        description = <<~TEXT
          #{unique_id}
          #{unique_id}
        TEXT
        summary_html = <<~HTML
          <p>
            #{unique_id}
            #{unique_id}
          </p>
        HTML
        create(
          :article_page, cur_site: site, cur_node: node,
          keywords: Array.new(2) { unique_id }, description: description, summary_html: summary_html
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:keywords)]).to eq page1.keywords.join(", ")
            expect(csv_row[Article::Page.t(:description)]).to eq page1.description
            expect(csv_row[Article::Page.t(:summary_html)]).to eq page1.summary_html
          end
        end
      end
    end
  end
end
