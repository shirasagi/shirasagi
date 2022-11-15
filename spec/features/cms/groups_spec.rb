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
    before(:each) do
      tel   = "000-000-0000"
      email = "sys@example.jp"
      link_url = "/"
      link_name = "http://demo.ss-proj.org/"
      g1 = create(
        :cms_group, name: "A", order: 10,
        contact_groups: [
          { contact_tel: tel, contact_fax: tel, contact_email: email, contact_link_url: link_url, contact_link_name: link_name }
        ]
      )
      cms_site.add_to_set(group_ids: [g1.id])
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

      groups = Cms::Group.site(cms_site).ne(id: cms_group.id)
      expected_names = %w(A A/B A/B/C A/B/C/D A/E A/E/F A/E/G)
      expected_orders = %w(10 20 30 40 50 60 70).map(&:to_i)
      expected_contact_tels = %w(1 2 3 4 5 6 7).fill("000-000-0000")
      expected_contact_faxs = %w(1 2 3 4 5 6 7).fill("000-000-0000")
      expected_contact_emails = %w(1 2 3 4 5 6 7).fill("sys@example.jp")
      expected_contact_link_urls = %w(/ /B/ /B/C/ /B/C/D/ /E/ /E/F/ /E/G/)
      expected_contact_link_names = %w(http://demo.ss-proj.org/ B C D E F G)

      expect(groups.map(&:name)).to eq expected_names
      expect(groups.map(&:order)).to eq expected_orders
      expect(groups.map(&:contact_tel)).to eq expected_contact_tels
      expect(groups.map(&:contact_fax)).to eq expected_contact_faxs
      expect(groups.map(&:contact_email)).to eq expected_contact_emails
      expect(groups.map(&:contact_link_url)).to eq expected_contact_link_urls
      expect(groups.map(&:contact_link_name)).to eq expected_contact_link_names
    end
  end

  context "disable group and edit it" do
    let(:group_name) { unique_id }
    let!(:group) { create(:cms_group, name: "#{cms_group.name}/#{group_name}", order: 100) }
    let(:expiration_date) { Time.zone.now.days_ago(1).beginning_of_day }
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
            first('[name="item[contact_groups][][main_state]"]').click
            fill_in "item[contact_groups][][contact_tel]", with: contact_tel
          end
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      group.reload
      expect(group.contact_tel).to eq contact_tel
      expect(group.contact_groups[0].contact_tel).to eq contact_tel
      expect(group.contact_groups[0].main_state).to eq "main"
    end
  end
end
