require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }

  context "without login" do
    it do
      visit article_pages_path(site: site.id, cid: node)
      expect(current_path).to eq sns_login_path
    end
  end

  context "without permissions" do
    let!(:role) { create :cms_role, cur_site: site, permissions: [] }
    let!(:user) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }

    before do
      login_user user
    end

    around do |example|
      @save_logger = Rails.logger

      tmpfile do |log_file|
        @log_file = log_file
        Rails.logger = ::Logger.new(log_file)
        example.run
      ensure
        Rails.logger = @save_logger
      end

      @save_logger = nil
      @log_file = nil
    end

    it do
      visit article_pages_path(site: site.id, cid: node)
      expect(page).to have_title(/403 Forbidden/)
      expect(page).to have_css("#addon-basic .addon-head", text: I18n.t("ss.rescues.default.head"))
      # expect(page).to have_css("#addon-basic .addon-body", html: I18n.t("ss.rescues.default.body"))

      @log_file.flush
      log_text = ::File.read(@log_file.path)
      expect(log_text).to include("FATAL -- : RuntimeError (403):\n")
    end
  end
end
