require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }

  describe "#enum_csv" do
    context "file_upload (image)" do
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "image")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_file) do
        content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
      end
      let(:column1_image_html_type) { %w(image thumb).sample }
      let(:column1_image_html_type_label) { I18n.t(column1_image_html_type, scope: "cms.options.column_image_html_type") }
      let(:column1_file_label) { unique_id }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              file: column1_file, image_html_type: column1_image_html_type, file_label: column1_file_label)
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
            [ form.name, column1.name, column1.value_type.t(:file) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file.humanized_name
            end
            [ form.name, column1.name, I18n.t("cms.column_file_upload.image.file_label") ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file_label
            end
            [ form.name, column1.name, column1.value_type.t(:image_html_type) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_image_html_type_label
            end
          end
        end
      end
    end

    context "file_upload (attachment)" do
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "attachment")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_file) do
        content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
      end
      let(:column1_file_label) { unique_id }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              file: column1_file, file_label: column1_file_label)
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
            [ form.name, column1.name, column1.value_type.t(:file) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file.humanized_name
            end
            [ form.name, column1.name, I18n.t("cms.column_file_upload.attachment.file_label") ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file_label
            end
          end
        end
      end
    end

    context "file_upload (video)" do
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "video")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_file) do
        content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
      end
      let(:column1_text) { Array.new(2) { unique_id }.join("\n") }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              file: column1_file, text: column1_text)
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
            [ form.name, column1.name, column1.value_type.t(:file) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file.humanized_name
            end
            [ form.name, column1.name, column1.value_type.t(:text) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_text
            end
          end
        end
      end
    end

    context "file_upload (banner)" do
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "banner")
      end
      let(:column1_alignment) { %w(flow left center right).sample }
      let(:column1_file) do
        content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
      end
      let(:column1_file_label) { unique_id }
      let(:column1_link_url) { unique_url }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(
              column: column1, name: column1.name, alignment: column1_alignment,
              file: column1_file, file_label: column1_file_label, link_url: column1_link_url)
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
            [ form.name, column1.name, column1.value_type.t(:file) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file.humanized_name
            end
            [ form.name, column1.name, I18n.t("cms.column_file_upload.banner.file_label") ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_file_label
            end
            [ form.name, column1.name, column1.value_type.t(:link_url) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_link_url
            end
          end
        end
      end
    end
  end
end
