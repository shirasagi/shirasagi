class Sys::MailLog
  extend SS::Translation
  include SS::Document

  seqid :id
  field :mailer, type: String
  field :subject, type: String
  field :to, type: String
  field :from, type: String
  field :bcc, type: String
  field :cc, type: String
  field :date, type: DateTime
  field :mail, type: String

  index({ created_at: 1 }, { expire_after_seconds: 2.weeks })

  class << self
    def add_from_event(event)
      payload = event.payload

      self.create(
        mailer: payload[:mailer],
        subject: payload[:subject],
        from: from_mail_address(payload[:from]),
        to: from_mail_address(payload[:to]),
        bcc: from_mail_address(payload[:bcc]),
        cc: from_mail_address(payload[:cc]),
        date: payload[:date],
        mail: payload[:mail]
      )
    end

    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :mailer, :subject, :from, :to, :bcc, :cc, :mail
      end

      criteria
    end

    private

      def from_mail_address(addr)
        return addr if addr.blank?
        return addr if !addr.is_a?(Array)
        addr.join(',')
      end
  end
end
