require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20250310000000_history_data.rb")

RSpec.describe SS::Migration20250310000000, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let!(:group) { create(:cms_group, name: unique_id) }
  let!(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
  let!(:node) { create :article_node_page, filename: "docs", name: "article" }
  let!(:item1) do
    item = nil
    Timecop.freeze(now - 3.hours) do
      item = create(:article_page, cur_node: node, cur_user: user1, group_ids: user1.group_ids, state: "closed")
    end
    Timecop.freeze(now - 2.hours) do
      item.update!(html: unique_id)
    end
    Timecop.freeze(now - 1.hour) do
      item.update!(html: unique_id)
    end

    item.backups.unset(:ref_id)

    item.class.find(item.id)
  end
  let!(:item2) do
    item = nil
    Timecop.freeze(now - 2.hours) do
      item = create(:article_page, cur_node: node, cur_user: cms_user, group_ids: cms_user.group_ids, state: "public")
    end
    Timecop.freeze(now - 2.hours) do
      item.update!(html: unique_id)
    end
    Timecop.freeze(now - 1.hour) do
      item.update!(html: unique_id)
    end

    item.backups.unset(:ref_id)

    item.class.find(item.id)
  end

  before do
    described_class.new.change
  end

  it do
    item1.reload
    item1.backups.to_a.tap do |backups|
      backups.each do |backup|
        expect(backup.ref_id).to eq item1.id
      end
    end

    item2.reload
    item2.backups.to_a.tap do |backups|
      backups.each do |backup|
        expect(backup.ref_id).to eq item2.id
      end
    end
  end
end
