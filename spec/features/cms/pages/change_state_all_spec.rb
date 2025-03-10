require 'spec_helper'

describe "cms_page_pages", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let(:user) { cms_user }

  context "change state all" do
    let!(:page1) { Timecop.freeze(now - 4.hours) { create(:cms_page) } }
    let!(:page2) { Timecop.freeze(now - 3.hours) { create(:cms_page) } }
    let!(:page3) { Timecop.freeze(now - 2.hours) { create(:cms_page) } }
    let(:index_path) { cms_pages_path(site) }

    it do
      expect(page1.state).to eq "public"
      expect(page2.state).to eq "public"
      expect(page3.state).to eq "public"
      expect(page1.backups.size).to eq 1
      expect(page2.backups.size).to eq 1
      expect(page3.backups.size).to eq 1

      Timecop.freeze(now - 1.hour) do
        login_cms_user

        visit index_path
        wait_for_turbo_frame "#cms-nodes-tree-frame"

        within ".list-head" do
          wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
          click_button I18n.t('ss.links.make_them_close')
        end

        wait_for_js_ready
        click_button I18n.t("ss.buttons.make_them_close")
        wait_for_notice I18n.t("ss.notice.depublished")
        wait_for_turbo_frame "#cms-nodes-tree-frame"
      end

      page1.reload
      page2.reload
      page3.reload
      expect(page1.state).to eq "closed"
      expect(page2.state).to eq "closed"
      expect(page3.state).to eq "closed"

      expect(page1.backups.size).to eq 2
      page1.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now - 1.hour
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "closed"
      end

      expect(page2.backups.size).to eq 2
      page2.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now - 1.hour
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "closed"
      end

      expect(page3.backups.size).to eq 2
      page3.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now - 1.hour
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "closed"
      end

      Timecop.freeze(now) do
        login_cms_user

        visit index_path
        wait_for_turbo_frame "#cms-nodes-tree-frame"

        within ".list-head" do
          wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
          click_button I18n.t('ss.links.make_them_public')
        end

        wait_for_js_ready
        click_button I18n.t("ss.buttons.make_them_public")
        wait_for_notice I18n.t("ss.notice.published")
        wait_for_turbo_frame "#cms-nodes-tree-frame"
      end

      page1.reload
      page2.reload
      page3.reload
      expect(page1.state).to eq "public"
      expect(page2.state).to eq "public"
      expect(page3.state).to eq "public"

      expect(page1.backups.size).to eq 3
      page1.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "public"
      end

      expect(page2.backups.size).to eq 3
      page2.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "public"
      end

      expect(page3.backups.size).to eq 3
      page3.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "public"
      end
    end
  end

  context "branch page" do
    let!(:node) { create :cms_node_page }
    let!(:page1) do
      Timecop.freeze(now - 5.hours) do
        create(:cms_page, cur_site: site, cur_node: node, cur_user: cms_user)
      end
    end
    let!(:page2) do
      Timecop.freeze(now - 4.hours) do
        create(:cms_page, cur_site: site, cur_node: node, cur_user: cms_user)
      end
    end
    let!(:page3) do
      Timecop.freeze(now - 3.hours) do
        page1.cur_node = node

        copy = page1.new_clone
        copy.master = page1
        copy.html = "<s>copy1</s>"
        copy.save!

        page1.reload
        Cms::Page.find(copy.id)
      end
    end
    let!(:page4) do
      Timecop.freeze(now - 2.hours) do
        page2.cur_node = node

        copy = page2.new_clone
        copy.master = page2
        copy.html = "<s>copy2</s>"
        copy.save!

        page2.reload
        Cms::Page.find(copy.id)
      end
    end
    let(:index_path) { node_pages_path(site, node) }

    it do
      expect(page1.backups.size).to eq 1
      expect(page2.backups.size).to eq 1

      Timecop.freeze(now - 1.hour) do
        login_cms_user

        visit index_path
        wait_for_turbo_frame "#cms-nodes-tree-frame"
        expect(page1.state).to eq "public"
        expect(page2.state).to eq "public"
        expect(page3.state).to eq "closed"
        expect(page4.state).to eq "closed"

        within ".list-head" do
          wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
          click_button I18n.t('ss.links.make_them_public')
        end

        wait_for_js_ready
        click_button I18n.t("ss.buttons.make_them_public")
        wait_for_notice I18n.t("ss.notice.published")
        wait_for_turbo_frame "#cms-nodes-tree-frame"
      end

      page1.reload
      page2.reload
      expect(Cms::Page.where(id: page3.id).first).to be_nil
      expect(Cms::Page.where(id: page4.id).first).to be_nil

      expect(page1.state).to eq "public"
      expect(page1.html).to eq "<s>copy1</s>"
      expect(page2.state).to eq "public"
      expect(page2.html).to eq "<s>copy2</s>"

      expect(page1.backups.size).to eq 2
      page1.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now - 1.hour
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "public"
      end
      expect(page2.backups.size).to eq 2
      page2.backups.to_a.tap do |backups|
        expect(backups[0].created.in_time_zone).to eq now - 1.hour
        expect(backups[0].user_id).to eq user.id
        expect(backups[0].data[:state]).to eq "public"
      end
    end
  end
end
