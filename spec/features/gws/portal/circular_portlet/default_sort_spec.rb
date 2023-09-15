require 'spec_helper'

describe "gws_portal_circluar", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:folder) { create(:gws_notice_folder) }

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
    login_gws_user
  end

  context "default due_date_asc" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.circular.name')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-boards" do
          expect(all(".list-item").size).to eq 5
          expect(all(".list-item")[0].text).to include(post1.name)
          expect(all(".list-item")[1].text).to include(post2.name)
          expect(all(".list-item")[2].text).to include(post3.name)
          expect(all(".list-item")[3].text).to include(post4.name)
          expect(all(".list-item")[4].text).to include(post5.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-boards" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index.gws-boards" do
        expect(all(".list-item").size).to eq 12
        expect(all(".list-item")[0].text).to include(post1.name)
        expect(all(".list-item")[1].text).to include(post2.name)
        expect(all(".list-item")[2].text).to include(post3.name)
        expect(all(".list-item")[3].text).to include(post4.name)
        expect(all(".list-item")[4].text).to include(post5.name)
        expect(all(".list-item")[5].text).to include(post6.name)
        expect(all(".list-item")[6].text).to include(post7.name)
        expect(all(".list-item")[7].text).to include(post8.name)
        expect(all(".list-item")[8].text).to include(post9.name)
        expect(all(".list-item")[9].text).to include(post10.name)
        expect(all(".list-item")[10].text).to include(post11.name)
        expect(all(".list-item")[11].text).to include(post12.name)
      end
    end
  end

  context "default due_date_desc" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.circular.name')
      end
      within 'form#item-form' do
        select I18n.t("gws/circular.options.sort.due_date_desc"), from: "item[circular_sort]"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-boards" do
          expect(all(".list-item").size).to eq 5
          expect(all(".list-item")[0].text).to include(post12.name)
          expect(all(".list-item")[1].text).to include(post11.name)
          expect(all(".list-item")[2].text).to include(post10.name)
          expect(all(".list-item")[3].text).to include(post9.name)
          expect(all(".list-item")[4].text).to include(post8.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-boards" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index.gws-boards" do
        expect(all(".list-item").size).to eq 12
        expect(all(".list-item")[0].text).to include(post12.name)
        expect(all(".list-item")[1].text).to include(post11.name)
        expect(all(".list-item")[2].text).to include(post10.name)
        expect(all(".list-item")[3].text).to include(post9.name)
        expect(all(".list-item")[4].text).to include(post8.name)
        expect(all(".list-item")[5].text).to include(post7.name)
        expect(all(".list-item")[6].text).to include(post6.name)
        expect(all(".list-item")[7].text).to include(post5.name)
        expect(all(".list-item")[8].text).to include(post4.name)
        expect(all(".list-item")[9].text).to include(post3.name)
        expect(all(".list-item")[10].text).to include(post2.name)
        expect(all(".list-item")[11].text).to include(post1.name)
      end
    end
  end
end
