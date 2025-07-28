require 'spec_helper'
require Rails.root.join("lib/migrations/event/20240903000000_calendar_tabs.rb")

RSpec.describe SS::Migration20240903000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:item1) { create :event_node_page, cur_site: site }
  let!(:item2) { create :event_node_page, cur_site: site }
  let!(:item3) { create :event_node_page, cur_site: site }
  let!(:item4) { create :event_node_page, cur_site: site }

  it do
    item1.set(event_display: "list")
    item1.unset(:event_display_tabs)

    item2.set(event_display: "table")
    item2.unset(:event_display_tabs)

    item3.set(event_display: "list_only")
    item3.unset(:event_display_tabs)

    item4.set(event_display: "table_only")
    item4.unset(:event_display_tabs)

    described_class.new.change
    item1.reload
    item2.reload
    item3.reload
    item4.reload

    expect(item1.event_display).to eq "list"
    expect(item1.event_display_tabs).to eq %w(list table)

    expect(item2.event_display).to eq "table"
    expect(item2.event_display_tabs).to eq %w(list table)

    expect(item3.event_display).to eq "list"
    expect(item3.event_display_tabs).to eq %w(list)

    expect(item4.event_display).to eq "table"
    expect(item4.event_display_tabs).to eq %w(table)
  end
end
