require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20240913000000_cms_contact_group_contact.rb")

RSpec.describe SS::Migration20240913000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:layout) { create_cms_layout }
  let!(:group1) do
    # group1 is sub group of group0
    create(
      :cms_group, name: "#{group0.name}/#{unique_id}",
      contact_groups: [{ name: unique_id, contact_email: unique_email, main_state: "main" }])
  end
  let!(:group2) do
    # 連絡先が未設定
    create(:cms_group, name: "#{group0.name}/#{unique_id}")
  end

  let!(:article_node) { create :article_node_page, cur_site: site, layout: layout, group_ids: [ group1.id ] }
  let!(:article_page1) do
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout,
      contact_state: "show", contact_group: group1, contact_group_contact: group1.contact_groups.first,
      group_ids: [ group1.id ])
  end
  let!(:article_page2) do
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout,
      contact_state: nil, contact_group: group1, contact_group_contact: group1.contact_groups.first,
      group_ids: [ group1.id ])
  end
  let!(:article_page3) do
    # 正しく設定されているのでマイグレーションが適用されない
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout,
      contact_state: "show", contact_group: group1, contact_group_contact: group1.contact_groups.first,
      group_ids: [ group1.id ])
  end
  let!(:article_page4) do
    # 連絡先が非表示のためマイグレーションを適用する必要がない
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout,
      contact_state: "hide", contact_group: group1, contact_group_contact: group1.contact_groups.first,
      group_ids: [ group1.id ])
  end
  let!(:article_page5) do
    # グループの連絡先が未設定のためマイグレーションを適用する必要がない
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout,
      contact_state: "show", contact_group: group2, group_ids: [ group2.id ])
  end

  before do
    article_page1.unset(:contact_group_contact_id)
    article_page2.unset(:contact_group_contact_id)

    described_class.new.change
  end

  it do
    # put your specs here
    Article::Page.find(article_page1.id).tap do |after_migration|
      expect(after_migration.contact_group_contact_id).to eq group1.contact_groups.first.id
      expect(after_migration.backups.count).to eq 2
    end
    Article::Page.find(article_page2.id).tap do |after_migration|
      expect(after_migration.contact_group_contact_id).to eq group1.contact_groups.first.id
      expect(after_migration.backups.count).to eq 2
    end
    Article::Page.find(article_page3.id).tap do |after_migration|
      # 正しく設定されているのでマイグレーションが適用されない
      expect(after_migration.contact_group_contact_id).to eq group1.contact_groups.first.id
      expect(after_migration.backups.count).to eq 1
    end
    Article::Page.find(article_page4.id).tap do |after_migration|
      # 連絡先が非表示のためマイグレーションを適用する必要がない
      expect(after_migration.contact_group_contact_id).to eq group1.contact_groups.first.id
      expect(after_migration.backups.count).to eq 1
    end
    Article::Page.find(article_page5.id).tap do |after_migration|
      # グループの連絡先が未設定のためマイグレーションを適用する必要がない
      expect(after_migration.contact_group_contact_id).to be_blank
      expect(after_migration.backups.count).to eq 1
    end
  end
end
