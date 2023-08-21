require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20200204000000_portal_name.rb")

RSpec.describe SS::Migration20200204000000, dbscope: :example do
  let!(:group0) { create :gws_group }
  let!(:group1) { create :gws_group, name: "#{group0.name}/#{unique_id}" }
  let!(:portal_name0) { "portal-#{unique_id}" }
  let!(:portal_name1) { "portal-#{unique_id}" }
  let!(:organization_portal_setting) do
    Gws::Portal::GroupSetting.create(cur_site: group0, portal_group: group0, name: portal_name0)
  end
  let!(:group_portal_setting) do
    Gws::Portal::GroupSetting.create(cur_site: group0, portal_group: group1, name: portal_name1)
  end

  before do
    described_class.new.change
  end

  it do
    organization_portal_setting.reload
    expect(organization_portal_setting.name).to eq I18n.t("gws/portal.tabs.root_portal")

    group_portal_setting.reload
    expect(group_portal_setting.name).to eq portal_name1
  end
end
