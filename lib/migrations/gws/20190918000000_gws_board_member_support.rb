class SS::Migration20190918000000
  include SS::Migration::Base

  depends_on "20190913000000"

  def change
    each_item do |item|
      if item.invalid?
        puts ""
        puts "#{item.name}(#{item.id}): unable to migrate this board due to some errors"
        puts item.errors.full_messages.join("\n")
        next
      end

      case item.readable_setting_range
      when 'public'
        item.member_group_ids = Gws::Group.all.site(item.site).active.pluck(:id)
      when 'select'
        item.member_ids = item.readable_member_ids
        item.member_group_ids = item.readable_group_ids
        item.member_custom_group_ids = item.readable_custom_group_ids
      else
        # private
        next
      end

      item.save
    end

    each_role do |role|
      role.permissions = role.permissions.map { |permission| permission.sub("_gws_board_posts", "_gws_board_topics") }
      role.save
    end
  end

  private

  def each_item
    all_ids = Gws::Board::Topic.topic.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Gws::Board::Topic.topic.in(id: ids).to_a.each do |item|
        item.cur_site = item.site
        yield item
      end
    end
  end

  def each_role
    all_ids = Gws::Role.all.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Gws::Role.all.in(id: ids).to_a.each do |item|
        item.cur_site = item.site
        yield item
      end
    end
  end
end
