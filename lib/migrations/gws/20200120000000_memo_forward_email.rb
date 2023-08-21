class SS::Migration20200120000000
  include SS::Migration::Base

  depends_on "20200117000000"

  def change
    each_forward do |forward|
      if forward.emails.present?
        forward.unset(:email)
        next
      end

      emails = [ forward[:email].presence ].compact.presence
      next if emails.blank?

      forward.set(emails: emails)
      forward.unset(:email)
    end
  end

  private

  def each_forward(&block)
    criteria = Gws::Memo::Forward.all.unscoped.exists(email: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
