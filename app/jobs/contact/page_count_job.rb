class Contact::PageCountJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "contact/page_count"

  class << self
    def page_count_path(task)
      "#{task.base_dir}/page_count.json"
    end
  end

  def perform
    f = Tempfile.create
    f.puts "# 連絡先使用数"
    each_item do |group_id, contact_id, count|
      hash = { group_id: group_id, contact_id: contact_id.to_s, count: count }
      f.puts(hash.to_json)
    end
    f.close

    path = self.class.page_count_path(task)
    dirname = ::File.dirname(path)
    ::FileUtils.mkdir_p(dirname)
    ::FileUtils.move(f.path, path)

    f = nil
  ensure
    if f
      f.close rescue nil
      f.unlink rescue nil
    end
  end

  private

  def build_stages
    [
      {
        "$group" => {
          _id: { contact_group_id: "$contact_group_id", contact_group_contact_id: "$contact_group_contact_id" },
          count: { "$sum" => 1 }
        }
      }
    ]
  end

  def each_item
    stages = build_stages
    result = Cms::Page.collection.aggregate(stages)

    result.each do |doc|
      contact_group_id = doc["_id"]["contact_group_id"]
      contact_group_contact_id = doc["_id"]["contact_group_contact_id"]
      count = doc["count"]

      yield contact_group_id, contact_group_contact_id, count
    end
  end
end
