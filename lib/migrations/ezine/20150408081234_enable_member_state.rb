class SS::Migration20150408081234
  include SS::Migration::Base

  def change
    Ezine::Member.where(state: nil).each do |member|
      member.update state: 'enabled'
    end
  end
end
