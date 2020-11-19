require 'spec_helper'

describe Faq::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group1) do
    name = 'シラサギ市'
    Cms::Group.where(name: name).first_or_create!(attributes_for(:cms_group, name: name))
  end
  let!(:group2) do
    name = 'シラサギ市/企画政策部/政策課'
    Cms::Group.where(name: name).first_or_create!(attributes_for(:cms_group, name: name))
  end
  let!(:layout) { create(:cms_layout, site: site, name: "FAQ") }
  let!(:category_1) { create(:category_node_node, site: site, filename: "faq", name: "よくある質問") }
  let!(:category_2) { create(:category_node_page, site: site, filename: "faq/c1", name: "くらし・手続き") }
  let!(:category_3) { create(:category_node_page, site: site, filename: "faq/c2", name: "子育て・教育") }
  let!(:node_1) { create(:faq_node_page, site: site, filename: "faq/docs", st_category_ids: [category_1.id], group_ids: [ group2.id ]) }
  let!(:node_2) { create(:faq_node_page, site: site, filename: "faq/docs2", group_ids: [ group2.id ]) }
  let(:role) { create(:cms_role_admin, site_id: site.id, permissions: ['import_private_faq_pages']) }
  let(:user) { create(:cms_user, uid: unique_id, name: unique_id, group_ids: [ group2.id ], role: role) }
  let!(:related_page) { create(:article_page, site: site, filename: "docs/page27.html", name: "関連ページ") }

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/faq/import_job/faq_pages.csv" }
  let!(:in_file) { Fs::UploadedFile.create_from_file(file_path) }
  let!(:ss_file) { create(:ss_file, site: site, in_file: in_file ) }

  describe ".perform_later" do
    context "with node_1" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node_1, user_id: user).perform_later(ss_file.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        items = Faq::Page.site(site).where(filename: /^#{node_1.filename}\//, depth: 3)
        expect(items.count).to be 4

        item = items.where(filename: "#{node_1.filename}/page1.html").first
        expect(item.name).to eq "休日や夜間の戸籍の届出について"
        expect(item.index_name).to eq "一覧用タイトル"
        expect(item.layout.try(:name)).to eq "FAQ"
        expect(item.order).to be 10
        expect(item.keywords).to match_array ["キーワード"]
        expect(item.description).to eq "概要"
        expect(item.summary).to eq "サマリー"
        expect(item.question).to eq "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>"
        expect(item.category_name_tree).to match_array ["よくある質問/くらし・手続き", "よくある質問/子育て・教育"]
        expect(item.event_name).to eq "イベントタイトル"
        expect(item.event_dates).to eq "2016/09/08\r\n2016/09/09\r\n2016/09/10\r\n2016/09/14\r\n2016/09/15\r\n2016/09/16"
        expect(item.related_page_ids).to match_array [related_page.id]
        expect(item.parent_crumb_urls).to match_array ["/faq/kurashi/"]
        expect(item.label(:contact_state)).to eq "表示"
        expect(item.contact_group.try(:name)).to eq "シラサギ市"
        expect(item.contact_charge).to eq "担当"
        expect(item.contact_tel).to eq "電話番号"
        expect(item.contact_fax).to eq "ファックス番号"
        expect(item.contact_email).to eq "メールアドレス"
        expect(item.contact_link_url).to eq "リンクURL"
        expect(item.contact_link_name).to eq "リンク名"
        expect(item.released.try(:strftime, "%Y/%m/%d %H:%M")).to eq "2016/09/07 19:11"
        expect(item.release_date.try(:strftime, "%Y/%m/%d %H:%M")).to eq nil
        expect(item.close_date.try(:strftime, "%Y/%m/%d %H:%M")).to eq nil
        expect(item.groups.pluck(:name)).to match_array ["シラサギ市/企画政策部/政策課"]
        expect(item.permission_level).to be 1
        expect(item.state).to eq "closed"
      end
    end

    context "with node_2" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node_2, user_id: user).perform_later(ss_file.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        items = Faq::Page.site(site).where(filename: /^#{node_2.filename}\//, depth: 3)
        expect(items.count).to be 4

        item = items.where(filename: "#{node_2.filename}/page2.html").first
        expect(item.name).to eq "休日や夜間の戸籍の届出について"
        expect(item.index_name).to eq "一覧用タイトル"
        expect(item.layout.try(:name)).to eq "FAQ"
        expect(item.order).to be 10
        expect(item.keywords).to match_array ["キーワード"]
        expect(item.description).to eq "概要"
        expect(item.summary).to eq "サマリー"
        expect(item.question).to eq "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>"
        expect(item.html).to eq "<p>可能です。</p>"
        expect(item.category_name_tree).to match_array ["よくある質問/子育て・教育"]
        expect(item.event_name).to eq "イベントタイトル"
        expect(item.event_dates).to eq "2016/09/08\r\n2016/09/09\r\n2016/09/10\r\n2016/09/14\r\n2016/09/15\r\n2016/09/16"
        expect(item.related_page_ids).to match_array [related_page.id]
        expect(item.parent_crumb_urls).to match_array ["/faq/kurashi/"]
        expect(item.label(:contact_state)).to eq "表示"
        #expect(item.contact_group.try(:name)).to eq "シラサギ市"
        expect(item.contact_charge).to eq "担当"
        expect(item.contact_tel).to eq "電話番号"
        expect(item.contact_fax).to eq "ファックス番号"
        expect(item.contact_email).to eq "メールアドレス"
        expect(item.contact_link_url).to eq "リンクURL"
        expect(item.contact_link_name).to eq "リンク名"
        expect(item.released.try(:strftime, "%Y/%m/%d %H:%M")).to eq "2016/09/07 19:11"
        expect(item.release_date.try(:strftime, "%Y/%m/%d %H:%M")).to eq "2016/09/01 19:11"
        expect(item.close_date.try(:strftime, "%Y/%m/%d %H:%M")).to eq "2016/10/01 19:11"
        #expect(item.groups.pluck(:name)).to match_array ["シラサギ市/企画政策部/政策課"]
        expect(item.permission_level).to be 1
        expect(item.state).to eq "closed"
      end
    end
  end
end
