require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20190913000000_set_notification_noticed_to_gws_board.rb")

RSpec.describe SS::Migration20190913000000, dbscope: :example do
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:topic1) { create(:gws_board_topic, notify_state: "enabled", state: "public", deleted: nil) }
  let!(:topic2) { create(:gws_board_topic, notify_state: "disabled", state: "public", deleted: nil) }
  let!(:topic3) { create(:gws_board_topic, notify_state: "enabled", state: "close", deleted: nil) }
  let!(:topic4) { create(:gws_board_topic, notify_state: "enabled", state: "public", deleted: now) }

  before do
    travel_to(now) do
      described_class.new.change
    end
  end

  it do
    topic1.reload
    expect(topic1.notification_noticed_at).to eq now

    topic2.reload
    expect(topic2.notification_noticed_at).to be_blank

    topic3.reload
    expect(topic3.notification_noticed_at).to be_blank

    topic4.reload
    expect(topic4.notification_noticed_at).to eq now
  end
end
