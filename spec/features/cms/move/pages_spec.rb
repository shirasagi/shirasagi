require 'spec_helper'

describe "move_cms_pages", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }

  around do |example|
    save_config = SS.config.replace_value_at(:cms, 'replace_urls_after_move', true)
    perform_enqueued_jobs do
      example.run
    end
    SS.config.replace_value_at(:cms, 'replace_urls_after_move', save_config)
  end

  context "with auth", js: true do
    let(:page_html) { '<a href="/A/B/C/">/A/B/C/</a>' }
    let(:page2_html) { '<a href="/page.html">page.html</a>' }
    let(:layout_layout_html) { "<a href='#{site.full_url}page.html'>page.html</a><a href='#{site.full_url}A/B/C/'>/A/B/C/</a>" }
    let(:part_part_html) { '<a href="/page.html ">page.html</a><a href="/A/B/C/ ">/A/B/C/</a>' }

    before { login_cms_user }
    before(:each) do
      create(:cms_page, filename: "page.html", name: "page", html: page_html)
      create(:cms_page, filename: "A/B/C/page2.html", name: "page2", html: page2_html)
      create(:cms_layout, filename: "layout.layout.html", name: "layout", html: layout_layout_html)
      create(:cms_part_free, filename: "part.part.html", name: "part", html: part_part_html)
      create(:cms_node_page, site: site, filename: "A", name: "A")
      create(:cms_node_page, site: site, filename: "A/B", name: "B" )
      create(:cms_node_page, site: site, filename: "A/B/C", name: "C" )
      create(:cms_node_page, site: site, filename: "D", name: "D" )
    end
    after(:each) do
      Fs.rm_rf "#{site.path}/A"
      Fs.rm_rf "#{site.path}/D"
    end

    it "#move" do
      Cms::Page.where(filename: "page.html").first.tap do |item|
        expect(Fs.exist?("#{site.path}/page.html")).to be_truthy

        visit move_cms_page_path(site.id, item)
        within "form" do
          fill_in "destination", with: "A/page"
          click_button I18n.t('ss.buttons.move')
        end
        wait_for_notice I18n.t("ss.notice.moved")
      end
      expect(Cms::Page.where(filename: "A/page.html").first).to be_present
      expect(page).to have_css("form#item-form .current-filename", text: "A/page.html")

      expect(Fs.exist?("#{site.path}/page.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/A/page.html")).to be_truthy

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.where(filename: "A/B/C/page2.html").first.tap do |item|
        visit cms_page_path(site.id, item)
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        within "#addon-history-agents-addons-backup" do
          expect(page).to have_css('.history-backup-table', text: I18n.t('history.options.action.replace_urls'), count: 1)
        end
      end

      Cms::Node.where(filename: "A/B/C").first.tap do |item|
        parent_node = Cms::Node.where(filename: "D").first
        expect(Fs.exist?("#{site.path}/A/B/C/page2.html")).to be_truthy

        visit move_node_conf_path(site.id, item)
        within "form" do
          within(".destination") do
            wait_for_cbox_opened { click_link(I18n.t("cms.apis.nodes.index")) }
          end
        end
        within_cbox do
          expect(page).to have_css("tr[data-id='#{parent_node.id}']", text: parent_node.name)
          wait_for_cbox_closed { click_on parent_node.name }
        end
        within "form" do
          within(".destination") do
            expect(page).to have_css("tr[data-id='#{parent_node.id}']", text: parent_node.name)
          end
          fill_in "item[destination_basename]", with: "E"
          click_on I18n.t('ss.buttons.move')
        end
        within_cbox do
          wait_for_turbo_frame("#contents-frame")
          find("#confirm_changes").click
          click_on I18n.t("ss.buttons.move")
        end
        wait_for_notice I18n.t("ss.notice.moved")
      end
      expect(Cms::Node.where(filename: "D/E").first).to be_present
      # expect(page).to have_css("form#item-form .current-filename", text: "D/E")

      expect(Fs.exist?("#{site.path}/A/B/C/page2.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/D/E/page2.html")).to be_truthy

      expect(Job::Log.count).to eq 2
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.where(filename: "A/page.html").first.tap do |item|
        visit cms_page_path(site.id, item)
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        within "#addon-history-agents-addons-backup" do
          expect(page).to have_css('.history-backup-table', text: I18n.t('history.options.action.replace_urls'), count: 1)
        end

        visit move_cms_page_path(site.id, item)
        within "form" do
          fill_in "destination", with: "D/E/page"
          click_button I18n.t('ss.buttons.move')
        end
        wait_for_notice I18n.t("ss.notice.moved")
        expect(page).to have_css("form#item-form .current-filename", text: "D/E/page.html")
      end

      expect(Fs.exist?("#{site.path}/A/page.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/D/E/page.html")).to be_truthy

      expect(Job::Log.count).to eq 3
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.where(filename: "D/E/page2.html").first.tap do |item|
        visit cms_page_path(site.id, item)
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        within "#addon-history-agents-addons-backup" do
          expect(page).to have_css('.history-backup-table', text: I18n.t('history.options.action.replace_urls'), count: 1)
        end
      end

      Cms::Node.where(filename: "D/E").first.tap do |item|
        parent_node = Cms::Node.where(filename: "A/B").first

        visit move_node_conf_path(site.id, item)
        within "form#item-form" do
          within(".destination") do
            wait_for_cbox_opened { click_link(I18n.t("cms.apis.nodes.index")) }
          end
        end
        within_cbox do
          expect(page).to have_css("tr[data-id='#{parent_node.id}']", text: parent_node.name)
          wait_for_cbox_closed { click_on parent_node.name }
        end
        within "form#item-form" do
          within(".destination") do
            expect(page).to have_css("tr[data-id='#{parent_node.id}']", text: parent_node.name)
          end
          fill_in "item[destination_basename]", with: "C"
          click_button I18n.t('ss.buttons.move')
        end
        within_cbox do
          wait_for_turbo_frame("#contents-frame")
          find("#confirm_changes").click
          click_on I18n.t("ss.buttons.move")
        end
        wait_for_notice I18n.t("ss.notice.moved")
      end
      expect(Cms::Node.where(filename: "A/B/C").first).to be_present

      expect(Fs.exist?("#{site.path}/D/E/page.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/D/E/page2.html")).to be_falsy
      expect(Fs.exist?("#{site.path}/A/B/C/page.html")).to be_truthy
      expect(Fs.exist?("#{site.path}/A/B/C/page2.html")).to be_truthy

      expect(Job::Log.count).to eq 4
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.where(filename: "A/B/C/page.html").first.tap do |item|
        visit cms_page_path(site.id, item)
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        within "#addon-history-agents-addons-backup" do
          expect(page).to have_css('.history-backup-table', text: I18n.t('history.options.action.replace_urls'), count: 1)
        end
      end

      Cms::Page.where(filename: "A/B/C/page2.html").first.tap do |item|
        visit cms_page_path(site.id, item)
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        within "#addon-history-agents-addons-backup" do
          expect(page).to have_css('.history-backup-table', text: I18n.t('history.options.action.replace_urls'), count: 1)
        end
      end
    end
  end
end
