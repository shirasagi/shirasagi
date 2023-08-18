require 'spec_helper'

describe "workflow_remind", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page1) { create :article_page, cur_site: site, cur_node: node, state: "public" }
  let!(:page2) { create :article_page, cur_site: site, cur_node: node, state: "closed" }

  before do
    # テストの再現性を高めるために、ミリ秒部を 0 クリアするし、page2 の更新日時を page1 と同じにする
    page1.set(updated: page1.updated.change(usec: 0).utc)
    page2.set(updated: page1.updated.change(usec: 0).utc)
  end

  context "when page_expiration_state is disabled" do
    before do
      site.page_expiration_state = [ "disabled", nil ].sample
      site.page_expiration_before = %w(90.days 180.days 1.year 2.years 3.years).sample
      site.page_expiration_mail_subject = unique_id
      site.page_expiration_mail_upper_text = Array.new(2) { unique_id }
      site.save!
    end

    it do
      time = page1.updated + SS::Duration.parse(site.page_expiration_before)
      time = time.end_of_day.change(sec: 0)
      Timecop.freeze(time) do
        login_cms_user

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: I18n.t("ss.state.public"))
        expect(page).to have_css(".list-item[data-id='#{page2.id}']", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_no_css(".page-expiration")

        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        expect(page).to have_no_css(".page-expiration")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end

      time = page1.updated + SS::Duration.parse(site.page_expiration_before) + 1.day
      time = time.beginning_of_day
      Timecop.freeze(time) do
        login_cms_user

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: I18n.t("ss.state.public"))
        expect(page).to have_css(".list-item[data-id='#{page2.id}']", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_no_css(".page-expiration")

        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        expect(page).to have_no_css(".page-expiration")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end
  end

  context "when page_expiration_state is enabled" do
    before do
      site.page_expiration_state = "enabled"
      site.page_expiration_before = %w(90.days 180.days 1.year 2.years 3.years).sample
      site.page_expiration_mail_subject = unique_id
      site.page_expiration_mail_upper_text = Array.new(2) { unique_id }
      site.save!
    end

    it do
      time = page1.updated + SS::Duration.parse(site.page_expiration_before)
      time = time.end_of_day.change(sec: 0)
      Timecop.freeze(time) do
        login_cms_user

        visit article_pages_path(site: site, cid: node)
        expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: I18n.t("ss.state.public"))
        expect(page).to have_css(".list-item[data-id='#{page2.id}']", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_no_css(".page-expiration")

        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        expect(page).to have_no_css(".page-expiration")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end

      time = page1.updated + SS::Duration.parse(site.page_expiration_before) + 1.day
      time = time.beginning_of_day
      Timecop.freeze(time) do
        login_cms_user

        visit article_pages_path(site: site, cid: node)
        "#{I18n.t("ss.state.public")}#{I18n.t("cms.state_expired_suffix")}".tap do |text|
          expect(page).to have_css(".list-item[data-id='#{page1.id}']", text: text)
        end
        expect(page).to have_css(".list-item[data-id='#{page2.id}']", text: I18n.t("ss.state.edit"))

        click_on page1.name
        expect(page).to have_css(".page-expiration", text: I18n.t("cms.notices.page_expiration_header"))

        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        expect(page).to have_no_css(".page-expiration")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end
  end
end
