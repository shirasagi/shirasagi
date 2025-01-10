require 'spec_helper'

describe "michecker", type: :feature, dbscope: :example, js: true, michecker: true do
  let(:site) { cms_site }
  let(:node) { create(:article_node_page, filename: "docs", name: "article") }
  let(:item) { create(:article_page, cur_node: node) }
  let(:show_path) { article_page_path site.id, node, item }

  context "route check" do
    before do
      login_cms_user

      #
      # テスト時 docker container 内の michecker を利用する。
      # テスト用サーバーは、ホストで稼働しているので、docker container 内からホストへアクセスする必要がある。
      # これを達成する方法として docker コマンドのオプションに --add-host localhost:ip-address というオプションをつける方法が紹介されているが、
      # うまく動作しない。
      # 参考: https://qiita.com/kai_kou/items/5182965ea75c85cf1e3f
      #
      # これは chrome の仕様制限によるもの。
      # --add-host オプションをつけて起動された container は /etc/hosts に "192.168.32.121 localhost" のような
      # レコードが追加されるが、chrome は localhost の解決に /etc/hosts を見ない。
      # chrome は localhost を常に loopback address へと解決する。
      # 参考: https://stackoverflow.com/questions/30579720/chrome-now-treating-ip-address-of-localhost-same-as-somesite-localhost
      #
      # そこで、mypage_domain に localhost やループバックアドレス以外の IP アドレスを設定してやる。
      #
      server = Capybara.current_session.server
      # site.mypage_domain = "#{server.host}:#{server.port}"
      site.mypage_domain = "#{Rails.application.ip_address}:#{server.port}"
      site.save!
    end

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    it do
      visit show_path
      click_on I18n.t('cms.links.michecker')

      switch_to_window(windows.last)
      wait_for_document_loading
      within ".michecker-head" do
        expect(page).to have_content(I18n.t("cms.cms/michecker.prepared"), wait: 60)
        click_on I18n.t('cms.cms/michecker.start')

        expect(page).to have_content(I18n.t("cms.cms/michecker.michecker_completed"), wait: 60)
      end

      expect(performed_jobs.size).to eq 1
      expect(Job::Log.count).to eq 1
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).to include(/#{::Regexp.escape(I18n.t('cms.cms/michecker/task.success'))}/)

      select I18n.t("cms.cms/michecker.accessibility"), from: "report-type"
      within ".michecker-report__accessibility" do
        expect(page).to have_content I18n.t('cms.cms/michecker/report.type')
      end

      select I18n.t("cms.cms/michecker.lowvision"), from: "report-type"
      within ".michecker-report__low-vision" do
        expect(page).to have_content I18n.t('cms.cms/michecker/report.type')
      end

      expect(Cms::Michecker::Result.all.count).to eq 1
      Cms::Michecker::Result.all.first.tap do |result|
        expect(result.target_type).to eq "page"
        expect(result.target_class).to eq item.class.name
        expect(result.target_id).to eq item.id.to_s
        expect(result.state).to eq "completed"
        expect(result.michecker_last_job_id).to be_present
        expect(result.michecker_last_result).to eq 0
        expect(result.michecker_last_executed_at).to be_present
        expect(::File.exist?(result.html_checker_report_filepath)).to be_truthy
        expect(::File.exist?(result.low_vision_report_filepath)).to be_truthy
        expect(::File.exist?(result.low_vision_source_filepath)).to be_truthy
        expect(::File.exist?(result.low_vision_result_filepath)).to be_truthy
      end
    end
  end
end
