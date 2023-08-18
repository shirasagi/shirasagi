require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20200918000000_user_settings.rb")

RSpec.describe SS::Migration20200918000000, dbscope: :example do
  let(:now) { Time.zone.now.beginning_of_minute }
  let(:user_id1) { rand(0..10) }
  let(:user_id2) { rand(11..20) }
  let(:user_id3) { rand(21..30) }
  let!(:n1) do
    create(:ss_notification, member_ids: [ user_id1, user_id2, user_id3 ])
  end
  let!(:n2) do
    create(:ss_notification, member_ids: [ user_id1, user_id2, user_id3 ])
  end
  let!(:n3) do
    create(:ss_notification, member_ids: [ user_id1, user_id2, user_id3 ])
  end
  let!(:n4) do
    create(:ss_notification, member_ids: [ user_id1, user_id2, user_id3 ])
  end

  before do
    n1.set(deleted: now)
    # n2.set(deleted: { user_id1.to_s => now })
    n2.send(:persist_atomic_operations, "$set" => { deleted: { user_id1.to_s => now.utc } })
    # n3.set(seen: { user_id2.to_s => now })
    n3.send(:persist_atomic_operations, "$set" => { seen: { user_id2.to_s => now.utc } })
    # n4.set(deleted: { user_id1.to_s => now, user_id3.to_s => now }, seen: ...)
    n4.send(
      :persist_atomic_operations,
      "$set" => {
        deleted: { user_id1.to_s => now.utc, user_id3.to_s => now.utc },
        seen: { user_id2.to_s => now.utc, user_id3.to_s => now.utc }
      }
    )

    n1.reload
    n2.reload
    n3.reload
    n4.reload

    described_class.new.change
  end

  it do
    # n1
    n1.reload
    expect(n1.user_settings).to be_blank

    # n2
    expect(n2.user_settings).to be_blank
    expect(n2.attributes["deleted"]).to be_present
    expect(n2.attributes["seen"]).to be_blank
    n2.reload
    expect(n2.user_settings.length).to eq 1
    expect(n2.send(:find_user_setting, user_id1, "deleted")).to be_present
    expect(n2.send(:find_user_setting, user_id2, "deleted")).to be_blank
    expect(n2.send(:find_user_setting, user_id3, "deleted")).to be_blank
    expect(n2.attributes["deleted"]).to be_blank
    expect(n2.attributes["seen"]).to be_blank

    # n3
    expect(n3.user_settings).to be_blank
    expect(n3.attributes["deleted"]).to be_blank
    expect(n3.attributes["seen"]).to be_present
    n3.reload
    expect(n3.user_settings.length).to eq 1
    expect(n3.send(:find_user_setting, user_id1, "seen_at")).to be_blank
    expect(n3.send(:find_user_setting, user_id2, "seen_at")).to be_present
    expect(n3.send(:find_user_setting, user_id3, "seen_at")).to be_blank
    expect(n3.attributes["deleted"]).to be_blank
    expect(n3.attributes["seen"]).to be_blank

    # n4
    expect(n4.user_settings).to be_blank
    expect(n4.attributes["deleted"]).to be_present
    expect(n4.attributes["seen"]).to be_present
    n4.reload
    expect(n4.user_settings.length).to eq 3
    # user_settings は user_id の昇順でなければならない
    expect(n4.user_settings.find_index { |user_state| user_state["user_id"] == user_id1 }).to eq 0
    expect(n4.user_settings.find_index { |user_state| user_state["user_id"] == user_id2 }).to eq 1
    expect(n4.user_settings.find_index { |user_state| user_state["user_id"] == user_id3 }).to eq 2
    # ユーザーごとの状態が正しいか？
    expect(n4.send(:find_user_setting, user_id1, "deleted")).to be_present
    expect(n4.send(:find_user_setting, user_id2, "deleted")).to be_blank
    expect(n4.send(:find_user_setting, user_id3, "deleted")).to be_present
    expect(n4.send(:find_user_setting, user_id1, "seen_at")).to be_blank
    expect(n4.send(:find_user_setting, user_id2, "seen_at")).to be_present
    expect(n4.send(:find_user_setting, user_id3, "seen_at")).to be_present
    # 古い廃止された属性が削除されているか？
    expect(n4.attributes.key?("deleted")).to be_falsey
    expect(n4.attributes.key?("seen")).to be_falsey
  end
end
