require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20251023000000_loop_setting.rb")

RSpec.describe SS::Migration20251023000000, dbscope: :example do
  let!(:site) { cms_site }

  let!(:loop_setting_with_nil) do
    create(:cms_loop_setting,
      site: site,
      html: "<div><% if true %>Hello<% end %></div>",
      state: 'public',
      html_format: 'shirasagi')
  end

  let!(:loop_setting_preserved) do
    create(:cms_loop_setting,
      site: site,
      html: "<div>{{ item.title }}</div>",
      state: 'closed',
      html_format: 'liquid')
  end

  before do
    # Set fields to nil using direct database update
    loop_setting_with_nil.collection.update_one(
      { "_id" => loop_setting_with_nil._id },
      { "$unset" => { "state" => "", "html_format" => "" } }
    )
    loop_setting_with_nil.reload

    # Check that fields are actually unset in the database
    raw_doc = loop_setting_with_nil.collection.find({ "_id" => loop_setting_with_nil._id }).first
    expect(raw_doc["state"]).to be_nil
    expect(raw_doc["html_format"]).to be_nil

    described_class.new.change
  end

  it "sets defaults for nil attributes without altering HTML" do
    loop_setting_with_nil.reload

    expect(loop_setting_with_nil[:state]).to eq 'public'
    expect(loop_setting_with_nil[:html_format]).to eq 'shirasagi'
    expect(loop_setting_with_nil[:html]).to eq "<div><% if true %>Hello<% end %></div>"
  end

  it "keeps existing values when already present" do
    loop_setting_preserved.reload

    expect(loop_setting_preserved[:state]).to eq 'closed'
    expect(loop_setting_preserved[:html_format]).to eq 'liquid'
    expect(loop_setting_preserved[:html]).to eq "<div>{{ item.title }}</div>"
  end
end
