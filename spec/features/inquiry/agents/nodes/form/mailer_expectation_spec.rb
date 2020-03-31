require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'disabled',
      notice_state: 'enabled',
      notice_content: 'enabled',
      notice_email: 'notice@example.jp',
      from_name: 'admin',
      from_email: 'admin@example.jp'
    )
  end
  let(:sender) { unique_id }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "mailer raised expectation" do
    let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/" }

    it do
      # override deliver method
      # ref: https://github.com/mikel/mail/blob/master/lib/mail/network/delivery_methods/test_mailer.rb
      allow_any_instance_of(Mail::TestMailer).to receive(:deliver!) do |mail|
        # Create the envelope to validate it
        # Mail::SmtpEnvelope.new(mail)
        raise Net::SMTPFatalError.new("550 : Recipient address rejected: User unknown")

        Mail::TestMailer.deliveries << mail
      end

      # submit inquiry
      visit index_url
      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: sender
        end
        click_button I18n.t("inquiry.confirm")
      end
      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq sender
        end
        within 'footer.send' do
          click_button I18n.t("inquiry.submit")
        end
      end
      expect(status_code).to eq 200
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')

      # Inquiry::Answer
      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data[0].value).to eq sender

      # ActionMailer::Base.deliveries
      expect(ActionMailer::Base.deliveries.count).to eq 0

      # Sys::MailLog
      expect(Sys::MailLog.count).to eq 1
      expect(Sys::MailLog.first.error).to eq "Net::SMTPFatalError (550 : Recipient address rejected: User unknown)"
    end
  end
end
