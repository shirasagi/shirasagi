require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20251010000000_loop_setting.rb")

RSpec.describe SS::Migration20251010000000, dbscope: :example do
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
    loop_setting_with_nil.set(state: nil, html_format: nil)
    loop_setting_with_nil.reload

    expect(loop_setting_with_nil[:state]).to be_nil
    expect(loop_setting_with_nil[:html_format]).to be_nil

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
