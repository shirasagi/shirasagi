require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }

  describe "#enum_csv" do
    context "free with files" do
      let!(:column1) do
        create(:cms_column_free, cur_site: site, cur_form: form, required: "optional")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_value) { unique_id }
      let(:column1_file1) do
        content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, basename: "keyvisual-1.gif", contents: content_path)
      end
      let(:column1_file2) do
        content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, basename: "keyvisual-2.gif", contents: content_path)
      end
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              value: column1_value, file_ids: [ column1_file1.id, column1_file2.id ])
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
            [ form.name, column1.name, column1.value_type.t(:value) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_value
            end
            [ form.name, column1.name, column1.value_type.t(:files) ].join("/").tap do |header|
              expect(csv_row[header]).to eq [ column1_file1.humanized_name, column1_file2.humanized_name ].join("\n")
            end
          end
        end
      end
    end
    context "free without files" do
      let!(:column1) do
        create(:cms_column_free, cur_site: site, cur_form: form, required: "optional")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_value) { unique_id }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment, value: column1_value)
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
            [ form.name, column1.name, column1.value_type.t(:value) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_value
            end
            [ form.name, column1.name, column1.value_type.t(:files) ].join("/").tap do |header|
              expect(csv_table.headers).to include(header)
              expect(csv_row[header]).to be_blank
            end
          end
        end
      end
    end
  end
end
