require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  describe "cms/pages" do
    let(:html_with_error) { '<p>ﾃｽﾄ</p><p>①②③④⑤⑥⑦⑧⑨</p>' }

    it do
      login_user user, to: new_cms_page_path(site: site)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        fill_in_ckeditor "item[html]", with: html_with_error

        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']")
        end
      end
    end
  end

  describe "node/pages with node 'cms/page'" do
    let!(:node) { create :cms_node_page, cur_site: site }
    let(:html_with_error) { '<p>ﾃｽﾄ</p><p>①②③④⑤⑥⑦⑧⑨</p>' }

    it do
      login_user user, to: new_node_page_path(site: site, cid: node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        fill_in_ckeditor "item[html]", with: html_with_error

        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']")
        end
      end
    end
  end

  describe "node/pages with node 'article/page'" do
    let!(:node) { create :article_node_page, cur_site: site }
    let(:html_with_error) { '<p>ﾃｽﾄ</p><p>①②③④⑤⑥⑦⑧⑨</p>' }

    it do
      login_user user, to: new_node_page_path(site: site, cid: node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        fill_in_ckeditor "item[html]", with: html_with_error

        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']")
        end
      end
    end
  end
end
