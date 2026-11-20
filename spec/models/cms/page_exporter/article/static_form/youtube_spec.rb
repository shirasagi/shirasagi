require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }

  describe "#enum_csv" do
    context "youtube" do
      let!(:column1) do
        create(:cms_column_youtube, cur_site: site, cur_form: form, required: "optional")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_youtube_id) { unique_id }
      let(:column1_url) { "https://www.youtube.com/watch?v=#{column1_youtube_id}" }
      let(:column1_width) { rand(100..200) }
      let(:column1_height) { rand(100..200) }
      let(:column1_auto_width) { %w(disabled enabled).sample }
      let(:column1_title) { unique_id }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              url: column1_url, title: column1_title,
              width: column1_width, height: column1_height, auto_width: column1_auto_width)
          ]
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: form)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          # puts csv_table.headers.join("\n")
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page1.basename
            [ form.name, column1.name, column1.value_type.t(:alignment) ].join("/").tap do |header|
              expect(csv_row[header]).to eq I18n.t(column1_alignment, scope: "cms.options.alignment")
            end
            [ form.name, column1.name, column1.value_type.t(:url) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_url
            end
            [ form.name, column1.name, column1.value_type.t(:width) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_width.to_s
            end
            [ form.name, column1.name, column1.value_type.t(:height) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_height.to_s
            end
            [ form.name, column1.name, column1.value_type.t(:auto_width) ].join("/").tap do |header|
              expect(csv_row[header]).to eq I18n.t(column1_auto_width, scope: "cms.column_youtube_auto_width")
            end
            [ form.name, column1.name, column1.value_type.t(:title) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_title
            end
          end
        end
      end
    end
  end
end
