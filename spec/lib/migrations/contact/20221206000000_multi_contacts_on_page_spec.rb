require 'spec_helper'
require Rails.root.join("lib/migrations/contact/20221206000000_multi_contacts_on_page.rb")

RSpec.describe SS::Migration20221206000000, dbscope: :example do
  let!(:site) { cms_site }
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", contact_groups: [] }
  let!(:page1) do
    Timecop.freeze(now) do
      create(
        :cms_page, contact_group: group1,
        contact_group_name: "contact_group_name_#{unique_id}", contact_charge: "contact_charge_#{unique_id}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_postal_code: unique_id, contact_address: "address-#{unique_id}",
        contact_link_url: "contact_link_url_#{unique_id}", contact_link_name: unique_url)
    end
  end
  let!(:page2) do
    Timecop.freeze(now) do
      create(
        :cms_page, contact_group: group1,
        contact_group_name: "contact_group_name_#{unique_id}", contact_charge: "contact_charge_#{unique_id}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_postal_code: unique_id, contact_address: "address-#{unique_id}",
        contact_link_url: "contact_link_url_#{unique_id}", contact_link_name: unique_url)
    end
  end
  let!(:page3) do
    Timecop.freeze(now) do
      create(
        :cms_page, contact_group: group1, contact_group_name: nil, contact_charge: nil, contact_tel: nil, contact_fax: nil,
        contact_email: nil, contact_postal_code: nil, contact_address: nil, contact_link_url: nil, contact_link_name: nil)
    end
  end
  let!(:page4) do
    Timecop.freeze(now) do
      create(
        :cms_page, contact_group_id: rand(900..999),
        contact_group_name: "contact_group_name_#{unique_id}", contact_charge: "contact_charge_#{unique_id}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_postal_code: unique_id, contact_address: "address-#{unique_id}",
        contact_link_url: "contact_link_url_#{unique_id}", contact_link_name: unique_url)
    end
  end

  before do
    expect(group1.contact_groups.count).to eq 0
    expect(page1.contact_group_relation).to be_blank
    expect(page2.contact_group_relation).to be_blank
    expect(page3.contact_group_relation).to be_blank
    expect(page4.contact_group_relation).to be_blank

    described_class.new.change
  end

  it do
    group1.reload
    expect(group1.contact_groups.count).to eq 2
    group1.contact_groups.first.tap do |contact|
      expect(contact.main_state).to be_blank
      expect(contact.name).to eq "#{group1.section_name} 1"
    end
    group1.contact_groups.second.tap do |contact|
      expect(contact.main_state).to be_blank
      expect(contact.name).to eq "#{group1.section_name} 2"
    end

    group1.contact_groups.first.tap do |contact|
      Cms::Page.find(page1.id).tap do |page|
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_group_contact_id).to eq contact.id
        expect(page.contact_group_name).to eq contact.contact_group_name
        expect(page.contact_charge).to eq contact.contact_charge
        expect(page.contact_tel).to eq contact.contact_tel
        expect(page.contact_fax).to eq contact.contact_fax
        expect(page.contact_email).to eq contact.contact_email
        expect(page.contact_postal_code).to eq contact.contact_postal_code
        expect(page.contact_address).to eq contact.contact_address
        expect(page.contact_link_url).to eq contact.contact_link_url
        expect(page.contact_link_name).to eq contact.contact_link_name
        expect(page.created).to eq page1.created
        expect(page.updated).to eq page1.updated
      end
    end
    group1.contact_groups.second.tap do |contact|
      Cms::Page.find(page2.id).tap do |page|
        expect(page.contact_group_relation).to eq "related"
        expect(page.contact_group_contact_id).to eq contact.id
        expect(page.contact_group_name).to eq contact.contact_group_name
        expect(page.contact_charge).to eq contact.contact_charge
        expect(page.contact_tel).to eq contact.contact_tel
        expect(page.contact_fax).to eq contact.contact_fax
        expect(page.contact_email).to eq contact.contact_email
        expect(page.contact_postal_code).to eq contact.contact_postal_code
        expect(page.contact_address).to eq contact.contact_address
        expect(page.contact_link_url).to eq contact.contact_link_url
        expect(page.contact_link_name).to eq contact.contact_link_name
        expect(page.created).to eq page2.created
        expect(page.updated).to eq page2.updated
      end
    end

    Cms::Page.find(page3.id).tap do |page|
      expect(page.contact_group_relation).to eq "unrelated"
      expect(page.created).to eq page3.created
      expect(page.updated).to eq page3.updated
    end

    Cms::Page.find(page4.id).tap do |page|
      expect(page.contact_group_relation).to eq "unrelated"
      expect(page.created).to eq page4.created
      expect(page.updated).to eq page4.updated
    end
  end
end
