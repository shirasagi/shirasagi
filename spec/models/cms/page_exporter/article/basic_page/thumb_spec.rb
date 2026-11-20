require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "thumb" do
      let!(:thumb_file) do
        content_path = "#{Rails.root}/spec/fixtures/ss/logo.png"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, basename: "logo-1.png", contents: content_path)
      end
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, thumb: thumb_file
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:thumb)]).to eq thumb_file.humanized_name
          end
        end
      end
    end
  end
end
