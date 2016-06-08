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

        html = page.html.encode("UTF-8")
        expect(html).to include("アクセス日,リンクURL,アクセス数")
        expect(html).to include("#{access_log0.date.strftime("%Y-%m-%d")},#{access_log0.link_url},#{access_log0.count}")
        expect(html).to include("#{access_log1.date.strftime("%Y-%m-%d")},#{access_log1.link_url},#{access_log1.count}")
        expect(html).to include("#{access_log2.date.strftime("%Y-%m-%d")},#{access_log2.link_url},#{access_log2.count}")
        expect(html).to include("#{access_log3.date.strftime("%Y-%m-%d")},#{access_log3.link_url},#{access_log3.count}")
        expect(html).to include("#{access_log4.date.strftime("%Y-%m-%d")},#{access_log4.link_url},#{access_log4.count}")
        expect(html).to include("#{access_log5.date.strftime("%Y-%m-%d")},#{access_log5.link_url},#{access_log5.count}")
      end
    end

    context "monthly" do
      it do
        visit index_path
        click_on "検索"
        click_on "ダウンロード"
        expect(status_code).to eq 200

        html = page.html.encode("UTF-8")
        expect(html).to include("リンクURL,1日,2日,3日,4日,5日,6日,7日,8日,9日,10日,11日,12日,13日,14日,15日,16日,17日,18日,19日,20日,21日,22日,23日,24日,25日,26日,27日,28日")
        expect(html).to include("#{access_log0.link_url},")
        expect(html).to include("#{access_log1.link_url},")
        expect(html).to include("#{access_log2.link_url},")
        expect(html).to include("#{access_log3.link_url},")
        expect(html).to include("#{access_log4.link_url},")
        expect(html).to include("#{access_log5.link_url},")
        expect(html).to include(",#{access_log0.count}")
        expect(html).to include(",#{access_log1.count}")
        expect(html).to include(",#{access_log2.count}")
        expect(html).to include(",#{access_log3.count}")
        expect(html).to include(",#{access_log4.count}")
        expect(html).to include(",#{access_log5.count}")
      end
    end

    context "yearly" do
      it do
        visit index_path
        select "年間", from: "s[month]"
        click_on "検索"
        click_on "ダウンロード"
        expect(status_code).to eq 200

        html = page.html.encode("UTF-8")
        expect(html).to include("リンクURL,1月,2月,3月,4月,5月,6月,7月,8月,9月,10月,11月,12月,合計")
        expect(html).to include("#{access_log0.link_url},")
        expect(html).to include("#{access_log1.link_url},")
        expect(html).to include("#{access_log2.link_url},")
        expect(html).to include("#{access_log3.link_url},")
        expect(html).to include("#{access_log4.link_url},")
        expect(html).to include("#{access_log5.link_url},")
        expect(html).to include(",#{access_log0.count}")
        expect(html).to include(",#{access_log1.count}")
        expect(html).to include(",#{access_log2.count}")
        expect(html).to include(",#{access_log3.count}")
        expect(html).to include(",#{access_log4.count}")
        expect(html).to include(",#{access_log5.count}")
      end
    end
  end
end
