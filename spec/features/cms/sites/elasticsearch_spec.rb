require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  context "SS::Addon::Elasticsearch::SiteSetting" do
    context "basic crud" do
      let(:elasticsearch_host) { unique_domain }
      let(:elasticsearch_user) { "user-#{unique_id}" }
      let(:elasticsearch_password) { "pass-#{unique_id}" }
      let(:elasticsearch_ssl_verify_mode) { %w(none peer).sample }

      it do
        login_user user, to: cms_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          # open addon
          ensure_addon_opened("#addon-ss-agents-addons-elasticsearch-site_setting")

          # fill form
          within "#addon-ss-agents-addons-elasticsearch-site_setting" do
            fill_in "item[elasticsearch_hosts]", with: elasticsearch_host
            fill_in "item[elasticsearch_user]", with: elasticsearch_user
            fill_in "item[in_elasticsearch_password]", with: elasticsearch_password
            select elasticsearch_ssl_verify_mode, from: "item[elasticsearch_ssl_verify_mode]"
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        site.reload
        expect(site.elasticsearch_hosts).to eq [ elasticsearch_host ]
        expect(site.elasticsearch_user).to eq elasticsearch_user
        expect(SS::Crypto.decrypt(site.elasticsearch_password)).to eq elasticsearch_password
        expect(site.elasticsearch_ssl_verify_mode).to eq elasticsearch_ssl_verify_mode

        # edit again
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        site.reload
        expect(site.elasticsearch_hosts).to eq [ elasticsearch_host ]
        expect(site.elasticsearch_user).to eq elasticsearch_user
        expect(SS::Crypto.decrypt(site.elasticsearch_password)).to eq elasticsearch_password
        expect(site.elasticsearch_ssl_verify_mode).to eq elasticsearch_ssl_verify_mode

        # delete password
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          ensure_addon_opened("#addon-ss-agents-addons-elasticsearch-site_setting")
          within "#addon-ss-agents-addons-elasticsearch-site_setting" do
            check I18n.t("ss.links.delete")
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        site.reload
        expect(site.elasticsearch_hosts).to eq [ elasticsearch_host ]
        expect(site.elasticsearch_user).to eq elasticsearch_user
        expect(site.elasticsearch_password).to be_blank
        expect(site.elasticsearch_ssl_verify_mode).to eq elasticsearch_ssl_verify_mode
      end
    end

    context "multiple hosts" do
      let(:elasticsearch_hosts) { Array.new(2) { unique_url } }
      let(:elasticsearch_user) { "user-#{unique_id}" }
      let(:elasticsearch_password) { "pass-#{unique_id}" }
      let(:elasticsearch_ssl_verify_mode) { %w(none peer).sample }

      it do
        login_user user, to: cms_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          # open addon
          ensure_addon_opened("#addon-ss-agents-addons-elasticsearch-site_setting")

          # fill form
          within "#addon-ss-agents-addons-elasticsearch-site_setting" do
            fill_in "item[elasticsearch_hosts]", with: elasticsearch_hosts.join(", ")
            fill_in "item[elasticsearch_user]", with: elasticsearch_user
            fill_in "item[in_elasticsearch_password]", with: elasticsearch_password
            select elasticsearch_ssl_verify_mode, from: "item[elasticsearch_ssl_verify_mode]"
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        site.reload
        expect(site.elasticsearch_hosts).to eq elasticsearch_hosts
        expect(site.elasticsearch_user).to eq elasticsearch_user
        expect(SS::Crypto.decrypt(site.elasticsearch_password)).to eq elasticsearch_password
        expect(site.elasticsearch_ssl_verify_mode).to eq elasticsearch_ssl_verify_mode
      end
    end
  end
end
