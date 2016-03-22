require 'spec_helper'

describe Workflow::Mailer, type: :mailer, dbscope: :example do
  let(:site) { cms_site }
  let(:page) { create :cms_page }
  let(:user1) { create :ss_user, email: "user1@example.jp" }
  let(:user2) { create :ss_user, email: "user2@example.jp" }

  describe "#request_mail" do
    let(:mail) do
      Workflow::Mailer.request_mail(
        f_uid: user1.id,
        t_uid: user2.id,
        site: site,
        page: page,
        url: "http://example.jp/",
        comment: "comment",
      )
    end

    it "mail attributes" do
      expect(mail.from.first).to eq user1.email
      expect(mail.to.first).to eq user2.email
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end

  describe "#approve_mail" do
    let(:mail) do
      Workflow::Mailer.approve_mail(
        f_uid: user1.id,
        t_uid: user2.id,
        site: site,
        page: page,
        url: "http://example.jp/",
      )
    end

    it "mail attributes" do
      expect(mail.from.first).to eq user1.email
      expect(mail.to.first).to eq user2.email
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end

  describe "#remand_mail" do
    let(:mail) do
      Workflow::Mailer.remand_mail(
        f_uid: user1.id,
        t_uid: user2.id,
        site: site,
        page: page,
        url: "http://example.jp/",
        comment: "comment",
      )
    end

    it "mail attributes" do
      expect(mail.from.first).to eq user1.email
      expect(mail.to.first).to eq user2.email
      expect(mail.subject.to_s).not_to eq ""
      expect(mail.body.to_s).not_to eq ""
    end
  end
end
