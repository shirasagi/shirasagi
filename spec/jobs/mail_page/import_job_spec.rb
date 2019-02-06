require 'spec_helper'

describe MailPage::ImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:node1) { create :mail_page_node_page, filename: "node1", arrival_days: 3 }
  let(:node2) do
    create :mail_page_node_page, filename: "node2", arrival_days: 3,
    mail_page_from_conditions: ["sample@example.jp"],
    mail_page_to_conditions: ["sample@example.jp"]
  end
  let(:node3) do
    create :mail_page_node_page, filename: "node3", arrival_days: 3,
    mail_page_from_conditions: ["example.jp"],
    mail_page_to_conditions: ["example.jp"]
  end

  let(:decoded) { Fs.read("#{Rails.root}/spec/fixtures/mail_page/decoded") }
  let(:utf_8_eml) do
    file = "#{Rails.root}/private/files/mail_page_files/#{Time.zone.now.to_i}"
    Fs.mkdir_p "#{Rails.root}/private/files/mail_page_files"
    Fs.binwrite file, Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml")
    file
  end
  let(:iso_2022_jp_eml) do
    file = "#{Rails.root}/private/files/mail_page_files/#{Time.zone.now.to_i}"
    Fs.mkdir_p "#{Rails.root}/private/files/mail_page_files"
    Fs.binwrite file, Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml")
    file
  end

  let(:top_page) { create :cms_page, filename: "index.html", name: "top", layout: nil }
  let(:urgency_layout) { create :cms_layout, html: "<html><head></head><body>switched</body></html>" }
  let(:urgency_node) do
    create :urgency_node_layout, urgency_mail_page_layout: urgency_layout,
      filename: "urgency_node"
  end
  let(:node4) do
    create :mail_page_node_page, filename: "node2", arrival_days: 3,
      mail_page_from_conditions: ["sample@example.jp"],
      mail_page_to_conditions: ["sample@example.jp"],
      urgency_state: "enabled", urgency_node: urgency_node
  end

  describe ".perform_later" do
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
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))

        page1 = MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).first
        page2 = MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).first
        page3 = MailPage::Page.site(site).where(filename: /^#{node3.filename}\//).first

        expect(page1).to be nil
        expect(page2.html.split("<br />")).to match_array decoded.split("\n")
        expect(page3.html.split("<br />")).to match_array decoded.split("\n")
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
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))

        page1 = MailPage::Page.site(site).where(filename: /^#{node1.filename}\//).first
        page2 = MailPage::Page.site(site).where(filename: /^#{node2.filename}\//).first
        page3 = MailPage::Page.site(site).where(filename: /^#{node3.filename}\//).first

        expect(page1).to be nil
        expect(page2.html.split("<br />")).to match_array decoded.split("\n")
        expect(page3.html.split("<br />")).to match_array decoded.split("\n")
      end
    end

    context "switch urgency_layout" do
      before do
        top_page
        urgency_layout
        urgency_node
        node4
        perform_enqueued_jobs do
          described_class.bind(site_id: site).perform_later(iso_2022_jp_eml)
        end
      end

      it do
        top = Cms::Page.where(filename: "index.html").first
        expect(top.layout_id).to eq urgency_layout.id
      end
    end
  end
end
