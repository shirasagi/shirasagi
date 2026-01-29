require 'spec_helper'
require 'csv'

describe Cms::AllContentsMovesExporter, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create(:cms_node_page, cur_site: site) }
  let(:layout) { create(:cms_layout, cur_site: site) }
  let(:page) do
    create(:cms_page,
      cur_site: site,
      cur_node: node,
      filename: "#{node.filename}/page1.html",
      layout: layout,
      name: "Test Page",
      index_name: "Test Index",
      keywords: "keyword1, keyword2",
      description: "Test description",
      summary_html: "<p>Summary</p>"
    )
  end
  let(:group) { create(:cms_group, name: "Test Group") }

  before do
    page.group_ids = [group.id]
    page.save!
  end

  describe "#enum_csv" do
    context "with default encoding (Shift_JIS)" do
      let(:exporter) { described_class.new(site: site) }
      let(:csv_rows) { exporter.enum_csv.to_a }

      it "generates CSV with correct headers" do
        expect(csv_rows.length).to be >= 2 # header + at least one page

        # Check headers
        header_row = csv_rows[0].dup
        header_row.encode!(Encoding::UTF_8, invalid: :replace, undef: :replace)
        expect(header_row).to include(I18n.t("all_content.page_id"))
        expect(header_row).to include(I18n.t("cms.all_contents_moves.destination_filename"))
        expect(header_row).to include(Cms::Page.t(:name))
        expect(header_row).to include(I18n.t("mongoid.attributes.cms/reference/layout.layout"))
      end

      it "includes page data in CSV" do
        data_row = csv_rows.find { |row| row.include?(page.id.to_s) }
        expect(data_row).to be_present
        expect(data_row).to include(page.id.to_s)
        expect(data_row).to include(page.filename)
        expect(data_row).to include(page.name)
      end
    end

    context "with UTF-8 encoding" do
      let(:exporter) { described_class.new(site: site) }
      let(:csv_rows) { exporter.enum_csv(encoding: "UTF-8").to_a }

      it "generates CSV with UTF-8 encoding" do
        expect(csv_rows.length).to be >= 2
        expect(csv_rows[0]).to include(I18n.t("all_content.page_id"))
      end
    end

    context "with multiple pages" do
      let(:page2) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/page2.html") }
      let(:page3) { create(:cms_page, cur_site: site, cur_node: node, filename: "#{node.filename}/page3.html") }
      let(:exporter) { described_class.new(site: site) }

      before do
        page2
        page3
      end

      it "includes all pages in CSV" do
        csv_rows = exporter.enum_csv.to_a
        page_ids_in_csv = csv_rows[1..-1].map { |row| CSV.parse_line(row)&.first&.to_i }.compact

        expect(page_ids_in_csv).to include(page.id)
        expect(page_ids_in_csv).to include(page2.id)
        expect(page_ids_in_csv).to include(page3.id)
      end
    end

    context "with contact group information" do
      let(:contact_group) { create(:cms_group, name: "Contact Group") }
      let(:page_with_contact) do
        create(:cms_page,
          cur_site: site,
          cur_node: node,
          filename: "#{node.filename}/contact_page.html",
          contact_group: contact_group,
          contact_group_name: "Contact Name",
          contact_charge: "Contact Charge",
          contact_tel: "03-1234-5678",
          contact_fax: "03-1234-5679",
          contact_email: "test@example.com",
          contact_postal_code: "100-0001",
          contact_address: "Tokyo",
          contact_link_url: "https://example.com",
          contact_link_name: "Link Name"
        )
      end
      let(:exporter) { described_class.new(site: site) }

      before do
        page_with_contact
      end

      it "includes contact group information in CSV" do
        csv_rows = exporter.enum_csv.to_a
        header_row = CSV.parse_line(csv_rows[0])
        data_row_raw = csv_rows.find { |row| row.include?(page_with_contact.id.to_s) }
        expect(data_row_raw).to be_present

        data_row = CSV.parse_line(data_row_raw)
        contact_group_name_index = header_row.index(I18n.t("mongoid.attributes.cms/model/page.contact_group_name"))
        contact_tel_index = header_row.index(Cms::Page.t(:contact_tel))
        contact_email_index = header_row.index(Cms::Page.t(:contact_email))

        expect(contact_group_name_index).to be_present
        expect(contact_tel_index).to be_present
        expect(contact_email_index).to be_present

        expect(data_row[contact_group_name_index]).to eq(page_with_contact.contact_group_name)
        expect(data_row[contact_tel_index]).to eq(page_with_contact.contact_tel)
        expect(data_row[contact_email_index]).to eq(page_with_contact.contact_email)
      end
    end

    context "with groups information" do
      let(:exporter) { described_class.new(site: site) }

      it "includes groups information in CSV" do
        csv_rows = exporter.enum_csv.to_a
        header_row = CSV.parse_line(csv_rows[0])
        data_row_raw = csv_rows.find { |row| row.include?(page.id.to_s) }
        expect(data_row_raw).to be_present

        data_row = CSV.parse_line(data_row_raw)
        groups_index = header_row.index(I18n.t("mongoid.attributes.cms/addon/group_permission.groups"))

        expect(groups_index).to be_present
        expect(data_row[groups_index]).to include(group.name)
      end
    end

    context "with custom criteria" do
      let(:custom_node) { create(:cms_node_page, cur_site: site) }
      let(:custom_page) { create(:cms_page, cur_site: site, cur_node: custom_node) }
      let(:criteria) { Cms::Page.site(site).node(custom_node) }
      let(:exporter) { described_class.new(site: site, criteria: criteria) }

      before do
        custom_page
      end

      it "exports only pages matching criteria" do
        csv_rows = exporter.enum_csv.to_a
        page_ids_in_csv = csv_rows[1..-1].map { |row| CSV.parse_line(row)&.first&.to_i }.compact

        expect(page_ids_in_csv).to include(custom_page.id)
        expect(page_ids_in_csv).not_to include(page.id)
      end
    end

    context "with page without layout" do
      let(:page_no_layout) do
        create(:cms_page,
          cur_site: site,
          cur_node: node,
          filename: "#{node.filename}/no_layout.html",
          layout: nil
        )
      end
      let(:exporter) { described_class.new(site: site) }

      before do
        page_no_layout
      end

      it "handles nil layout gracefully" do
        csv_rows = exporter.enum_csv.to_a
        data_row = csv_rows.find { |row| row.include?(page_no_layout.id.to_s) }
        expect(data_row).to be_present
      end
    end

    context "with page without contact group" do
      let(:page_no_contact) do
        create(:cms_page,
          cur_site: site,
          cur_node: node,
          filename: "#{node.filename}/no_contact.html",
          contact_group: nil
        )
      end
      let(:exporter) { described_class.new(site: site) }

      before do
        page_no_contact
      end

      it "handles nil contact group gracefully" do
        csv_rows = exporter.enum_csv.to_a
        data_row = csv_rows.find { |row| row.include?(page_no_contact.id.to_s) }
        expect(data_row).to be_present
      end
    end

    context "with large number of pages" do
      let(:exporter) { described_class.new(site: site) }

      before do
        # Create more than 20 pages to test batching
        25.times do |i|
          create(:cms_page,
            cur_site: site,
            cur_node: node,
            filename: "#{node.filename}/batch_page#{i}.html"
          )
        end
      end

      it "exports all pages using batching" do
        csv_rows = exporter.enum_csv.to_a
        # Should have header + 25 pages + original page
        expect(csv_rows.length).to be >= 26
      end
    end
  end

  describe "#initialize" do
    context "without criteria" do
      let(:exporter) { described_class.new(site: site) }

      it "creates enumerator for all pages" do
        expect(exporter).to be_present
        csv_rows = exporter.enum_csv.to_a
        expect(csv_rows.length).to be >= 2
      end
    end

    context "with criteria" do
      let(:criteria) { Cms::Page.site(site).node(node) }
      let(:exporter) { described_class.new(site: site, criteria: criteria) }

      it "uses provided criteria" do
        expect(exporter).to be_present
        csv_rows = exporter.enum_csv.to_a
        expect(csv_rows.length).to be >= 2
      end
    end
  end
end
