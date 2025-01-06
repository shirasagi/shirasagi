require 'spec_helper'

describe 'board_agents_nodes_anpi_post', type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :board_node_post, cur_site: site, layout_id: layout.id, deny_url: 'allow' }
  let(:board) { create :board_post, node_id: node.id }

  context 'usual case' do
    let!(:item) { create :board_post, cur_site: site, cur_node: node }

    it do
      visit node.full_url

      expect(page).to have_css(".email[href='mailto:#{item.email}']")
      query = { back_to: node.url, ref: item.poster_url }.to_query
      expect(page).to have_css(".url[href='/.mypage/redirect?#{query}']")
    end
  end

  context 'protect from xss vulnerability' do
    let(:http_url) { "http://#{unique_id}.example.jp" }
    let(:https_url) { "https://#{unique_id}.example.jp" }
    let(:mail_to_url) { "mailto:#{unique_id}@example.jp" }
    let(:text) { [ http_url, https_url, mail_to_url ].join("\n") }
    let!(:item) { create :board_post, cur_site: site, cur_node: node, text: text }

    before do
      item.set(email: "javascript:alert('危険な操作');", poster_url: "javascript:alert('危険な操作');")
    end

    it do
      visit node.full_url

      expect(page).to have_css(".body a[href='/.mypage/redirect?ref=#{CGI.escape(http_url)}']")
      expect(page).to have_css(".body a[href='/.mypage/redirect?ref=#{CGI.escape(https_url)}']")
      expect(page).to have_no_css("a[href='#{mail_to_url}']")
      expect(page).to have_no_css("a[href='#{CGI.escape(mail_to_url)}']")
      expect(page).to have_no_css(".email")
      expect(page).to have_no_css(".url")
    end
  end

  context "new board" do
    let(:index_url) { URI.parse "http://#{site.domain}/#{node.filename}/new" }

    it "success to post" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.board-post-form' do
        within 'div.columns' do
          fill_in "item[name]", with: "test_name"
          fill_in "item[poster]", with: "test_poster"
          fill_in 'item[text]', with: 'test_text'
          fill_in "item[delete_key]", with: "test"
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: SS::Captcha.order_by(id: -1).first.captcha_text
        end
        click_button '投稿'
      end

      expect(page).to have_content I18n.t("ss.notice.saved")
    end

    it "fail to post with blank at required" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.board-post-form' do
        within 'div.columns' do
          fill_in "item[name]", with: ""
          fill_in "item[poster]", with: ""
          fill_in 'item[text]', with: ""
          fill_in "item[delete_key]", with: ""
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: ""
        end
        click_button '投稿'
      end

      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.poster")}#{I18n.t("errors.messages.blank")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.delete_key")}#{I18n.t("board.errors.invalid_delete_key")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.text")}#{I18n.t("errors.messages.blank")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.cms/addon/captcha.captcha")}#{I18n.t("simple_captcha.message.default")}"
    end
  end

  context "post reply" do
    let(:index_url) { URI.parse "http://#{site.domain}/#{node.filename}/#{board.id}/new" }

    it "success to reply" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.board-post-form' do
        within 'div.columns' do
          fill_in "item[name]", with: "Re"
          fill_in "item[poster]", with: "poster"
          fill_in "item[text]", with: "text text"
          fill_in "item[delete_key]", with: "pass"
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: SS::Captcha.order_by(id: -1).first.captcha_text
        end
        click_button '投稿'
      end

      expect(page).to have_content I18n.t("ss.notice.saved")
    end

    it "fail to reply with blank at required" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.board-post-form' do
        within 'div.columns' do
          fill_in "item[name]", with: ""
          fill_in "item[poster]", with: ""
          fill_in "item[text]", with: ""
          fill_in "item[delete_key]", with: ""
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: ""
        end
        click_button '投稿'
      end

      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.poster")}#{I18n.t("errors.messages.blank")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.delete_key")}#{I18n.t("board.errors.invalid_delete_key")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.text")}#{I18n.t("errors.messages.blank")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.cms/addon/captcha.captcha")}#{I18n.t("simple_captcha.message.default")}"
    end
  end

  context "post reply" do
    let(:index_url) { URI.parse "http://#{site.domain}/#{node.filename}/#{board.id}/delete" }

    it "success to delete" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.board-post-form' do
        within 'div.columns' do
          fill_in "item[delete_key]", with: "pass"
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: SS::Captcha.order_by(id: -1).first.captcha_text
        end
        click_button '削除'
      end

      expect(page).to have_content I18n.t("ss.notice.deleted")
    end

    it "failed to delete with blank at required" do
      visit index_url
      expect(status_code).to eq 200
      within 'div.board-post-form' do
        within 'div.columns' do
          fill_in "item[delete_key]", with: ""
        end
        within 'div.simple-captcha' do
          fill_in "answer[captcha_answer]", with: ""
        end
        click_button '削除'
      end

      expect(page).to have_content "#{I18n.t("mongoid.attributes.board/post.delete_key")}#{I18n.t("board.errors.invalid_delete_key")}"
      expect(page).to have_content "#{I18n.t("mongoid.attributes.cms/addon/captcha.captcha")}#{I18n.t("simple_captcha.message.default")}"
    end
  end
end
