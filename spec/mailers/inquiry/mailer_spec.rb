require 'spec_helper'

describe Inquiry::Mailer, type: :mailer, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form }
  let(:answer) { Inquiry::Answer.new }

  describe "#notify_mail" do
    let(:mail) { Inquiry::Mailer.notify_mail(site, node, answer) }

    it "mail attributes" do
      expect(mail.from.first).to eq "from@example.jp"
      expect(mail.to.first).to eq "notice@example.jp"
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end

  describe "#reply_mail" do
    context "no reply_email_address" do
      let(:mail) { Inquiry::Mailer.reply_mail(site, node, answer) }

      it "mail_to blank" do
        expect(mail.to).to eq nil
      end
    end
  end
end
