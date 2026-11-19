require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "contact with 'related' options" do
      let!(:contact_group1) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}") }
      let(:contact) { contact_group1.contact_groups.where(main_state: "main").first }
      let!(:contact_sub_group1) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}", order: 10) }
      let!(:contact_sub_group2) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}", order: 20) }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node,
          contact_state: "show", contact_group_relation: "related", contact_group: contact_group1,
          contact_group_contact_id: contact.id, contact_sub_group_ids: [ contact_sub_group1.id, contact_sub_group2.id ]
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:contact_state)]).to eq page1.label(:contact_state)
            expect(csv_row[Article::Page.t(:contact_group)]).to eq contact_group1.name
            expect(csv_row[Article::Page.t(:contact_group_contact)]).to eq contact.name
            expect(csv_row[Article::Page.t(:contact_group_relation)]).to eq page1.label(:contact_group_relation)
            expect(csv_row[Article::Page.t(:contact_group_name)]).to eq page1.contact_group_name
            expect(csv_row[Article::Page.t(:contact_charge)]).to eq page1.contact_charge
            expect(csv_row[Article::Page.t(:contact_tel)]).to eq page1.contact_tel
            expect(csv_row[Article::Page.t(:contact_fax)]).to eq page1.contact_fax
            expect(csv_row[Article::Page.t(:contact_email)]).to eq page1.contact_email
            expect(csv_row[Article::Page.t(:contact_postal_code)]).to eq page1.contact_postal_code
            expect(csv_row[Article::Page.t(:contact_address)]).to eq page1.contact_address
            expect(csv_row[Article::Page.t(:contact_link_url)]).to eq page1.contact_link_url
            expect(csv_row[Article::Page.t(:contact_link_name)]).to eq page1.contact_link_name
            exported = [ contact_sub_group1.name, contact_sub_group2.name ].join("\n")
            expect(csv_row[Article::Page.t(:contact_sub_groups)]).to eq exported
          end
        end
      end
    end

    context "contact with 'unrelated' options" do
      let!(:contact_group1) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}") }
      let(:contact) { contact_group1.contact_groups.where(main_state: "main").first }
      let!(:contact_sub_group1) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}", order: 10) }
      let!(:contact_sub_group2) { create(:contact_group, name: "#{site.groups.first.name}/#{unique_id}", order: 20) }
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node,
          contact_state: "hide", contact_group_relation: "unrelated", contact_group: contact_group1,
          contact_group_contact_id: contact.id, contact_group_name: unique_id, contact_charge: unique_id,
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_postal_code: unique_id, contact_address: unique_id,
          contact_link_url: "/#{unique_id}", contact_link_name: unique_id,
          contact_sub_group_ids: [ contact_sub_group1.id, contact_sub_group2.id ]
        )
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:contact_state)]).to eq page1.label(:contact_state)
            expect(csv_row[Article::Page.t(:contact_group)]).to eq contact_group1.name
            expect(csv_row[Article::Page.t(:contact_group_contact)]).to eq contact.name
            expect(csv_row[Article::Page.t(:contact_group_relation)]).to eq page1.label(:contact_group_relation)
            expect(csv_row[Article::Page.t(:contact_group_name)]).to eq page1.contact_group_name
            expect(csv_row[Article::Page.t(:contact_charge)]).to eq page1.contact_charge
            expect(csv_row[Article::Page.t(:contact_tel)]).to eq page1.contact_tel
            expect(csv_row[Article::Page.t(:contact_fax)]).to eq page1.contact_fax
            expect(csv_row[Article::Page.t(:contact_email)]).to eq page1.contact_email
            expect(csv_row[Article::Page.t(:contact_postal_code)]).to eq page1.contact_postal_code
            expect(csv_row[Article::Page.t(:contact_address)]).to eq page1.contact_address
            expect(csv_row[Article::Page.t(:contact_link_url)]).to eq page1.contact_link_url
            expect(csv_row[Article::Page.t(:contact_link_name)]).to eq page1.contact_link_name
            exported = [ contact_sub_group1.name, contact_sub_group2.name ].join("\n")
            expect(csv_row[Article::Page.t(:contact_sub_groups)]).to eq exported
          end
        end
      end
    end
  end
end
