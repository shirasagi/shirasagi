require 'spec_helper'
require Rails.root.join("lib/migrations/contact/20231115000000_fix_incorrect_migration.rb")

RSpec.describe SS::Migration20231115000000, dbscope: :example do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:group1) do
    # 本マイグレーションを適用するには、連絡先が本マイグレーションの適用日時よりも前に作成されていなければならない
    Timecop.freeze(now - 1.day) do
      # 不具合のあるマイグレーションを実行すると、以下のような連絡先が作成される。
      create(
        :cms_group, name: "#{group.name}/#{unique_id}",
        contact_groups: [
          {
            main_state: "main", name: group.section_name,
            contact_group_name: "name-#{unique_id}", contact_charge: nil,
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          },
          {
            main_state: nil, name: "#{group.section_name} 1",
            contact_group_name: "page-charge-#{unique_id}", contact_charge: nil,
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          }
        ]
      )
    end
  end
  let!(:group1_main_contact) { group1.contact_groups.where(main_state: "main").first }
  let!(:group1_sub_contact) { group1.contact_groups.ne(main_state: "main").first }

  let!(:group2) do
    # 本マイグレーションを適用するには、連絡先が本マイグレーションの適用日時よりも前に作成されていなければならない
    Timecop.freeze(now - 1.day) do
      # 手動で作成した次のような連絡先には変更はないはず。
      create(
        :cms_group, name: "#{group.name}/#{unique_id}",
        contact_groups: [
          {
            main_state: "main", name: group.section_name,
            contact_group_name: "name-#{unique_id}", contact_charge: nil,
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          },
          {
            main_state: nil, name: "#{group.section_name} 1",
            contact_group_name: "name-#{unique_id}", contact_charge: "charge-#{unique_id}",
            contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
            contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
          }
        ]
      )
    end
  end
  let!(:group2_main_contact) { group2.contact_groups.where(main_state: "main").first }
  let!(:group2_sub_contact) { group2.contact_groups.ne(main_state: "main").first }

  before do
    Timecop.freeze(now) do
      SS::Migration.create!(version: "20221206000000")
    end
    described_class.new.change
  end

  it do
    Cms::Group.find(group1.id).contact_groups.where(main_state: "main").first.tap do |new_main_contact|
      # 主連絡先に変更はないはず。
      expect(new_main_contact.id).to eq group1_main_contact.id
      expect(new_main_contact.main_state).to eq group1_main_contact.main_state
      expect(new_main_contact.name).to eq group1_main_contact.name
      expect(new_main_contact.contact_group_name).to eq group1_main_contact.contact_group_name
      expect(new_main_contact.contact_charge).to eq group1_main_contact.contact_charge
      expect(new_main_contact.contact_tel).to eq group1_main_contact.contact_tel
      expect(new_main_contact.contact_fax).to eq group1_main_contact.contact_fax
      expect(new_main_contact.contact_email).to eq group1_main_contact.contact_email
      expect(new_main_contact.contact_link_url).to eq group1_main_contact.contact_link_url
    end
    Cms::Group.find(group1.id).contact_groups.ne(main_state: "main").first.tap do |new_sub_contact|
      expect(new_sub_contact.id).to eq group1_sub_contact.id
      expect(new_sub_contact.main_state).to be_blank
      expect(new_sub_contact.name).to eq group1_sub_contact.name
      expect(new_sub_contact.contact_group_name).to eq group1_main_contact.contact_group_name
      expect(new_sub_contact.contact_charge).to eq group1_sub_contact.contact_group_name
      # TEL からは変更はない
      expect(new_sub_contact.contact_tel).to eq group1_sub_contact.contact_tel
      expect(new_sub_contact.contact_fax).to eq group1_sub_contact.contact_fax
      expect(new_sub_contact.contact_email).to eq group1_sub_contact.contact_email
      expect(new_sub_contact.contact_link_url).to eq group1_sub_contact.contact_link_url
    end

    # group2 の連絡先に変更はないはず。
    Cms::Group.find(group2.id).contact_groups.where(main_state: "main").first.tap do |new_main_contact|
      expect(new_main_contact.id).to eq group2_main_contact.id
      expect(new_main_contact.main_state).to eq group2_main_contact.main_state
      expect(new_main_contact.name).to eq group2_main_contact.name
      expect(new_main_contact.contact_group_name).to eq group2_main_contact.contact_group_name
      expect(new_main_contact.contact_charge).to eq group2_main_contact.contact_charge
      expect(new_main_contact.contact_tel).to eq group2_main_contact.contact_tel
      expect(new_main_contact.contact_fax).to eq group2_main_contact.contact_fax
      expect(new_main_contact.contact_email).to eq group2_main_contact.contact_email
      expect(new_main_contact.contact_link_url).to eq group2_main_contact.contact_link_url
    end
    Cms::Group.find(group2.id).contact_groups.ne(main_state: "main").first.tap do |new_sub_contact|
      expect(new_sub_contact.id).to eq group2_sub_contact.id
      expect(new_sub_contact.main_state).to be_blank
      expect(new_sub_contact.name).to eq group2_sub_contact.name
      expect(new_sub_contact.contact_group_name).to eq group2_sub_contact.contact_group_name
      expect(new_sub_contact.contact_charge).to eq group2_sub_contact.contact_charge
      expect(new_sub_contact.contact_tel).to eq group2_sub_contact.contact_tel
      expect(new_sub_contact.contact_fax).to eq group2_sub_contact.contact_fax
      expect(new_sub_contact.contact_email).to eq group2_sub_contact.contact_email
      expect(new_sub_contact.contact_link_url).to eq group2_sub_contact.contact_link_url
    end
  end
end
