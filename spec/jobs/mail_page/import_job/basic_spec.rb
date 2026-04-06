require 'spec_helper'

describe MailPage::ImportJob, dbscope: :example do
  let(:site) { cms_site }

  describe ".perform_later" do
    let(:node1) { create :mail_page_node_page, layout: create_cms_layout, filename: "node1", arrival_days: rand(1..5) }
    let(:node2) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node2", arrival_days: rand(1..5),
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"]
    end
    let(:node3) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node3", arrival_days: rand(1..5),
      mail_page_from_conditions: ["example.jp"],
      mail_page_to_conditions: ["example.jp"]
    end

    let(:decoded) { Fs.read("#{Rails.root}/spec/fixtures/mail_page/basic/decoded") }
    let(:utf_8_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/basic/UTF-8.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end
    let(:iso_2022_jp_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/basic/ISO-2022-JP.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end

    context "with UTF-8 eml" do
      before do
        node1
        node2
        node3
        perform_enqueued_jobs do
          described_class.bind(site_id: site).perform_later(utf_8_eml)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        page1 = MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).first
        page2 = MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).first
        page3 = MailPage::Page.site(site).where(filename: /^#{node3.filename}\//).first

        expect(page1).to be_nil

        expect(page2.layout_id).to eq node2.layout_id
        expect(page2.group_ids).to eq node2.group_ids
        expect(page2.name).to eq "UTF-8"
        expect(page2.html.split("<br />")).to match_array decoded.split("\n")
        expect(page2.arrival_start_date).to be_present
        expect(page2.arrival_close_date).to eq page2.arrival_start_date.advance(days: node2.arrival_days)
        expect(page2.state).to eq "public"

        expect(page3.layout_id).to eq node3.layout_id
        expect(page3.group_ids).to eq node3.group_ids
        expect(page3.name).to eq "UTF-8"
        expect(page3.html.split("<br />")).to match_array decoded.split("\n")
        expect(page3.arrival_start_date).to be_present
        expect(page3.arrival_close_date).to eq page3.arrival_start_date.advance(days: node3.arrival_days)
        expect(page3.state).to eq "public"
      end
    end

    context "with ISO-2022-JP eml" do
      before do
        node1
        node2
        node3
        perform_enqueued_jobs do
          described_class.bind(site_id: site).perform_later(iso_2022_jp_eml)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        page1 = MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).first
        page2 = MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).first
        page3 = MailPage::Page.site(site).where(filename: /^#{node3.filename}\//).first

        expect(page1).to be nil

        expect(page2.layout_id).to eq node2.layout_id
        expect(page2.group_ids).to eq node2.group_ids
        expect(page2.name).to eq "ISO-2022-JP"
        expect(page2.html.split("<br />")).to match_array decoded.split("\n")
        expect(page2.arrival_start_date).to be_present
        expect(page2.arrival_close_date).to eq page2.arrival_start_date.advance(days: node2.arrival_days)
        expect(page2.state).to eq "public"

        expect(page3.layout_id).to eq node3.layout_id
        expect(page3.group_ids).to eq node3.group_ids
        expect(page3.name).to eq "ISO-2022-JP"
        expect(page3.html.split("<br />")).to match_array decoded.split("\n")
        expect(page3.arrival_start_date).to be_present
        expect(page3.arrival_close_date).to eq page3.arrival_start_date.advance(days: node3.arrival_days)
        expect(page3.state).to eq "public"
      end
    end
  end

  context "switch urgency_layout" do
    let(:top_page) { create :cms_page, filename: "index.html", name: "top", layout: nil }
    let(:urgency_layout) { create :cms_layout, html: "<html><head></head><body>switched</body></html>" }
    let(:urgency_node) do
      create :urgency_node_layout, urgency_mail_page_layout: urgency_layout,
        filename: "urgency_node"
    end
    let(:node) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node", arrival_days: rand(1..5),
        mail_page_from_conditions: ["sample@example.jp"],
        mail_page_to_conditions: ["sample@example.jp"],
        urgency_state: "enabled", urgency_node: urgency_node
    end
    let(:iso_2022_jp_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/basic/ISO-2022-JP.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end

    before do
      top_page
      urgency_layout
      urgency_node
      node
      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(iso_2022_jp_eml)
      end
    end

    it do
      top = Cms::Page.where(filename: "index.html").first
      expect(top.layout_id).to eq urgency_layout.id
    end
  end

  context "perform at same time" do
    let(:now) { Time.zone.now }
    let(:node1) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node1", arrival_days: rand(1..5),
      mail_page_from_conditions: ["bosai@example.jp"],
      mail_page_to_conditions: ["bosai@example.jp"]
    end
    let(:node2) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node2", arrival_days: rand(1..5),
      mail_page_from_conditions: ["kotsu@example.jp"],
      mail_page_to_conditions: ["kotsu@example.jp"]
    end

    let(:bosai_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/same_time/bosai.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end
    let(:kotsu_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/same_time/kotsu.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end
    let(:bosai_decoded) { Fs.read("#{Rails.root}/spec/fixtures/mail_page/same_time/bosai_decoded") }
    let(:kotsu_decoded) { Fs.read("#{Rails.root}/spec/fixtures/mail_page/same_time/kotsu_decoded") }

    before do
      node1
      node2
    end

    it do
      Timecop.freeze(now) do
        perform_enqueued_jobs do
          kotsu_eml
          bosai_eml
          described_class.bind(site_id: site).perform_later(kotsu_eml)
          described_class.bind(site_id: site).perform_later(bosai_eml)
        end
      end

      expect(MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).count).to eq 1
      expect(MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).count).to eq 1

      page1 = MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).first
      page2 = MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).first

      expect(page1.layout_id).to eq node1.layout_id
      expect(page1.group_ids).to eq node1.group_ids
      expect(page1.name).to eq "防災情報"
      expect(page1.html.split("<br />")).to match_array bosai_decoded.split("\n")
      expect(page1.arrival_start_date).to be_present
      expect(page1.arrival_close_date).to eq page1.arrival_start_date.advance(days: node1.arrival_days)
      expect(page1.state).to eq "public"

      expect(page2.layout_id).to eq node2.layout_id
      expect(page2.group_ids).to eq node2.group_ids
      expect(page2.name).to eq "交通情報"
      expect(page2.html.split("<br />")).to match_array kotsu_decoded.split("\n")
      expect(page2.arrival_start_date).to be_present
      expect(page2.arrival_close_date).to eq page2.arrival_start_date.advance(days: node2.arrival_days)
      expect(page2.state).to eq "public"
    end
  end

  context "perform at multiple_to" do
    let(:node1) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node1", arrival_days: rand(1..5),
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["bosai@example.jp"]
    end
    let(:node2) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node2", arrival_days: rand(1..5),
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["kotsu@example.jp"]
    end

    let(:bosai_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/multiple_to/bosai.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end
    let(:kotsu_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/multiple_to/kotsu.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end

    before do
      node1
      node2
    end

    it do
      perform_enqueued_jobs do
        kotsu_eml
        bosai_eml
        described_class.bind(site_id: site).perform_later(kotsu_eml)
        described_class.bind(site_id: site).perform_later(bosai_eml)
      end

      expect(MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).count).to eq 1
      expect(MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).count).to eq 1
    end
  end

  context "enable auto_link" do
    let(:node1) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node1", arrival_days: rand(1..5),
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"],
      auto_link_state: "enabled"
    end
    let(:node2) do
      create :mail_page_node_page, layout: create_cms_layout, filename: "node2", arrival_days: rand(1..5),
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"],
      auto_link_state: "disabled"
    end
    let(:mail_eml) do
      data = Fs.binread("#{Rails.root}/spec/fixtures/mail_page/auto_link/UTF-8.eml")
      SS::MailHandler.write_eml(data, "mail_page")
    end
    let(:html1) do
      Fs.read("#{Rails.root}/spec/fixtures/mail_page/auto_link/html1")
    end
    let(:html2) do
      Fs.read("#{Rails.root}/spec/fixtures/mail_page/auto_link/html2")
    end

    before do
      node1
      node2
    end

    it do
      perform_enqueued_jobs do
        mail_eml
        described_class.bind(site_id: site).perform_later(mail_eml)
      end

      page1 = MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).first
      expect(page1.layout_id).to eq node1.layout_id
      expect(page1.group_ids).to eq node1.group_ids
      expect(page1.name).to eq "熊の目撃情報"
      expect(page1.html).to eq html1

      page2 = MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).first
      expect(page2.layout_id).to eq node2.layout_id
      expect(page2.group_ids).to eq node2.group_ids
      expect(page2.name).to eq "熊の目撃情報"
      expect(page2.html).to eq html2
    end
  end
end
