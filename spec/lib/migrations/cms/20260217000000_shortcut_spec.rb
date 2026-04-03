require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20260217000000_shortcut.rb")

# 古いシラサギでは shortcut に "show" を設定していた。それを shortcuts に "system" と "quota" をセットする。
RSpec.describe SS::Migration20260217000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node1) do
    node = create(:article_node_page, cur_site: site)
    node.collection.update_one({ _id: node.id }, { '$set' => { shortcut: "show" } })
    node.unset(:shortcuts)
    Cms::Node.find(node.id)
  end
  let!(:node2) do
    node = create(:article_node_page, cur_site: site, shortcuts: [ Cms::Node::SHORTCUT_NAVI ])
    node.collection.update_one({ _id: node.id }, { '$set' => { shortcut: "show" } })
    Cms::Node.find(node.id)
  end

  before do
    described_class.new.change
  end

  it do
    Cms::Node.find(node1.id).tap do |node_after_migration|
      expect(node_after_migration.shortcuts).to have(2).items
      expect(node_after_migration.shortcuts).to include(Cms::Node::SHORTCUT_SYSTEM, Cms::Node::SHORTCUT_QUOTA)
      expect(node_after_migration.attributes.key?("shortcut")).to be_falsey
    end
    Cms::Node.find(node2.id).tap do |node_after_migration|
      expect(node_after_migration.shortcuts).to have(1).items
      expect(node_after_migration.shortcuts).to include(Cms::Node::SHORTCUT_NAVI)
      expect(node_after_migration.attributes.key?("shortcut")).to be_falsey
    end
  end
end
