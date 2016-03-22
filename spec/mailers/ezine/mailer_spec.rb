require 'spec_helper'

describe Ezine::Mailer, type: :mailer, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :ezine_node_page }

  describe "#verification_mail" do
    let(:entry) { create :ezine_entry, node_id: node.id }
    let(:mail) { Ezine::Mailer.verification_mail(entry) }

    it "mail attributes" do
      expect(mail.from.first).to eq "from@example.jp"
      expect(mail.to.first).to eq "entry@example.jp"
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end

  describe "#page_mail" do
    let(:page) { create :ezine_page, filename: "#{node.filename}/page" }
    let(:mail) { Ezine::Mailer.page_mail(page, member) }

    describe "text_mail" do
      let(:member) { create :ezine_member, email: "member@example.jp", email_type: "text" }

      it "mail attributes" do
        expect(mail.from.first).to eq "from@example.jp"
        expect(mail.to.first).to eq "member@example.jp"
        expect(mail.subject.to_s).not_to eq ""
        expect(mail.body.to_s).not_to eq ""
      end
    end

    describe "html_mail" do
      let(:member) { create :ezine_member, email: "member@example.jp", email_type: "html" }

      it "mail attributes" do
        expect(mail.from.first).to eq "from@example.jp"
        expect(mail.to.first).to eq "member@example.jp"
        expect(mail.subject.to_s).not_to eq ""
        #expect(mail.body.to_s).not_to eq ""
      end
    end
  end
end
