require 'spec_helper'

describe "member_agents_parts_photo_search", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node }
  let(:part)   { create :member_part_photo_search, cur_node: node }

  context "public" do
    before do
      node.layout = layout
      node.save!
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url

      wait_cbox_open { click_on I18n.t("member.buttons.detail_search") }
      within_cbox do
        click_on I18n.t('facility.submit.reset')
        click_on I18n.t('facility.submit.search')
      end
    end
  end
end
