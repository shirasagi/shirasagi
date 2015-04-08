class SS::Migration20150408081234
  def change
    Ezine::Member.where(state: nil).each do |member|
      member.update state: 'enabled'
    end
  end
end
