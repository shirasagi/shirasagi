require 'spec_helper'

describe "cms_search", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:pages_index_path) { cms_search_contents_pages_path site.id }
  let(:html_index_path) { cms_search_contents_html_path site.id }
  let(:user) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }

  context "with auth" do
    before do
      login_cms_user
    end

    context "search_contents_pages" do
      let(:node_name) { unique_id }
      let(:node_filename) { 'base' }
      let(:cate_name1) { unique_id }
      let(:opendata_cate_name1) { unique_id }

      before(:each) do
        node = create(:cms_node_page, name: node_name, filename: node_filename)
        cate1 = create(:category_node_page, name: cate_name1)
        cate2 = create(:category_node_page)
        cate3 = create(:category_node_page)
        cate4 = create(:category_node_page)
        html1 = "<div>html1</div>"
        html2 = "<div>[TEST]A</div>"
        html3 = "<div>html3</div>"
        html4 = "<div>html4</div>"
        create(
          :cms_page, cur_site: site, user: user, name: "[TEST]A", filename: "A.html", state: "public",
          category_ids: [ cate1.id ], group_ids: [ cms_group.id ], html: html1)
        create(
          :article_page, cur_site: site, cur_node: node, name: "[TEST]B", filename: "B.html", state: "public",
          category_ids: [ cate2.id ], group_ids: [ cms_group.id ], html: html2)
        create(
          :event_page, cur_site: site, cur_node: node, name: "[TEST]C", filename: "C.html", state: "closed",
          category_ids: [ cate3.id ], group_ids: [ cms_group.id ], html: html3)
        create(
          :faq_page, cur_site: site, cur_node: node, name: "[TEST]D", filename: "D.html", state: "closed",
          category_ids: [ cate4.id ], group_ids: [ cms_group.id ], html: html4)

        opendata_node = create(:opendata_node_dataset)
        opendata_cate = create(:opendata_node_category, name: opendata_cate_name1)
        create(
          :opendata_dataset, cur_node: opendata_node, name: "[TEST]E", state: "closed",
          category_ids: [ opendata_cate.id ], group_ids: [ cms_group.id ])
      end

      it "search with empty conditions" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
        expect(page).to have_css("div.info a.title", text: "[TEST]E")
      end

      it "search with name" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          fill_in "item[search_name]", with: "A"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
      end

      it "search with filename" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          fill_in "item[search_filename]", with: "#{node_filename}/"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end

      it "search with keyword" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          fill_in "item[search_keyword]", with: "[TEST]A"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "2 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
      end

      it "search with state" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          select I18n.t("ss.options.state.public"), from: "item[search_state]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "2 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        within "form.search-pages" do
          select I18n.t("ss.options.state.closed"), from: "item[search_state]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
        expect(page).to have_css("div.info a.title", text: "[TEST]E")
      end

      it "search with publishable" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          select I18n.t("ss.options.first_released.published"), from: "item[search_first_released]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "2 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        within "form.search-pages" do
          select I18n.t("ss.options.first_released.draft"), from: "item[search_first_released]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
        expect(page).to have_css("div.info a.title", text: "[TEST]E")
      end

      it "search with ready state" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          select I18n.t("ss.options.state.ready"), from: "item[search_state]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "0 件の検索結果")

        Article::Page.first.tap do |item|
          item.state = "ready"
          item.save!
        end

        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
      end

      it "search with released_or_updated" do
        Timecop.travel(3.days.from_now) do
          login_cms_user
          visit pages_index_path
          expect(current_path).not_to eq sns_login_path
          page = Cms::Page.where(name: "[TEST]D").first
          page.state = "public"
          page.save
        end

        Timecop.travel(6.days.from_now) do
          login_cms_user
          visit pages_index_path
          expect(current_path).not_to eq sns_login_path
          page = Cms::Page.where(name: "[TEST]A").first
          page.html = "update"
          page.save
        end

        Timecop.travel(1.day.from_now) do
          login_cms_user
          visit pages_index_path
          expect(current_path).not_to eq sns_login_path
          start = Time.zone.now
          close = start.advance(days: 6)
          start = start.strftime("%Y/%m/%d %H:%M")
          close = close.strftime("%Y/%m/%d %H:%M")

          # disable datetimepicker because I can't find the way to work with datetimepicker
          page.execute_script("$('#item_search_released_start').datetimepicker('destroy');")
          page.execute_script("$('#item_search_released_close').datetimepicker('destroy');")
          page.execute_script("$('#item_search_updated_start').datetimepicker('destroy');")
          page.execute_script("$('#item_search_updated_close').datetimepicker('destroy');")
          within "form.search-pages" do
            fill_in "item[search_released_start]", with: start
            fill_in "item[search_released_close]", with: close
            fill_in "item[search_updated_start]", with: ""
            fill_in "item[search_updated_close]", with: ""
            click_button I18n.t('ss.buttons.search')
          end
          expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
          expect(page).to have_css("div.info a.title", text: "[TEST]D")

          # disable datetimepicker because I can't find the way to work with datetimepicker
          page.execute_script("$('#item_search_released_start').datetimepicker('destroy');")
          page.execute_script("$('#item_search_released_close').datetimepicker('destroy');")
          page.execute_script("$('#item_search_updated_start').datetimepicker('destroy');")
          page.execute_script("$('#item_search_updated_close').datetimepicker('destroy');")
          within "form.search-pages" do
            fill_in "item[search_released_start]", with: ""
            fill_in "item[search_released_close]", with: ""
            fill_in "item[search_updated_start]", with: start
            fill_in "item[search_updated_close]", with: close
            click_button I18n.t('ss.buttons.search')
          end
          expect(page).to have_css(".search-count", text: "2 件の検索結果")
          expect(page).to have_css("div.info a.title", text: "[TEST]A")
          expect(page).to have_css("div.info a.title", text: "[TEST]D")
        end
      end

      it "search with request approver_state" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          select I18n.t("workflow.page.request"), from: "item[search_approver_state]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "0 件の検索結果")

        Article::Page.first.tap do |item|
          item.cur_site = site
          item.cur_user = cms_user
          item.workflow_state = "request"
          item.workflow_user_id = cms_user.id
          item.workflow_approvers = [{ level: 1, user_id: user.id, state: "request" }]
          item.workflow_required_counts = [ false ]
          item.save!
        end

        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
      end

      it "search with approve approver_state" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          select I18n.t("workflow.page.approve"), from: "item[search_approver_state]"
          click_button I18n.t('ss.buttons.search')
        end
        expect(page).to have_css(".search-count", text: "0 件の検索結果")

        Article::Page.first.tap do |item|
          item.cur_site = site
          item.cur_user = user
          item.workflow_state = "request"
          item.workflow_user_id = user.id
          item.workflow_approvers = [{ level: 1, user_id: cms_user.id, state: "request" }]
          item.workflow_required_counts = [ false ]
          item.save!
        end

        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
      end

      it "search with categories" do
        visit pages_index_path
        click_on I18n.t("cms.apis.categories.index")
        wait_for_cbox do
          click_on cate_name1
        end
        expect(page).to have_css(".mod-cms-page-search", text: cate_name1)
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
      end

      it "search with opendata categories" do
        visit pages_index_path
        click_on I18n.t("cms.apis.categories.index")
        wait_for_cbox do
          click_on opendata_cate_name1
        end
        expect(page).to have_css(".mod-cms-page-search", text: opendata_cate_name1)
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]E")
      end

      it "search with groups" do
        visit pages_index_path
        click_on I18n.t("ss.apis.groups.index")
        wait_for_cbox do
          click_on cms_group.name
        end
        expect(page).to have_css(".mod-cms-page-search", text: cms_group.name)
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 5))
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
        expect(page).to have_css("div.info a.title", text: "[TEST]E")
      end

      it "search with user" do
        visit pages_index_path
        click_on I18n.t("cms.apis.users.index")
        wait_for_cbox do
          click_on user.name
        end
        expect(page).to have_css(".mod-cms-page-search", text: user.name)
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
      end

      it "search with nodes" do
        visit pages_index_path
        click_on I18n.t("cms.apis.nodes.index")
        wait_for_cbox do
          click_on node_name
        end
        expect(page).to have_css(".mod-cms-page-search", text: node_name)
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end

      it "search with routes" do
        visit pages_index_path
        click_on I18n.t("cms.apis.pages_routes.index")
        page_route = I18n.t("modules.article") + "/" + I18n.t("mongoid.models.article/page")
        wait_for_cbox do
          click_on page_route
        end
        expect(page).to have_css(".mod-cms-page-search", text: page_route)
        click_button I18n.t('ss.buttons.search')
        expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
      end
    end

    context "search_contents_html" do
      before(:each) do
        create(:article_page, name: "[TEST]top",     html: '<a href="/top/" class="top">anchor</a>')
        create(:article_page, name: "[TEST]child",   html: '<a href="/top/child/">anchor2</a><p>くらし\r\nガイド</p>')
        create(:article_page, name: "[TEST]1.html",  html: '<a href="/top/child/1.html">anchor3</a>')
        create(:article_page, name: "[TEST]nothing", html: '')
      end

      it "replace_html with string" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "くらし"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")

        page.accept_confirm do
          within "form.index-search" do
            fill_in "keyword", with: "くらし"
            fill_in "replacement", with: "戸籍"
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        within "form.index-search" do
          fill_in "keyword", with: "戸籍"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      end

      it "replace_html with url" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "/top/child/"
          check "option-url"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]child")
        expect(page).to have_css(".result table a", text: "[TEST]1")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")

        page.accept_confirm do
          within "form.index-search" do
            fill_in "keyword", with: "/top/child/"
            fill_in "replacement", with: "/kurashi/koseki/"
            check "option-url"
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        within "form.index-search" do
          fill_in "keyword", with: "/kurashi/koseki/"
          check "option-url"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]child")
        expect(page).to have_css(".result table a", text: "[TEST]1")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      end

      it "replace_html with regexp" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: '<p>.+?<\/p>'
          check "option-regexp"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")

        page.accept_confirm do
          within "form.index-search" do
            fill_in "keyword", with: '<p>.+?<\/p>'
            fill_in "replacement", with: "<s>正規表現</s>"
            check "option-regexp"
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        within "form.index-search" do
          fill_in "keyword", with: '<s>.+?<\/s>'
          check "option-regexp"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]child")
        expect(page).to have_no_css(".result table a", text: "[TEST]1")
        expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
      end

      context "with contact_group_id" do
        let(:root_group) { create(:revision_root_group) }
        let(:group) { create(:revision_new_group) }

        before(:each) do
          create(:revisoin_page, cur_site: site, group: group)
        end

        it "replace_html with string" do
          visit html_index_path
          expect(current_path).not_to eq sns_login_path
          within "form.index-search" do
            fill_in "keyword", with: group.contact_tel
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          page.accept_confirm do
            within "form.index-search" do
              fill_in "keyword", with: group.contact_tel
              fill_in "replacement", with: "contact_tel"
              click_button I18n.t("ss.buttons.replace_all")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "form.index-search" do
            fill_in "keyword", with: "contact_tel"
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          within "form.index-search" do
            fill_in "keyword", with: group.contact_fax
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          page.accept_confirm do
            within "form.index-search" do
              fill_in "keyword", with: group.contact_fax
              fill_in "replacement", with: "contact_fax"
              click_button I18n.t("ss.buttons.replace_all")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "form.index-search" do
            fill_in "keyword", with: "contact_fax"
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          within "form.index-search" do
            fill_in "keyword", with: group.contact_email
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          page.accept_confirm do
            within "form.index-search" do
              fill_in "keyword", with: group.contact_email
              fill_in "replacement", with: "contact_email"
              click_button I18n.t("ss.buttons.replace_all")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "form.index-search" do
            fill_in "keyword", with: "contact_email"
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          within "form.index-search" do
            fill_in "keyword", with: group.contact_link_url
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          page.accept_confirm do
            within "form.index-search" do
              fill_in "keyword", with: group.contact_link_url
              fill_in "replacement", with: "contact_link_url"
              click_button I18n.t("ss.buttons.replace_all")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "form.index-search" do
            fill_in "keyword", with: "contact_link_url"
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          within "form.index-search" do
            fill_in "keyword", with: group.contact_link_name
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")

          page.accept_confirm do
            within "form.index-search" do
              fill_in "keyword", with: group.contact_link_name
              fill_in "replacement", with: "contact_link_name"
              click_button I18n.t("ss.buttons.replace_all")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "form.index-search" do
            fill_in "keyword", with: "contact_link_name"
            click_button I18n.t('ss.buttons.search')
          end
          wait_for_ajax
          expect(page).to have_no_css(".result table a", text: "[TEST]top")
          expect(page).to have_no_css(".result table a", text: "[TEST]child")
          expect(page).to have_no_css(".result table a", text: "[TEST]1.html")
          expect(page).to have_no_css(".result table a", text: "[TEST]nothing")
          expect(page).to have_css(".result table a", text: "自動交付機・コンビニ交付サービスについて")
        end
      end
    end

    context "ss-909" do
      # see: https://github.com/shirasagi/shirasagi/issues/909
      before(:each) do
        create(:article_page, name: "[TEST]top",     html: '<a href="/top/" class="top">anchor</a>')
        create(:article_page, name: "[TEST]TOP",     html: '<a href="/TOP/" class="TOP">ANCHOR</a>')
      end

      it "replace_html with string" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "anchor"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_css(".result table a", text: "[TEST]top")
        expect(page).to have_no_css(".result table a", text: "[TEST]TOP")

        page.accept_confirm do
          within "form.index-search" do
            fill_in "keyword", with: "anchor"
            fill_in "replacement", with: "アンカー"
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      end

      it "replace_url with string" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "/TOP/"
          check "option-url"
          click_button I18n.t('ss.buttons.search')
        end
        wait_for_ajax
        expect(page).to have_no_css(".result table a", text: "[TEST]top")
        expect(page).to have_css(".result table a", text: "[TEST]TOP")

        page.accept_confirm do
          within "form.index-search" do
            fill_in "keyword", with: "/TOP/"
            fill_in "replacement", with: "/kurashi/"
            check "option-url"
            click_button I18n.t("ss.buttons.replace_all")
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      end
    end
  end
end
