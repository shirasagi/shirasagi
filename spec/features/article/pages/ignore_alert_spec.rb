require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page1) { create :article_page, cur_site: site, cur_node: node, state: "public" }
  let!(:page2) { create :article_page, cur_site: site, cur_node: node, state: "public" }
  let(:html) { "<p>#{unique_id}</p>" }

  before do
    page1.related_page_ids = [ page2.id ]
    page1.save!
    page1.reload

    role = cms_role
    role.permissions = role.permissions - %w(edit_cms_ignore_alert edit_cms_ignore_syntax_check)
    role.save!

    login_cms_user
  end

  context "https://github.com/shirasagi/shirasagi/issues/4543" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on page2.name
      click_on I18n.t("ss.buttons.edit")

      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      page2.reload
      expect(page2.html).to eq html
    end
  end

  context "with backlink" do
    context "when withdraw is clicked" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        click_on I18n.t("ss.buttons.edit")

        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: html

          click_on I18n.t("ss.buttons.withdraw")
        end

        within_cbox do
          expect(page).to have_css("li", text: I18n.t('ss.confirm.contains_url_expect'))
          expect(page).to have_no_css('.save')
        end
      end
    end

    context "when replace_save is clicked" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        click_on I18n.t("ss.buttons.edit")

        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: html

          click_on I18n.t("ss.buttons.replace_save")
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")
      end
    end

    context "when publish_save is clicked" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on page2.name
        click_on I18n.t("ss.buttons.edit")

        within "form#item-form" do
          fill_in_ckeditor "item[html]", with: html

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
    end
  end

  context "with syntax check" do
    shared_examples "ignore button on clicking withdraw / replace_save / publish_save" do
      context "when withdraw is clicked" do
        it do
          visit article_pages_path(site: site, cid: node)
          click_on page1.name
          click_on I18n.t("ss.buttons.edit")

          within "form#item-form" do
            fill_in_ckeditor "item[html]", with: html

            click_on I18n.t("ss.buttons.withdraw")
          end

          within_cbox do
            expect(page).to have_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
            expect(page).to have_css('.save', text: I18n.t("ss.buttons.ignore_alert"))

            click_on I18n.t("ss.buttons.ignore_alert")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          Article::Page.find(page1.id).tap do |after_page|
            expect(after_page.status).to eq "closed"
          end
        end
      end

      context "when replace_save is clicked" do
        it do
          visit article_pages_path(site: site, cid: node)
          click_on page1.name
          click_on I18n.t("ss.buttons.edit")

          within "form#item-form" do
            fill_in_ckeditor "item[html]", with: html

            click_on I18n.t("ss.buttons.replace_save")
          end

          within_cbox do
            expect(page).to have_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
            expect(page).to have_css('.save', text: I18n.t("ss.buttons.ignore_alert"))

            click_on I18n.t("ss.buttons.ignore_alert")
          end
          wait_for_notice I18n.t("workflow.notice.created_branch_page")

          Article::Page.find(page1.id).tap do |after_page|
            expect(after_page.status).to eq "public"
          end
          Article::Page.where(master_id: page1.id).first.tap do |branch_page|
            expect(branch_page.status).to eq "closed"
          end
        end
      end

      context "when publish_save is clicked" do
        it do
          visit article_pages_path(site: site, cid: node)
          click_on page1.name
          click_on I18n.t("ss.buttons.edit")

          within "form#item-form" do
            fill_in_ckeditor "item[html]", with: html

            click_on I18n.t("ss.buttons.publish_save")
          end

          within_cbox do
            expect(page).to have_css("li", text: I18n.t('cms.confirm.disallow_edit_ignore_syntax_check'))
            # 権限「edit_cms_ignore_syntax_check」がないので、ボタン「警告を無視する」は表示されない
            expect(page).to have_no_css('.save')
          end
        end
      end
    end

    context "with order_of_h checker error" do
      let(:html) { "<h6>#{unique_id}</h6>" }

      it_behaves_like "ignore button on clicking withdraw / replace_save / publish_save"
    end

    context "with embedded_media checker error" do
      let(:html) { '<embed type="video/webm" src="/fs/1/1/1/_/video.mp4">' }

      it_behaves_like "ignore button on clicking withdraw / replace_save / publish_save"
    end

    context "with order_of_h checker error and embedded_media checker error" do
      let(:html) { "<h6>#{unique_id}</h6>" + '<embed type="video/webm" src="/fs/1/1/1/_/video.mp4">' }

      it_behaves_like "ignore button on clicking withdraw / replace_save / publish_save"
    end
  end
end
