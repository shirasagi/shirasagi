require 'spec_helper'

# 差し替えページを経た公開日時の変遷
describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:article_node) { create :article_node_page, cur_site: site, group_ids: user.group_ids }
  let!(:article_item) do
    travel_to = now - 3.days
    Timecop.freeze(travel_to) do
      create(
        :article_page, cur_site: site, cur_node: article_node, released_type: "fixed", released: travel_to, state: "public")
    end
  end

  context "released changes through branch" do
    it do
      login_user user, to: article_pages_path(site: site, cid: article_node)
      click_on article_item.name
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      # 1. 差し替えページを作成する
      expect do
        within '#addon-workflow-agents-addons-branch' do
          wait_event_to_fire "turbo:frame-load" do
            click_on I18n.t("workflow.create_branch")
          end
          expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
        end
      end.to output(/#{::Regexp.escape(I18n.t("workflow.branch_page"))}/).to_stdout

      expect(Article::Page.all.count).to eq 2
      branch = Article::Page.all.where(master_id: article_item.id).first
      expect(branch.released_type).to eq "fixed"
      expect(branch.released_type).to eq article_item.released_type
      expect(branch.released).to eq article_item.released
      expect(branch.first_released).to be_blank

      # 2. 差し替えページを編集する
      visit edit_article_page_path(site: site, cid: article_node, id: branch)
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        ensure_addon_opened "#addon-cms-agents-addons-release"
        within "#addon-cms-agents-addons-release" do
          select I18n.t("cms.options.released_type.fixed"), from: "item[released_type]"
          # 公開日を変更する
          fill_in_datetime "item[released]", with: now
        end

        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      branch.reload
      expect(branch.released_type).to eq "fixed"
      expect(branch.released).to eq now
      expect(branch.first_released).to be_blank

      # 3. 差し替えページを公開する
      visit edit_article_page_path(site: site, cid: article_node, id: branch)
      wait_for_all_ckeditors_ready
      expect do
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end.to output(/#{::Regexp.escape(I18n.t("workflow.branch_page"))}/).to_stdout

      expect { branch.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      Article::Page.find(article_item.id).tap do |after_page|
        # 公開日時・公開日時種別は差し替えページのものになっているはず
        expect(after_page.released_type).to eq "fixed"
        expect(after_page.released).to eq branch.released
        # 初公開日時には変更がない
        expect(after_page.first_released).to eq article_item.first_released
      end
    end
  end
end
