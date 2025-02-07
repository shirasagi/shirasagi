require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let(:now) { Time.zone.now.change(sec: 0) }

  before { login_cms_user }

  context "merging expired branch" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:close_date) { now + 1.day }

    context "when branch is published" do
      it do
        # 1. 公開終了日を設定したページを作成・公開する
        visit new_article_page_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[close_date]", with: close_date

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(Article::Page.all.count).to eq 1
        master = Article::Page.all.first
        expect(master.site_id).to eq site.id
        expect(master.state).to eq "public"
        expect(master.name).to eq name
        expect(master.filename).to eq "#{node.filename}/#{master.id}.html"
        expect(master.close_date).to eq close_date
        expect(::File.size(master.path)).to be > 0

        # 2-1. 差し替えページを作成する
        expect do
          within '#addon-workflow-agents-addons-branch' do
            wait_for_event_fired "turbo:frame-load" do
              click_on I18n.t("workflow.create_branch")
            end
            expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
            expect(page).to have_css('table.branches')
          end
        end.to output(/#{::Regexp.escape(I18n.t("workflow.branch_page"))}/).to_stdout

        expect(Article::Page.all.count).to eq 2
        branch = Article::Page.all.where(master_id: master.id).first
        expect(branch.site_id).to eq site.id
        expect(branch.state).to eq "closed"
        expect(branch.name).to eq name
        expect(branch.filename).to eq "#{node.filename}/#{branch.id}.html"
        expect(branch.close_date).to eq close_date
        expect(::File.exist?(branch.path)).to be_falsey

        # 2-2. 差し替えページを編集・保存（下書き保存）する
        visit edit_article_page_path(site: site, cid: node, id: branch)
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name2
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        branch.reload
        expect(branch.site_id).to eq site.id
        expect(branch.state).to eq "closed"
        expect(branch.name).to eq name2
        expect(branch.filename).to eq "#{node.filename}/#{branch.id}.html"
        expect(branch.close_date).to eq close_date
        expect(::File.exist?(branch.path)).to be_falsey

        travel_to = close_date + 1.minute
        Timecop.travel(travel_to) do
          # 3. 公開終了日を経過し公開中のページ（1）が非公開になる
          expect do
            Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id).perform_now
          end.to output(/#{::Regexp.escape(master.full_url)}/).to_stdout

          master.reload
          expect(master.site_id).to eq site.id
          expect(master.state).to eq "closed"
          expect(master.name).to eq name
          expect(master.filename).to eq "#{node.filename}/#{master.id}.html"
          expect(master.close_date).to be_blank
          expect(::File.exist?(master.path)).to be_falsey

          # 4. 差し替えページ（2）を公開保存
          login_cms_user # 時計を進めたのでセッションの期限が切れているはずなので、再ログイン
          visit edit_article_page_path(site: site, cid: node, id: branch)
          wait_for_all_ckeditors_ready
          expect do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_error I18n.t("errors.messages.greater_than", count: I18n.l(travel_to))
          end.to output(/#{::Regexp.escape(I18n.t("workflow.branch_page"))}/).to_stdout

          wait_for_all_ckeditors_ready

          master.reload
          expect(master.site_id).to eq site.id
          expect(master.state).to eq "closed"
          expect(master.name).to eq name
          expect(master.filename).to eq "#{node.filename}/#{master.id}.html"
          expect(master.close_date).to be_blank
          expect(::File.exist?(master.path)).to be_falsey

          branch.reload
          expect(branch.site_id).to eq site.id
          expect(branch.state).to eq "closed"
          expect(branch.name).to eq name2
          expect(branch.filename).to eq "#{node.filename}/#{branch.id}.html"
          expect(branch.close_date).to eq close_date
          expect(::File.exist?(branch.path)).to be_falsey
        end
      end
    end

    context "when branch is approved" do
      it do
        # 1. 公開終了日を設定したページを作成・公開する
        visit new_article_page_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in_datetime "item[close_date]", with: close_date

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(Article::Page.all.count).to eq 1
        master = Article::Page.all.first
        expect(master.site_id).to eq site.id
        expect(master.state).to eq "public"
        expect(master.name).to eq name
        expect(master.filename).to eq "#{node.filename}/#{master.id}.html"
        expect(master.close_date).to eq close_date
        expect(::File.size(master.path)).to be > 0

        # 2-1. 差し替えページを作成する
        expect do
          within '#addon-workflow-agents-addons-branch' do
            wait_for_event_fired "turbo:frame-load" do
              click_on I18n.t("workflow.create_branch")
            end
            expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
            expect(page).to have_css('table.branches')
          end
        end.to output(/#{::Regexp.escape(I18n.t("workflow.branch_page"))}/).to_stdout

        expect(Article::Page.all.count).to eq 2
        branch = Article::Page.all.where(master_id: master.id).first
        expect(branch.site_id).to eq site.id
        expect(branch.state).to eq "closed"
        expect(branch.name).to eq name
        expect(branch.filename).to eq "#{node.filename}/#{branch.id}.html"
        expect(branch.close_date).to eq close_date
        expect(::File.exist?(branch.path)).to be_falsey

        # 2-2. 差し替えページを編集・保存（下書き保存）する
        visit edit_article_page_path(site: site, cid: node, id: branch)
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          fill_in "item[name]", with: name2
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_turbo_frame "#workflow-branch-frame"
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        branch.reload
        expect(branch.site_id).to eq site.id
        expect(branch.state).to eq "closed"
        expect(branch.name).to eq name2
        expect(branch.filename).to eq "#{node.filename}/#{branch.id}.html"
        expect(branch.close_date).to eq close_date
        expect(::File.exist?(branch.path)).to be_falsey

        travel_to = close_date + 1.minute
        Timecop.travel(travel_to) do
          # 3. 公開終了日を経過し公開中のページ（1）が非公開になる
          expect do
            Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id).perform_now
          end.to output(/#{::Regexp.escape(master.full_url)}/).to_stdout

          master.reload
          expect(master.site_id).to eq site.id
          expect(master.state).to eq "closed"
          expect(master.name).to eq name
          expect(master.filename).to eq "#{node.filename}/#{master.id}.html"
          expect(master.close_date).to be_blank
          expect(::File.exist?(master.path)).to be_falsey

          # 4. 差し替えページ（2）を承認
          login_cms_user # 時計を進めたのでセッションの期限が切れているはずなので、再ログイン
          visit article_page_path(site: site, cid: node, id: branch)
          wait_for_turbo_frame "#workflow-branch-frame"
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(cms_user.long_name)
            wait_for_cbox_closed { click_on cms_user.long_name }
          end
          message = I18n.t("errors.messages.greater_than", count: I18n.l(travel_to))
          page.accept_alert(/#{::Regexp.escape(message)}/) do
            within ".mod-workflow-request" do
              expect(page).to have_css("[data-id='1,#{cms_user.id}']", text: cms_user.long_name)
              click_on I18n.t("workflow.buttons.request")
            end
          end

          master.reload
          expect(master.site_id).to eq site.id
          expect(master.state).to eq "closed"
          expect(master.name).to eq name
          expect(master.filename).to eq "#{node.filename}/#{master.id}.html"
          expect(master.close_date).to be_blank
          expect(::File.exist?(master.path)).to be_falsey

          branch.reload
          expect(branch.site_id).to eq site.id
          expect(branch.state).to eq "closed"
          expect(branch.name).to eq name2
          expect(branch.filename).to eq "#{node.filename}/#{branch.id}.html"
          expect(branch.close_date).to eq close_date
          expect(::File.exist?(branch.path)).to be_falsey
        end
      end
    end
  end
end
