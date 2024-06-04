require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:ad_width) { rand(300..400) }
  let(:ad_speed) { rand(10..30) }
  let(:ad_pause) { rand(60..90) }
  let(:url) { "http://#{unique_id}.example.jp/" }

  before do
    login_gws_user
  end

  context "when ad portlet is created" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on I18n.t('ss.links.new')
      within '.main-box' do
        click_on I18n.t('gws/portal.portlets.ad.name')
      end
      within 'form#item-form' do
        within "#addon-gws-agents-addons-portal-portlet-ad" do
          fill_in "item[ad_width]", with: ad_width.to_s
          fill_in "item[ad_speed]", with: ad_speed.to_s
          fill_in "item[ad_pause]", with: ad_pause.to_s
        end

        within "#addon-gws-agents-addons-portal-portlet-ad_file" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
        end
      end
      within_cbox do
        attach_file "item[in_files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        wait_for_cbox_closed { click_on I18n.t("ss.buttons.attach") }
      end
      within 'form#item-form' do
        within "#addon-gws-agents-addons-portal-portlet-ad_file" do
          within first(".file-view") do
            first("input[type='text']").send_keys url
          end
        end

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Portal::UserPortlet.all.site(site).user(user).where(name: I18n.t('gws/portal.portlets.ad.name')).count).to eq 1
      portlet = Gws::Portal::UserPortlet.all.site(site).user(user).where(name: I18n.t('gws/portal.portlets.ad.name')).first
      expect(portlet.portlet_model).to eq "ad"
      expect(portlet.ad_width).to eq ad_width
      expect(portlet.ad_speed).to eq ad_speed
      expect(portlet.ad_pause).to eq ad_pause
      expect(portlet.ad_files.count).to eq 1
      portlet.ad_files.first.becomes_with(SS::LinkFile).tap do |file|
        expect(file.name).to eq "logo.png"
        expect(file.filename).to eq "logo.png"
        expect(file.site_id).to be_blank
        expect(file.model).to eq Gws::Portal::UserPortlet.model_name.i18n_key.to_s
        expect(file.owner_item_id).to eq portlet.id
        expect(file.owner_item_type).to eq portlet.class.name
        expect(file.link_url).to eq url
      end

      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.arrange_portlets')
      # wait for ajax completion
      expect(page).to have_css(".portlet-model-ad[data-id='#{portlet.id}']", text: portlet.name)
      click_on I18n.t('gws/portal.buttons.save_layouts')
      wait_for_notice I18n.t('ss.notice.saved')
      portlet.reload
      portlet.ad_files.first.becomes_with(SS::LinkFile).tap do |file|
        expect(file.name).to eq "logo.png"
        expect(file.filename).to eq "logo.png"
        expect(file.site_id).to be_blank
        expect(file.model).to eq Gws::Portal::UserPortlet.model_name.i18n_key.to_s
        expect(file.owner_item_id).to eq portlet.id
        expect(file.owner_item_type).to eq portlet.class.name
        expect(file.link_url).to eq url
      end

      visit gws_portal_user_path(site: site, user: user)
      expect(page).to have_css('.portlets .portlet-model-ad')
    end
  end

  context "when ad portlet is deleted" do
    let!(:setting) { create :gws_portal_user_setting, cur_user: user }
    let!(:portlet) { create :gws_portal_user_portlet, :gws_portal_ad_portlet, cur_user: user, setting: setting }

    it do
      expect(portlet.ad_files.count).to eq 1
      save_file = portlet.ad_files.first

      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on portlet.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within 'form#item-form' do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { portlet.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { save_file.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "when only ad image on ad portlet is deleted" do
    let!(:setting) { create :gws_portal_user_setting, cur_user: user }
    let!(:portlet) { create :gws_portal_user_portlet, :gws_portal_ad_portlet, cur_user: user, setting: setting }

    it do
      expect(portlet.ad_files.count).to eq 1
      save_file = portlet.ad_files.first

      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')
      click_on portlet.name
      click_on I18n.t("ss.links.edit")
      within 'form#item-form' do
        within "#addon-gws-agents-addons-portal-portlet-ad_file" do
          within first(".file-view") do
            click_on I18n.t("ss.buttons.delete")
          end
        end

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      portlet.reload
      expect(portlet.ad_files.count).to eq 0

      expect { save_file.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
