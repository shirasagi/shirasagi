require 'spec_helper'
require Rails.root.join("lib/migrations/contact/20221206000000_multi_contacts_on_page.rb")

RSpec.describe SS::Migration20221206000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", contact_groups: [] }
  let!(:page1) do
    create(
      :cms_page, contact_group: group1, contact_charge: "contact_charge_#{unique_id}", contact_tel: unique_tel,
      contact_fax: unique_tel, contact_email: unique_email, contact_link_url: "contact_link_url_#{unique_id}",
      contact_link_name: unique_url)
  end
  let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", contact_groups: [] }
  let!(:page2) do
    create(
      :cms_page, contact_group: group1, contact_charge: nil, contact_tel: nil, contact_fax: nil, contact_email: nil,
      contact_link_url: nil, contact_link_name: nil)
  end
  let!(:page3) do
    create(
      :cms_page, contact_group_id: rand(900..999), contact_charge: "contact_charge_#{unique_id}", contact_tel: unique_tel,
      contact_fax: unique_tel, contact_email: unique_email, contact_link_url: "contact_link_url_#{unique_id}",
      contact_link_name: unique_url)
  end

  before do
    expect(group1.contact_groups.count).to eq 0
    expect(group2.contact_groups.count).to eq 0
    expect(page1.contact_group_relation).to be_blank
    expect(page2.contact_group_relation).to be_blank
    expect(page3.contact_group_relation).to be_blank

    described_class.new.change
  end

  it do
    group1.reload
    expect(group1.contact_groups.count).to eq 1
    group1.contact_groups.first.tap do |contact|
      page1.reload
      expect(page1.contact_group_relation).to eq "related"
      expect(page1.contact_charge).to eq contact.contact_group_name
      expect(page1.contact_tel).to eq contact.contact_tel
      expect(page1.contact_fax).to eq contact.contact_fax
      expect(page1.contact_email).to eq contact.contact_email
      expect(page1.contact_link_url).to eq contact.contact_link_url
      expect(page1.contact_link_name).to eq contact.contact_link_name
    end

    page2.reload
    expect(page2.contact_group_relation).to eq "unrelated"

    page3.reload
    expect(page3.contact_group_relation).to eq "unrelated"
  end
end
