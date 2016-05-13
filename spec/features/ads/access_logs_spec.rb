require 'spec_helper'

describe "ads_access_logs" do
  subject(:site) { cms_site }
  subject(:node) { create_once :ads_node_banner, name: "ads" }
  subject(:index_path) { ads_access_logs_path site.id, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end

  context "download" do
    let!(:access_log0) { create :ads_access_log, cur_site: site, node_id: node.id }
    let!(:access_log1) { create :ads_access_log, cur_site: site, node_id: node.id }
    let!(:access_log2) { create :ads_access_log, cur_site: site, node_id: node.id }
    let!(:access_log3) { create :ads_access_log, cur_site: site, node_id: node.id }
    let!(:access_log4) { create :ads_access_log, cur_site: site, node_id: node.id }
    let!(:access_log5) { create :ads_access_log, cur_site: site, node_id: node.id }

    before { login_cms_user }

    context "recent" do
      it do
        visit index_path

        click_on "ダウンロード"
        expect(status_code).to eq 200

        expect(page.html).to include("date,link_url,count")
        expect(page.html).to include("#{access_log0.date.strftime("%Y-%m-%d")},#{access_log0.link_url},#{access_log0.count}")
        expect(page.html).to include("#{access_log1.date.strftime("%Y-%m-%d")},#{access_log1.link_url},#{access_log1.count}")
        expect(page.html).to include("#{access_log2.date.strftime("%Y-%m-%d")},#{access_log2.link_url},#{access_log2.count}")
        expect(page.html).to include("#{access_log3.date.strftime("%Y-%m-%d")},#{access_log3.link_url},#{access_log3.count}")
        expect(page.html).to include("#{access_log4.date.strftime("%Y-%m-%d")},#{access_log4.link_url},#{access_log4.count}")
        expect(page.html).to include("#{access_log5.date.strftime("%Y-%m-%d")},#{access_log5.link_url},#{access_log5.count}")
      end
    end

    context "monthly" do
      it do
        visit index_path
        click_on "検索"
        click_on "ダウンロード"
        expect(status_code).to eq 200

        expect(page.html).to include("link_url,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28")
        expect(page.html).to include("#{access_log0.link_url},")
        expect(page.html).to include("#{access_log1.link_url},")
        expect(page.html).to include("#{access_log2.link_url},")
        expect(page.html).to include("#{access_log3.link_url},")
        expect(page.html).to include("#{access_log4.link_url},")
        expect(page.html).to include("#{access_log5.link_url},")
        expect(page.html).to include(",#{access_log0.count}")
        expect(page.html).to include(",#{access_log1.count}")
        expect(page.html).to include(",#{access_log2.count}")
        expect(page.html).to include(",#{access_log3.count}")
        expect(page.html).to include(",#{access_log4.count}")
        expect(page.html).to include(",#{access_log5.count}")
      end
    end

    context "yearly" do
      it do
        visit index_path
        select "年間", from: "s[month]"
        click_on "検索"
        click_on "ダウンロード"
        expect(status_code).to eq 200

        expect(page.html).to include("link_url,1,2,3,4,5,6,7,8,9,10,11,12,total")
        expect(page.html).to include("#{access_log0.link_url},")
        expect(page.html).to include("#{access_log1.link_url},")
        expect(page.html).to include("#{access_log2.link_url},")
        expect(page.html).to include("#{access_log3.link_url},")
        expect(page.html).to include("#{access_log4.link_url},")
        expect(page.html).to include("#{access_log5.link_url},")
        expect(page.html).to include(",#{access_log0.count}")
        expect(page.html).to include(",#{access_log1.count}")
        expect(page.html).to include(",#{access_log2.count}")
        expect(page.html).to include(",#{access_log3.count}")
        expect(page.html).to include(",#{access_log4.count}")
        expect(page.html).to include(",#{access_log5.count}")
      end
    end
  end
end
