#set old flag
class SS::Migration20181024000000
  def change
    Gws::Memo::Notice.each do |notice|
      notice.set(old: true)
    end
  end
end
