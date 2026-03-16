require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  context "Gws::Addon::Elasticsearch::GroupSetting" do
    context "basic crud" do
      let(:elasticsearch_host) { unique_domain }
      let(:elasticsearch_user) { "user-#{unique_id}" }
      let(:elasticsearch_password) { "pass-#{unique_id}" }
      let(:elasticsearch_ssl_verify_mode) { %w(none peer).sample }

      it do
        login_user user, to: gws_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          # open addon
          ensure_addon_opened("#addon-gws-agents-addons-elasticsearch-group_setting")

          # fill form
          within "#addon-gws-agents-addons-elasticsearch-group_setting" do
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
          ensure_addon_opened("#addon-gws-agents-addons-elasticsearch-group_setting")
          within "#addon-gws-agents-addons-elasticsearch-group_setting" do
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
        login_user user, to: gws_site_path(site: site)
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          # open addon
          ensure_addon_opened("#addon-gws-agents-addons-elasticsearch-group_setting")

          # fill form
          within "#addon-gws-agents-addons-elasticsearch-group_setting" do
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
