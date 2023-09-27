require 'spec_helper'

describe Faq::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group1) do
    cms_group.update!(name: "シラサギ市")
    cms_group
  end
  let!(:group2) do
    name = 'シラサギ市/企画政策部/政策課'
    Cms::Group.where(name: name).first_or_create!(attributes_for(:cms_group, name: name))
  end
  let!(:layout) { create(:cms_layout, site: site, name: "FAQ", basename: 'faq') }
  let!(:category1) { create(:category_node_node, site: site, filename: "faq", name: "よくある質問") }
  let!(:category2) { create(:category_node_page, site: site, filename: "faq/c1", name: "くらし・手続き") }
  let!(:category3) { create(:category_node_page, site: site, filename: "faq/c2", name: "子育て・教育") }
  let!(:node1) do
    create(:faq_node_page, site: site, filename: "faq/docs", st_category_ids: [category1.id], group_ids: [ group2.id ])
  end
  let!(:node2) { create(:faq_node_page, site: site, filename: "faq/docs2", group_ids: [ group2.id ]) }
  let(:role) { create(:cms_role_admin, site_id: site.id, permissions: %w(import_private_faq_pages)) }
  let(:user) { create(:cms_user, uid: unique_id, name: unique_id, group_ids: [ group2.id ], role: role) }
  let!(:related_page) { create(:article_page, site: site, filename: "docs/page27.html", name: "関連ページ") }

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/faq/import_job/faq_pages.csv" }
  let!(:in_file) { Fs::UploadedFile.create_from_file(file_path) }
  let!(:ss_file) { create(:ss_file, site: site, in_file: in_file ) }

  describe ".perform_later" do
    context "with node1" do
      before do
        job_class = described_class.bind(site_id: site.id, node_id: node1.id, user_id: user.id)
        expect { job_class.perform_now(ss_file.id) }.to output(include("import start faq_pages.csv\n")).to_stdout
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        items = Faq::Page.site(site).where(filename: /^#{node1.filename}\//, depth: 3)
        expect(items.count).to be 4

        item = items.where(filename: "#{node1.filename}/page1.html").first
        expect(item.name).to eq "休日や夜間の戸籍の届出について"
        expect(item.index_name).to eq "一覧用タイトル"
        expect(item.layout.try(:name)).to eq "FAQ"
        expect(item.order).to be 10
        expect(item.keywords).to match_array %w(キーワード)
        expect(item.description).to eq "概要"
        expect(item.summary).to eq "サマリー"
        expect(item.question).to eq "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>"
        expect(item.category_ids).to match_array [category2.id, category3.id]
        expect(item.event_name).to eq "イベントタイトル"
        event_dates = %w(2016/09/08 2016/09/09 2016/09/10 2016/09/14 2016/09/15 2016/09/16).map { |d| d.in_time_zone.to_date }
        expect(item.event_dates).to eq event_dates
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
        expect(item.released_type).to eq "same_as_updated"
        expect(item.released.try(:strftime, "%Y/%m/%d %H:%M")).to eq "2016/09/07 19:11"
        expect(item.release_date.try(:strftime, "%Y/%m/%d %H:%M")).to eq nil
        expect(item.close_date.try(:strftime, "%Y/%m/%d %H:%M")).to eq nil
        expect(item.groups.pluck(:name)).to match_array ["シラサギ市/企画政策部/政策課"]
        unless SS.config.ss.disable_permission_level
          expect(item.permission_level).to be 1
        end
        expect(item.state).to eq "closed"
      end
    end

    context "with node2" do
      before do
        job_class = described_class.bind(site_id: site.id, node_id: node2.id, user_id: user.id)
        expect { job_class.perform_now(ss_file.id) }.to output(include("import start faq_pages.csv\n")).to_stdout
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        items = Faq::Page.site(site).where(filename: /^#{node2.filename}\//, depth: 3)
        expect(items.count).to be 4

        item = items.where(filename: "#{node2.filename}/page2.html").first
        expect(item.name).to eq "休日や夜間の戸籍の届出について"
        expect(item.index_name).to eq "一覧用タイトル"
        expect(item.layout.try(:name)).to eq "FAQ"
        expect(item.order).to be 10
        expect(item.keywords).to match_array %w(キーワード)
        expect(item.description).to eq "概要"
        expect(item.summary).to eq "サマリー"
        expect(item.question).to eq "<p>休日や夜間でも戸籍の届出は可能でしょうか。</p>"
        expect(item.html).to eq "<p>可能です。</p>"
        expect(item.category_ids).to match_array [ category3.id ]
        expect(item.event_name).to eq "イベントタイトル"
        event_dates = %w(2016/09/08 2016/09/09 2016/09/10 2016/09/14 2016/09/15 2016/09/16).map { |d| d.in_time_zone.to_date }
        expect(item.event_dates).to eq event_dates
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
        expect(item.released_type).to eq "same_as_created"
        expect(item.released.try(:strftime, "%Y/%m/%d %H:%M")).to eq item.created.try(:strftime, "%Y/%m/%d %H:%M")
        expect(item.release_date.try(:strftime, "%Y/%m/%d %H:%M")).to be_nil
        expect(item.close_date.try(:strftime, "%Y/%m/%d %H:%M")).to be_nil
        #expect(item.groups.pluck(:name)).to match_array ["シラサギ市/企画政策部/政策課"]
        unless SS.config.ss.disable_permission_level
          expect(item.permission_level).to be 1
        end
        expect(item.state).to eq "public"
      end
    end
  end
end
