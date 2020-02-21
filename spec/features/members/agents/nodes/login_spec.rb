require 'spec_helper'

describe 'members/agents/nodes/login', type: :feature, dbscope: :example do
  describe "ss-2724" do
    let(:root_site) { cms_site }
    let(:site1) { create(:cms_site_subdir, domains: root_site.domains) }
    let(:site2) { create(:cms_site_subdir, domains: root_site.domains) }

    let(:site1_layout) { create_cms_layout(cur_site: site1) }
    let(:site2_layout) { create_cms_layout(cur_site: site2) }

    let!(:site1_my_page) { create :member_node_mypage, cur_site: site1, layout_id: site1_layout.id }
    let!(:site2_my_page) { create :member_node_mypage, cur_site: site2, layout_id: site2_layout.id }
    let!(:site1_my_profile) do
      create :member_node_my_profile, cur_site: site1, cur_node: site1_my_page, layout_id: site1_layout.id
    end
    let!(:site2_my_profile) do
      create :member_node_my_profile, cur_site: site2, cur_node: site2_my_page, layout_id: site2_layout.id
    end
    let!(:site1_login) do
      create(
        :member_node_login, cur_site: site1, layout_id: site1_layout.id, redirect_url: site1_my_profile.url,
        form_auth: "enabled"
      )
    end
    let!(:site2_login) do
      create(
        :member_node_login, cur_site: site2, layout_id: site2_layout.id, redirect_url: site2_my_profile.url,
        form_auth: "enabled"
      )
    end

    let!(:site1_member) { create :cms_member, cur_site: site1 }

    it do
      visit site1_login.full_url

      within ".form-login" do
        fill_in "item[email]", with: site1_member.email
        fill_in "item[password]", with: site1_member.in_password

        click_on I18n.t("ss.login")
      end

      visit site2_my_profile.full_url
      expect(page).to have_css(".form-login")
    end
  end
end
