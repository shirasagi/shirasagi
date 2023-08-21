require 'spec_helper'

describe "sys_groups", type: :feature, dbscope: :example, js: true do
  it "without auth" do
    login_ss_user
    visit sys_groups_path
    expect(current_path).to eq sys_groups_path
    expect(page).to have_title("403")
  end

  context "basic crud" do
    before { login_sys_user }

    it do
      visit sys_groups_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Sys::Group.unscoped.count).to eq 1
      item = Sys::Group.unscoped.first
      expect(item.name).to eq "sample"
      expect(item.active?).to be_truthy

      visit sys_groups_path
      click_on item.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq "modify"
      expect(item.active?).to be_truthy

      visit sys_groups_path
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      item.reload
      expect(item.active?).to be_falsey
    end
  end

  context "gws_use" do
    before { login_sys_user }

    context "on root group" do
      let(:name) { unique_id }

      it do
        visit sys_groups_path
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          expect(page).to have_no_css("select[name='item[gws_use]']")

          fill_in "item[name]", with: name
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        visit sys_groups_path
        click_on name
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          expect(page).to have_css("select[name='item[gws_use]']")

          select I18n.t("ss.options.gws_use.enabled"), from: "item[gws_use]"
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
      end
    end

    context "on child group" do
      let!(:item) { create(:sys_group) }
      let(:name) { "#{item.name}/#{unique_id}" }

      it do
        visit sys_groups_path
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          expect(page).to have_no_css("select[name='item[gws_use]']")

          fill_in "item[name]", with: name
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        visit sys_groups_path
        click_on name
        click_on I18n.t("ss.links.edit")
        expect(page).to have_no_css("select[name='item[gws_use]']")
      end
    end
  end

  context "import from csv" do
    before { login_sys_user }

    it "#import" do
      visit sys_groups_path
      click_on I18n.t("ss.links.import")

      perform_enqueued_jobs do
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/group/sys_groups_1.csv"
          page.accept_confirm(I18n.t("ss.confirm.import")) do
            click_on I18n.t('ss.buttons.import')
          end
        end
        wait_for_notice I18n.t('ss.notice.started_import')
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(/INFO -- : .* 7件のグループをインポートしました。/)
        expect(log.state).to eq "completed"
      end

      groups = Sys::Group.all
      expect(groups.count).to eq 7
      groups.find_by(name: "A").tap do |g|
        expect(g.order).to eq 10
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to eq "enabled"
        expect(g.ldap_dn).to eq "cn=Manager,dc=city,dc=shirasagi,dc=jp"
        expect(g.contact_group_name).to eq "部署A"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/A/"
        expect(g.contact_link_name).to eq "A"
      end
      groups.find_by(name: "A/B").tap do |g|
        expect(g.order).to eq 20
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署B"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/B/"
        expect(g.contact_link_name).to eq "B"
      end
      groups.find_by(name: "A/B/C").tap do |g|
        expect(g.order).to eq 30
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署C"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/B/C/"
        expect(g.contact_link_name).to eq "C"
      end
      groups.find_by(name: "A/B/C/D").tap do |g|
        expect(g.order).to eq 40
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署D"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/B/C/D/"
        expect(g.contact_link_name).to eq "D"
      end
      groups.find_by(name: "A/E").tap do |g|
        expect(g.order).to eq 50
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署E"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/E/"
        expect(g.contact_link_name).to eq "E"
      end
      groups.find_by(name: "A/E/F").tap do |g|
        expect(g.order).to eq 60
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署F"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/E/F/"
        expect(g.contact_link_name).to eq "F"
      end
      groups.find_by(name: "A/E/G").tap do |g|
        expect(g.order).to eq 70
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.gws_use).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署G"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_link_url).to eq "/E/G/"
        expect(g.contact_link_name).to eq "G"
      end
    end
  end
end
