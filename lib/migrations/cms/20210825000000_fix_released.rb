class SS::Migration20210825000000
  include SS::Migration::Base

  depends_on "20210628000000"

  def change
    Cms::Page.all.where(route: /rss\//).set(released_type: "fixed")

    each_page do |page|
      case page.released_type
      when "same_as_updated"
        released = page.updated
      when "same_as_created"
        released = page.created
      when "same_as_first_released"
        released = page.first_released
      else # nil or "fixed"
        released = nil
      end
      next if released.blank?

      page.set(released: released.utc)
    end
  end

  private

  def each_page(&block)
    all_ids = Cms::Page.all.exists(released_type: true).ne(released_type: "fixed").pluck(:id)
    all_ids.each_slice(100) do |ids|
      Cms::Page.all.in(id: ids).to_a.each(&block)
    end
  end
end
