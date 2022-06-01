require 'spec_helper'

describe "cms/line/messages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:show_path) { cms_line_message_path site, item }
  let(:copy_path) { copy_cms_line_message_path site, item }

  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let!(:page1) { create(:article_page, cur_node: node) }
  let!(:image) do
    tmp_ss_file(Cms::TempFile, user: cms_user, site: site,
      contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
  end

  let!(:item) { create :cms_line_message }
  let!(:template0) { create :cms_line_template_text, message: item }
  let!(:template1) { create :cms_line_template_image, message: item, image: image }
  let!(:template2) { create :cms_line_template_page, message: item, page: page1 }
  let!(:template3) { create :cms_line_template_json_body, message: item }
  let!(:copied_name) { "[#{I18n.t("workflow.cloned_name_prefix")}] #{item.name}" }

  def copied_item
    Cms::Line::Message.site(site).where(name: copied_name).first
  end

  context "copy" do
    before { login_cms_user }

    it "#show" do
      visit show_path

      # original templates
      within ".template0.text" do
        expect(page).to have_css(".talk-balloon", text: template0.text)
      end
      within ".template1.image" do
        within ".talk-balloon" do
          expect(page.find('img')[:src]).to start_with image.full_url
        end
      end
      within ".template2.page" do
        expect(page).to have_css(".talk-balloon .title", text: template2.title)
        expect(page).to have_css(".talk-balloon .summary", text: template2.summary)
        within ".talk-balloon .footer" do
          expect(page.find('a')[:href]).to start_with(page1.full_url)
        end
      end
      within ".template3.json_body" do
        expect(page).to have_css(".talk-balloon", text: "{JSONテンプレート;}")
      end

      visit copy_path
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within ".list-items" do
        expect(page).to have_css(".list-item a", text: copied_name)
        click_on copied_name
      end

      # copied templates
      within ".template0.text" do
        expect(page).to have_css(".talk-balloon", text: template0.text)
      end
      within ".template1.image" do
        within ".talk-balloon" do
          expect(page.find('img')[:src]).to start_with(copied_item.templates[1].image.full_url)
        end
      end
      within ".template2.page" do
        expect(page).to have_css(".talk-balloon .title", text: template2.title)
        expect(page).to have_css(".talk-balloon .summary", text: template2.summary)
        within ".talk-balloon .footer" do
          expect(page.find('a')[:href]).to start_with page1.full_url
        end
      end
      within ".template3.json_body" do
        expect(page).to have_css(".talk-balloon", text: "{JSONテンプレート;}")
      end
    end

    it "#show" do
      visit show_path
      within "#menu" do
        expect(page).to have_link I18n.t("ss.links.deliver")
        click_on I18n.t("ss.links.deliver")
      end

      capture_line_bot_client do |capture|
        perform_enqueued_jobs do
          within "footer.send" do
            page.accept_confirm do
              click_on I18n.t("ss.links.deliver")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_deliver'))
        end
        expect(capture.multicast.count).to eq 0
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.completed"))
      end

      visit copy_path
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within ".list-items" do
        expect(page).to have_css(".list-item a", text: copied_name)
        click_on copied_name
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t("cms.options.deliver_state.draft"))
      end
    end
  end
end
