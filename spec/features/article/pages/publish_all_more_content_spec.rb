require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:node) { create(:article_node_page, cur_site: site) }

  context "with many alerts and/or errors" do
    let!(:page_with_a11y_error) do
      html = <<~HTML
        <img src="image.jpg">
        <p>ﾃｽﾄ</p>
      HTML
      create(:article_page, cur_site: site, cur_user: admin, cur_node: node, state: "closed", html: html)
    end
    let!(:item_branch) do
      create(
        :article_page, cur_site: site, cur_user: admin, cur_node: node, master: page_with_a11y_error,
        html: page_with_a11y_error.html, state: "closed")
    end

    it do
      login_user admin, to: article_pages_path(site: site, cid: node)

      first(".list-item[data-id='#{page_with_a11y_error.id}'] [type='checkbox']").click
      within ".list-head-action" do
        click_on I18n.t('ss.links.make_them_public')
      end

      within "form" do
        within "[data-id='#{page_with_a11y_error.id}']" do
          expect(page.first("[type='checkbox']")["disabled"]).to eq "false"
          expect(page).to have_css(".list-item-error", text: I18n.t("errors.messages.branch_is_already_existed"))
          expect(page).to have_css(".list-item-error", text: I18n.t("errors.messages.set_img_alt"))
          expect(page).to have_css(".list-item-error", text: I18n.t("errors.messages.invalid_kana_character"))

          expect(page.first(".ss-more-content")["data-is-open"]).to be_blank
          expect(page.first(".ss-more-content-body-wrap")["aria-expanded"]).to eq "false"
          bounding_client_rect(".ss-more-content-bottom-wrap").tap do |rect|
            expect(rect).to be_present
            # 表示されているかを確認 => 表示されている場合、高さを持つはず
            expect(rect["height"]).to be > 1
          end
          expect(page.first(".ss-more-content-bottom-wrap [data-action]")["disabled"]).to eq "false"

          click_on I18n.t("ss.links.more_all")

          expect(page.first(".ss-more-content")["data-is-open"]).to eq "true"
          expect(page.first(".ss-more-content-body-wrap")["aria-expanded"]).to eq "true"
          bounding_client_rect(".ss-more-content-bottom-wrap").tap do |rect|
            expect(rect).to be_present
            # 「全部見る」をクリックすると非表示になる => 非表示の場合、高さは0のはず
            expect(rect["height"]).to eq 0
          end
          # HTMLの場合、非表示の要素もタブが停止する。これを避けるためボタンにdisabledがセットされているはず
          expect(page.first(".ss-more-content-bottom-wrap [data-action]")["disabled"]).to eq "true"

          first("[type='checkbox']").check
        end

        click_on I18n.t('ss.buttons.make_them_public')
      end
      wait_for_notice I18n.t("ss.notice.published")

      Article::Page.find(page_with_a11y_error.id).tap do |after_page|
        expect(after_page.state).to eq "public"
      end
    end
  end

  context "with a few alerts and/or errors" do
    let!(:page_with_a11y_error) do
      html = <<~HTML
        <p>ﾃｽﾄ</p>
      HTML
      create(:article_page, cur_site: site, cur_user: admin, cur_node: node, state: "closed", html: html)
    end

    it do
      login_user admin, to: article_pages_path(site: site, cid: node)

      first(".list-item[data-id='#{page_with_a11y_error.id}'] [type='checkbox']").click
      within ".list-head-action" do
        click_on I18n.t('ss.links.make_them_public')
      end

      within "form" do
        within "[data-id='#{page_with_a11y_error.id}']" do
          expect(page.first("[type='checkbox']")["disabled"]).to eq "false"
          expect(page).to have_css(".list-item-error", text: I18n.t("errors.messages.invalid_kana_character"))

          expect(page.first(".ss-more-content")["data-is-open"]).to be_blank
          expect(page.first(".ss-more-content-body-wrap")["aria-expanded"]).to eq "true"
          bounding_client_rect(".ss-more-content-bottom-wrap").tap do |rect|
            expect(rect).to be_present
            # エラー数が少ない場合、「もっと見る」は表示されない => 非表示の場合、高さは0のはず
            expect(rect["height"]).to eq 0
          end
          # HTMLの場合、非表示の要素もタブが停止する。これを避けるためボタンにdisabledがセットされているはず
          expect(page.first(".ss-more-content-bottom-wrap [data-action]")["disabled"]).to eq "true"

          first("[type='checkbox']").check
        end

        click_on I18n.t('ss.buttons.make_them_public')
      end
      wait_for_notice I18n.t("ss.notice.published")

      Article::Page.find(page_with_a11y_error.id).tap do |after_page|
        expect(after_page.state).to eq "public"
      end
    end
  end
end
