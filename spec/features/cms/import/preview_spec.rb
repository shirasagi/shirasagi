require 'spec_helper'

describe "cms_import", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  let!(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site.zip", nil, true) }
  let!(:name) { "sample-#{unique_id}" }

  before do
    create(:cms_import_job_file, site: site, name: name, basename: name, in_file: in_file)

    expected_files = [ "#{name}/index.html", "#{name}/article/page.html", "#{name}/css/style.css", "#{name}/img/logo.jpg" ]
    expect do
      Cms::ImportFilesJob.bind(site_id: site).perform_now
    end.to output(include(*expected_files)).to_stdout

    login_cms_user
  end

  it do
    visit cms_nodes_path(site: site)
    click_on name
    click_on I18n.t("cms.node_config")

    within "#addon-basic" do
      click_on I18n.t("ss.links.pc_preview")
    end

    switch_to_window(windows.last)

    script = <<~SCRIPT
      (function(resolve) {
        window.ss.promiseLoaded.then(() => resolve(window.ss.errorCount));
      })(arguments[0]);
    SCRIPT

    # site.zip の index.html には細工がしてあるので、本スクリプトを実行すると画像のロードエラー数を取得することができる。
    error_count = page.evaluate_async_script(script)
    expect(error_count).to eq 0
  end
end
