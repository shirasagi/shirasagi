require 'spec_helper'

describe "gws_portal_circluar", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:folder) { create(:gws_notice_folder) }

  let(:preset) { user.find_portal_preset(cur_user: user, cur_site: site) }
  let(:preset_setting) { preset.portal_setting }
  let(:preset_portlet) { preset_setting.portlets.where(portlet_model: "circular").first }

  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:post1) do
    create(:gws_circular_post, due_date: now + 1.day, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post2) do
    create(:gws_circular_post, due_date: now + 2.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post3) do
    create(:gws_circular_post, due_date: now + 3.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post4) do
    create(:gws_circular_post, due_date: now + 4.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post5) do
    create(:gws_circular_post, due_date: now + 5.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post6) do
    create(:gws_circular_post, due_date: now + 6.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post7) do
    create(:gws_circular_post, due_date: now + 7.days, member_ids: [user.id], state: "public")
  end
  let!(:post8) do
    create(:gws_circular_post, due_date: now + 8.days, member_ids: [user.id], state: "public")
  end
  let!(:post9) do
    create(:gws_circular_post, due_date: now + 9.days, member_ids: [user.id], state: "public")
  end
  let!(:post10) do
    create(:gws_circular_post, due_date: now + 10.days, member_ids: [user.id], state: "public")
  end
  let!(:post11) do
    create(:gws_circular_post, due_date: now + 11.days, member_ids: [user.id], state: "public")
  end
  let!(:post12) do
    create(:gws_circular_post, due_date: now + 12.days, member_ids: [user.id], state: "public")
  end

  before do
    create_default_portal
    login_gws_user
  end

  context "default both" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.new')
      within ".main-box [data-id='#{preset_portlet.id}']" do
        click_on I18n.t('ss.buttons.add')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-boards" do
          expect(page).to have_css(".list-item", text: post1.name)
          expect(page).to have_css(".list-item", text: post2.name)
          expect(page).to have_css(".list-item", text: post3.name)
          expect(page).to have_css(".list-item", text: post4.name)
          expect(page).to have_css(".list-item", text: post5.name)
          expect(page).to have_no_css(".list-item", text: post6.name)
          expect(page).to have_no_css(".list-item", text: post7.name)
          expect(page).to have_no_css(".list-item", text: post8.name)
          expect(page).to have_no_css(".list-item", text: post9.name)
          expect(page).to have_no_css(".list-item", text: post10.name)
          expect(page).to have_no_css(".list-item", text: post11.name)
          expect(page).to have_no_css(".list-item", text: post12.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-boards" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index.gws-boards" do
        expect(page).to have_css(".list-item", text: post1.name)
        expect(page).to have_css(".list-item", text: post2.name)
        expect(page).to have_css(".list-item", text: post3.name)
        expect(page).to have_css(".list-item", text: post4.name)
        expect(page).to have_css(".list-item", text: post5.name)
        expect(page).to have_css(".list-item", text: post6.name)
        expect(page).to have_css(".list-item", text: post7.name)
        expect(page).to have_css(".list-item", text: post8.name)
        expect(page).to have_css(".list-item", text: post9.name)
        expect(page).to have_css(".list-item", text: post10.name)
        expect(page).to have_css(".list-item", text: post11.name)
        expect(page).to have_css(".list-item", text: post12.name)
      end
    end
  end

  context "default unseen" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.new')
      within ".main-box [data-id='#{preset_portlet.id}']" do
        click_on I18n.t('ss.buttons.add')
      end
      within 'form#item-form' do
        select I18n.t("gws/circular.options.article_state.unseen"), from: "item[circular_article_state]"
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-boards" do
          expect(page).to have_no_css(".list-item", text: post1.name)
          expect(page).to have_no_css(".list-item", text: post2.name)
          expect(page).to have_no_css(".list-item", text: post3.name)
          expect(page).to have_no_css(".list-item", text: post4.name)
          expect(page).to have_no_css(".list-item", text: post5.name)
          expect(page).to have_no_css(".list-item", text: post6.name)
          expect(page).to have_css(".list-item", text: post7.name)
          expect(page).to have_css(".list-item", text: post8.name)
          expect(page).to have_css(".list-item", text: post9.name)
          expect(page).to have_css(".list-item", text: post10.name)
          expect(page).to have_css(".list-item", text: post11.name)
          expect(page).to have_no_css(".list-item", text: post12.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-boards" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index.gws-boards" do
        expect(page).to have_no_css(".list-item", text: post1.name)
        expect(page).to have_no_css(".list-item", text: post2.name)
        expect(page).to have_no_css(".list-item", text: post3.name)
        expect(page).to have_no_css(".list-item", text: post4.name)
        expect(page).to have_no_css(".list-item", text: post5.name)
        expect(page).to have_no_css(".list-item", text: post6.name)
        expect(page).to have_css(".list-item", text: post7.name)
        expect(page).to have_css(".list-item", text: post8.name)
        expect(page).to have_css(".list-item", text: post9.name)
        expect(page).to have_css(".list-item", text: post10.name)
        expect(page).to have_css(".list-item", text: post11.name)
        expect(page).to have_css(".list-item", text: post12.name)
      end
    end
  end
end
