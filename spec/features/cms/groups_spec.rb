require 'spec_helper'

describe "cms_groups", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  before { login_cms_user }

  context "basic crud" do
    it do
      visit cms_groups_path(site: site)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "cms_group/sample"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit cms_groups_path(site: site)
      click_on "sample"
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "cms_group/modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit cms_groups_path(site: site)
      click_on "modify"
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end

  context "import from csv" do
    let!(:root_group) do
      tel   = "000-000-0000"
      email = "sys@example.jp"
      postal_code = '0000000'
      address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
      link_url = "/"
      link_name = "http://demo.ss-proj.org/"
      g1 = create(
        :cms_group, name: "A", order: 10,
        contact_groups: [
          {
            main_state: 'main', name: unique_id,
            contact_tel: tel, contact_fax: tel, contact_email: email, contact_postal_code: postal_code,
            contact_address: address, contact_link_url: link_url, contact_link_name: link_name
          }
        ]
      )
      cms_site.add_to_set(group_ids: [g1.id])
      g1
    end

    it "#import" do
      visit cms_groups_path(site: site)
      click_on I18n.t("ss.links.import")

      perform_enqueued_jobs do
        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/group/cms_groups_1.csv"
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
        expect(log.logs).to include(/INFO -- : .* 6件のグループをインポートしました。/)
        expect(log.state).to eq "completed"
      end

      groups = Cms::Group.site(cms_site).nin(id: [ cms_group.id, root_group.id ])
      expect(groups.count).to eq 6
      groups.find_by(name: "A/B").tap do |g|
        expect(g.order).to eq 20
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.ldap_dn).to eq "cn=Manager,dc=city,dc=shirasagi,dc=jp"
        expect(g.contact_group_name).to eq "部署B"
        expect(g.contact_charge).to eq "係B"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_postal_code).to eq "0000000"
        expect(g.contact_address).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
        expect(g.contact_link_url).to eq "/B/"
        expect(g.contact_link_name).to eq "B"
      end
      groups.find_by(name: "A/B/C").tap do |g|
        expect(g.order).to eq 30
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署C"
        expect(g.contact_charge).to eq "係C"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_postal_code).to eq "0000000"
        expect(g.contact_address).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
        expect(g.contact_link_url).to eq "/B/C/"
        expect(g.contact_link_name).to eq "C"
      end
      groups.find_by(name: "A/B/C/D").tap do |g|
        expect(g.order).to eq 40
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署D"
        expect(g.contact_charge).to eq "係D"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_postal_code).to eq "0000000"
        expect(g.contact_address).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
        expect(g.contact_link_url).to eq "/B/C/D/"
        expect(g.contact_link_name).to eq "D"
      end
      groups.find_by(name: "A/E").tap do |g|
        expect(g.order).to eq 50
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署E"
        expect(g.contact_charge).to eq "係E"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_postal_code).to eq "0000000"
        expect(g.contact_address).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
        expect(g.contact_link_url).to eq "/E/"
        expect(g.contact_link_name).to eq "E"
      end
      groups.find_by(name: "A/E/F").tap do |g|
        expect(g.order).to eq 60
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署F"
        expect(g.contact_charge).to eq "係F"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_postal_code).to eq "0000000"
        expect(g.contact_address).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
        expect(g.contact_link_url).to eq "/E/F/"
        expect(g.contact_link_name).to eq "F"
      end
      groups.find_by(name: "A/E/G").tap do |g|
        expect(g.order).to eq 70
        expect(g.activation_date).to be_blank
        expect(g.expiration_date).to be_blank
        expect(g.ldap_dn).to be_blank
        expect(g.contact_group_name).to eq "部署G"
        expect(g.contact_charge).to eq "係G"
        expect(g.contact_tel).to eq "000-000-0000"
        expect(g.contact_fax).to eq "000-000-0000"
        expect(g.contact_email).to eq "sys@example.jp"
        expect(g.contact_postal_code).to eq "0000000"
        expect(g.contact_address).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
        expect(g.contact_link_url).to eq "/E/G/"
        expect(g.contact_link_name).to eq "G"
      end
    end
  end

  context "disable group and edit it" do
    let(:group_name) { unique_id }
    let!(:group) { create(:cms_group, name: "#{cms_group.name}/#{group_name}", order: 100) }
    let(:expiration_date) { Time.zone.now.days_ago(1).beginning_of_day }
    let(:contact_name) { unique_id }
    let(:contact_tel) { unique_tel }

    it do
      visit cms_groups_path(site: site)
      click_on group_name
      click_on I18n.t("ss.links.edit")
      wait_for_js_ready
      within "form#item-form" do
        fill_in_datetime "item[expiration_date]", with: expiration_date
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      group.reload
      expect(group.expiration_date).to eq expiration_date

      visit cms_groups_path(site: site)
      expect(page).to have_no_css(".expandable", text: group_name)

      select I18n.t("ss.options.state.all"), from: "s[state]"
      click_on I18n.t('ss.buttons.search')

      expect(page).to have_css(".expandable", text: group_name)

      click_on group_name
      click_on I18n.t("ss.links.edit")
      wait_for_js_ready
      within "form#item-form" do
        ensure_addon_opened "#addon-contact-agents-addons-group"
        within "#addon-contact-agents-addons-group" do
          within "tr[data-id='#{group.contact_groups.first.id}']" do
            first('[type="radio"][name="item[contact_groups][][main_state]"]').click
            fill_in "item[contact_groups][][name]", with: contact_name
            fill_in "item[contact_groups][][contact_tel]", with: contact_tel
          end
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      group.reload
      expect(group.contact_tel).to eq contact_tel
      expect(group.contact_groups[0].name).to eq contact_name
      expect(group.contact_groups[0].contact_tel).to eq contact_tel
      expect(group.contact_groups[0].main_state).to eq "main"
    end
  end

  context "contact" do
    context "basic crud" do
      let(:group_name) { unique_id }
      let(:contact_name1) { unique_id }
      let(:contact_group_name1) { unique_id }
      let(:contact_charge1) { unique_id }
      let(:contact_tel1) { unique_tel }
      let(:contact_fax1) { unique_tel }
      let(:contact_email1) { unique_email }
      let(:contact_postal_code1) { unique_id }
      let(:contact_address1) { unique_id }
      let(:contact_link_url1) { "/#{unique_id}/" }
      let(:contact_link_name1) { unique_id }
      let(:contact_name2) { unique_id }
      let(:contact_group_name2) { unique_id }
      let(:contact_charge2) { unique_id }
      let(:contact_tel2) { unique_tel }
      let(:contact_fax2) { unique_tel }
      let(:contact_email2) { unique_email }
      let(:contact_postal_code2) { unique_id }
      let(:contact_address2) { unique_id }
      let(:contact_link_url2) { "/#{unique_id}/" }
      let(:contact_link_name2) { unique_id }

      it do
        visit cms_groups_path(site: site)
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[name]", with: "#{cms_group.name}/#{group_name}"
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item = Cms::Group.all.site(site).where(name: "#{cms_group.name}/#{group_name}").first
        expect(item.contact_groups).to be_blank
        expect(item.contact_group_name).to be_blank
        expect(item.contact_charge).to be_blank
        expect(item.contact_tel).to be_blank
        expect(item.contact_fax).to be_blank
        expect(item.contact_email).to be_blank
        expect(item.contact_postal_code).to be_blank
        expect(item.contact_address).to be_blank
        expect(item.contact_link_url).to be_blank
        expect(item.contact_link_name).to be_blank

        visit cms_groups_path(site: site)
        click_on group_name
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          ensure_addon_opened "#addon-contact-agents-addons-group"
          within "#addon-contact-agents-addons-group" do
            within "tr[data-id='new']" do
              fill_in "item[contact_groups][][name]", with: contact_name1
              fill_in "item[contact_groups][][contact_group_name]", with: contact_group_name1
              fill_in "item[contact_groups][][contact_charge]", with: contact_charge1
              fill_in "item[contact_groups][][contact_tel]", with: contact_tel1
              fill_in "item[contact_groups][][contact_fax]", with: contact_fax1
              fill_in "item[contact_groups][][contact_email]", with: contact_email1
              fill_in "item[contact_groups][][contact_postal_code]", with: contact_postal_code1
              fill_in "item[contact_groups][][contact_address]", with: contact_address1
              fill_in "item[contact_groups][][contact_link_url]", with: contact_link_url1
              fill_in "item[contact_groups][][contact_link_name]", with: contact_link_name1
            end
          end
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        save_contact_group_id = nil
        item.reload
        expect(item.contact_groups.count).to eq 1
        item.contact_groups.first.tap do |contact_group|
          save_contact_group_id = contact_group.id
          expect(contact_group.name).to eq contact_name1
          expect(contact_group.contact_group_name).to eq contact_group_name1
          expect(contact_group.contact_charge).to eq contact_charge1
          expect(contact_group.contact_tel).to eq contact_tel1
          expect(contact_group.contact_email).to eq contact_email1
          expect(contact_group.contact_postal_code).to eq contact_postal_code1
          expect(contact_group.contact_address).to eq contact_address1
          expect(contact_group.contact_link_url).to eq contact_link_url1
          expect(contact_group.contact_link_name).to eq contact_link_name1
          expect(contact_group.main_state).to be_blank
        end
        expect(item.contact_group_name).to be_blank
        expect(item.contact_charge).to be_blank
        expect(item.contact_tel).to be_blank
        expect(item.contact_fax).to be_blank
        expect(item.contact_email).to be_blank
        expect(item.contact_postal_code).to be_blank
        expect(item.contact_address).to be_blank
        expect(item.contact_link_url).to be_blank
        expect(item.contact_link_name).to be_blank

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          ensure_addon_opened "#addon-contact-agents-addons-group"
          within "#addon-contact-agents-addons-group" do
            within "tr[data-id='#{save_contact_group_id}']" do
              first('[type="radio"][name="item[contact_groups][][main_state]"]').click
            end
          end
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.contact_groups.count).to eq 1
        item.contact_groups.first.tap do |contact_group|
          # ページから id で参照するので、編集のたびに変化してはいけない。一度採番する変化しない。
          expect(contact_group.id).to eq save_contact_group_id
          expect(contact_group.name).to eq contact_name1
          expect(contact_group.contact_group_name).to eq contact_group_name1
          expect(contact_group.contact_charge).to eq contact_charge1
          expect(contact_group.contact_tel).to eq contact_tel1
          expect(contact_group.contact_fax).to eq contact_fax1
          expect(contact_group.contact_email).to eq contact_email1
          expect(contact_group.contact_postal_code).to eq contact_postal_code1
          expect(contact_group.contact_address).to eq contact_address1
          expect(contact_group.contact_link_url).to eq contact_link_url1
          expect(contact_group.contact_link_name).to eq contact_link_name1
          expect(contact_group.main_state).to eq "main"
        end
        expect(item.contact_group_name).to eq contact_group_name1
        expect(item.contact_charge).to eq contact_charge1
        expect(item.contact_tel).to eq contact_tel1
        expect(item.contact_fax).to eq contact_fax1
        expect(item.contact_email).to eq contact_email1
        expect(item.contact_postal_code).to eq contact_postal_code1
        expect(item.contact_address).to eq contact_address1
        expect(item.contact_link_url).to eq contact_link_url1
        expect(item.contact_link_name).to eq contact_link_name1

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          ensure_addon_opened "#addon-contact-agents-addons-group"
          within "#addon-contact-agents-addons-group" do
            within "tr[data-id='new']" do
              fill_in "item[contact_groups][][name]", with: contact_name2
              fill_in "item[contact_groups][][contact_group_name]", with: contact_group_name2
              fill_in "item[contact_groups][][contact_charge]", with: contact_charge2
              fill_in "item[contact_groups][][contact_tel]", with: contact_tel2
              fill_in "item[contact_groups][][contact_fax]", with: contact_fax2
              fill_in "item[contact_groups][][contact_email]", with: contact_email2
              fill_in "item[contact_groups][][contact_postal_code]", with: contact_postal_code2
              fill_in "item[contact_groups][][contact_address]", with: contact_address2
              fill_in "item[contact_groups][][contact_link_url]", with: contact_link_url2
              fill_in "item[contact_groups][][contact_link_name]", with: contact_link_name2
            end
          end
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.contact_groups.count).to eq 2
        item.contact_groups.first.tap do |contact_group|
          # ページから id で参照するので、編集のたびに変化してはいけない。一度採番する変化しない。
          expect(contact_group.id).to eq save_contact_group_id
          expect(contact_group.name).to eq contact_name1
          expect(contact_group.contact_group_name).to eq contact_group_name1
          expect(contact_group.contact_charge).to eq contact_charge1
          expect(contact_group.contact_tel).to eq contact_tel1
          expect(contact_group.contact_fax).to eq contact_fax1
          expect(contact_group.contact_email).to eq contact_email1
          expect(contact_group.contact_postal_code).to eq contact_postal_code1
          expect(contact_group.contact_address).to eq contact_address1
          expect(contact_group.contact_link_url).to eq contact_link_url1
          expect(contact_group.contact_link_name).to eq contact_link_name1
          expect(contact_group.main_state).to eq "main"
        end
        item.contact_groups.second.tap do |contact_group|
          expect(contact_group.name).to eq contact_name2
          expect(contact_group.contact_group_name).to eq contact_group_name2
          expect(contact_group.contact_charge).to eq contact_charge2
          expect(contact_group.contact_tel).to eq contact_tel2
          expect(contact_group.contact_fax).to eq contact_fax2
          expect(contact_group.contact_email).to eq contact_email2
          expect(contact_group.contact_postal_code).to eq contact_postal_code2
          expect(contact_group.contact_address).to eq contact_address2
          expect(contact_group.contact_link_url).to eq contact_link_url2
          expect(contact_group.contact_link_name).to eq contact_link_name2
          expect(contact_group.main_state).to be_blank
        end
        expect(item.contact_group_name).to eq contact_group_name1
        expect(item.contact_charge).to eq contact_charge1
        expect(item.contact_tel).to eq contact_tel1
        expect(item.contact_fax).to eq contact_fax1
        expect(item.contact_email).to eq contact_email1
        expect(item.contact_postal_code).to eq contact_postal_code1
        expect(item.contact_address).to eq contact_address1
        expect(item.contact_link_url).to eq contact_link_url1
        expect(item.contact_link_name).to eq contact_link_name1
      end
    end

    context "choose main contact" do
      let!(:group) do
        create(
          :cms_group, name: "#{cms_group.name}/#{unique_id}",
          contact_groups: [
            {
              main_state: "main", name: unique_id,
              contact_group_name: unique_id, contact_charge: unique_id, contact_tel: unique_tel,
              contact_fax: unique_tel, contact_email: unique_email, contact_postal_code: unique_id,
              contact_address: unique_id, contact_link_url: unique_url, contact_link_name: unique_id
            },
            {
              main_state: nil, name: unique_id,
              contact_group_name: unique_id, contact_charge: unique_id, contact_tel: unique_tel, contact_fax: unique_tel,
              contact_email: unique_email, contact_postal_code: unique_id,
              contact_address: unique_id, contact_link_url: unique_url, contact_link_name: unique_id
            },
            {
              main_state: nil, name: unique_id,
              contact_group_name: unique_id, contact_charge: unique_id, contact_tel: unique_tel, contact_fax: unique_tel,
              contact_email: unique_email, contact_postal_code: unique_id,
              contact_address: unique_id, contact_link_url: unique_url, contact_link_name: unique_id
            }
          ]
        )
      end

      context "second contact is selected" do
        it do
          visit cms_groups_path(site: site)
          click_on group.trailing_name
          click_on I18n.t("ss.links.edit")

          within "form#item-form" do
            within "[data-id='#{group.contact_groups.to_a[1].id}']" do
              first("[type='radio']").click
            end

            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          group.reload
          group.contact_groups.to_a.tap do |contact_groups|
            expect(contact_groups[0].main_state).to be_blank
            expect(contact_groups[1].main_state).to eq "main"
            expect(contact_groups[2].main_state).to be_blank
          end
        end
      end

      context "third contact is selected" do
        it do
          visit cms_groups_path(site: site)
          click_on group.trailing_name
          click_on I18n.t("ss.links.edit")

          within "form#item-form" do
            within "[data-id='#{group.contact_groups.to_a[2].id}']" do
              first("[type='radio']").click
            end

            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          group.reload
          group.contact_groups.to_a.tap do |contact_groups|
            expect(contact_groups[0].main_state).to be_blank
            expect(contact_groups[1].main_state).to be_blank
            expect(contact_groups[2].main_state).to eq "main"
          end
        end
      end
    end

    context "search" do
      let!(:group) { create :revision_new_group, name: "#{site.groups.first.name}/#{unique_id}" }
      let(:main_contact) { group.contact_groups.where(main_state: "main").first }

      it do
        visit cms_groups_path(site: site)
        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_group_name
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_charge
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_tel
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_fax
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_email
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_email.split("@", 2).first
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_postal_code
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_address
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_link_url
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)

        within ".index-search" do
          fill_in "s[keyword]", with: main_contact.contact_link_name
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".index tbody tr", count: 1)
        expect(page).to have_css(".index tbody tr", text: group.name)
      end
    end
  end
end
