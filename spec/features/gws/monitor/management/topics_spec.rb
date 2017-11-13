require 'spec_helper'

describe "gws_monitor_management_topics", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_monitor_topic, :gws_monitor_management_topics }
  let(:item2) { create :gws_monitor_topic, :gws_monitor_admins_item2 }
  let(:index_path) { gws_monitor_management_topics_path site, gws_user }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#index display all group when spec_config = 0" do
      item2
      visit index_path
      wait_for_ajax
      expect(page).to have_content('回答状況(1/2)')
    end

    it "#edit" do
      item
      visit "/.g#{site._id}/monitor/management/topics/#{item.id}/edit"
      wait_for_ajax
      expect(page).to have_content('基本情報')
    end

    it "#show" do
      item
      visit "/.g#{site._id}/monitor/management/topics/#{item.id}"
      wait_for_ajax
      expect(page).to have_content(item.name)
    end
  end
end
