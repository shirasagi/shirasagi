require 'spec_helper'

describe Ezine::Mailer, type: :mailer, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :ezine_node_page, cur_site: site }

  describe "#verification_mail" do
    let(:entry) { create :ezine_entry, node_id: node.id }
    let(:mail) { Ezine::Mailer.verification_mail(entry) }

    it "mail attributes" do
      expect(mail.from.first).to eq node.sender_email
      expect(mail.to.first).to eq "entry@example.jp"
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end

  describe "#page_mail" do
    let(:page) { create :ezine_page, cur_site: site, cur_node: node, html: '<p>メール</p>', text: 'メール' }
    let(:mail) { Ezine::Mailer.page_mail(page, member) }

    describe "text_mail" do
      let(:member) { create :ezine_member, node: node, email: "member@example.jp", email_type: "text" }

      it "mail attributes" do
        expect(mail.from.first).to eq node.sender_email
        expect(mail.to.first).to eq "member@example.jp"
        expect(mail.subject.to_s).not_to eq ""
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source.to_s).not_to eq ""
      end
    end

    describe "html_mail" do
      let(:member) { create :ezine_member, node: node, email: "member@example.jp", email_type: "html" }

      it "mail attributes" do
        expect(mail.from.first).to eq node.sender_email
        expect(mail.to.first).to eq "member@example.jp"
        expect(mail.subject.to_s).not_to eq ""
        expect(mail.body.multipart?).to be_truthy
        expect(mail.body.parts[0].body.to_s).not_to eq ""
        expect(mail.body.parts[1].body.to_s).not_to eq ""
      end
    end
  end
end
