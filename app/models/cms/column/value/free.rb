class Cms::Column::Value::Free < Cms::Column::Value::Base
  field :value, type: String
  field :contains_urls, type: Array, default: []

  embeds_ids :files, class_name: "SS::File"

  permit_values :value, file_ids: []

  before_validation :set_contains_urls
  before_save { @add_file_ids ||= file_ids - file_ids_was.to_a }
  after_save :put_contains_urls_logs
  before_parent_save :before_save_files
  after_parent_destroy :destroy_files

  liquidize do
    export :value
    export :files
  end

  def all_file_ids
    file_ids
  end

  def generate_public_files
    SS::File.each_file(file_ids) do |file|
      file.generate_public_file
    end
  end

  def remove_public_files
    SS::File.each_file(file_ids) do |file|
      file.remove_public_file
    end
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    values.find { |v| value.to_s.index(v) }.present?
  end

  private

  def validate_value
    return if column.blank? || _parent.skip_required?

    if column.required? && value.blank?
      self.errors.add(:value, :blank)
    end

    return if value.blank?

    if column.max_length.present? && column.max_length > 0
      if value.length > column.max_length
        self.errors.add(:value, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    value
  end

  def before_save_files
    # Cms::Addon::File では clone_files をしてから save_files を実行しているので、それに習う。
    #
    # 注意: カラム処理では以下の点が異なるので注意。
    #
    # カラムは数が変更される可能性があるため、master から branch を作成する際も、master へ branch をマージする際も、
    # delete & insert となるため常に @new_clone がセットされる。
    # master から branch を作成する際は @merge_values はセットされないのに対し、
    # master へ branch をマージする際は @merge_values がセットされる。
    clone_files if @new_clone && !@merge_values
    @add_file_ids ||= file_ids - file_ids_was.to_a
    save_files
  end

  def clone_files
    return if file_ids.blank?

    owner_item = SS::Model.container_of(self)
    return if owner_item.respond_to?(:branch?) && owner_item.branch?

    cur_user = owner_item.cur_user if owner_item.respond_to?(:cur_user)
    cloned_file_ids = []
    SS::File.each_file(file_ids) do |source_file|
      clone_file = SS::File.clone_file(source_file, cur_user: cur_user, owner_item: owner_item) do |new_file|
        # history_files
        if @merge_values
          new_file.history_file_ids = source_file.history_file_ids
        end
      end
      next unless clone_file

      cloned_file_ids << clone_file.id

      cloned_value = self.value.to_s
      cloned_value.gsub!("=\"#{source_file.url}\"", "=\"#{clone_file.url}\"")
      cloned_value.gsub!("=\"#{source_file.thumb_url}\"", "=\"#{clone_file.thumb_url}\"")
      self.value = cloned_value
    end

    self.file_ids = cloned_file_ids
  end

  def save_files
    # 追加されたファイルのリストを算出するには before_save でないといけない。
    # しかし、before_save コールバックが呼ばれた時点では _parent.id が未確定のため files の owner_item をセットできない。
    # 苦肉の策だが before_save コールバックで追加されたファイルのリストを算出し、@add_file_ids に保存する。
    # そして、before_parent_save コールバックで files の owner_item をセットする。
    owner_item = SS::Model.container_of(self)
    in_branch = owner_item.in_branch if @merge_values && owner_item.respond_to?(:in_branch)

    on_clone_file = method(:update_value_with_clone_file)
    ids = Cms::Reference::Files::Utils.attach_files(self, @add_file_ids, branch: in_branch, on_clone_file: on_clone_file)
    self.file_ids = ids rescue return

    del_ids = file_ids_was.to_a - ids
    Cms::Reference::Files::Utils.delete_files(self, del_ids)
  end

  def update_value_with_clone_file(old_file, new_file)
    return if value.blank?

    value = self.value
    value.gsub!("=\"#{old_file.url}\"", "=\"#{new_file.url}\"")
    value.gsub!("=\"#{old_file.thumb_url}\"", "=\"#{new_file.thumb_url}\"")
    self.value = value
  end

  def destroy_files
    Cms::Reference::Files::Utils.delete_files(self, file_ids)
  end

  def build_history_log(file)
    owner_item = SS::Model.container_of(self)
    site_id = owner_item.cur_site.id if owner_item.respond_to?(:cur_site) && owner_item.cur_site
    user_id = owner_item.cur_user.id if owner_item.respond_to?(:cur_user) && owner_item.cur_user

    History::Log.build_file_log(file, site_id: site_id, user_id: user_id)
  end

  def put_contains_urls_logs
    owner_item = SS::Model.container_of(self)
    add_contains_urls = owner_item.value_contains_urls - owner_item.value_contains_urls_previously_was.to_a
    add_contains_urls.each do |file_url|
      item = build_history_log(nil)
      item.url = file_url
      item.action = "update"
      item.behavior = "paste"
      item.ref_coll = "ss_files"
      item.save
    end

    del_contains_urls = owner_item.value_contains_urls_previously_was.to_a - owner_item.value_contains_urls
    del_contains_urls.each do |file_url|
      item = build_history_log(nil)
      item.url = file_url
      item.action = "destroy"
      item.behavior = "paste"
      item.ref_coll = "ss_files"
      item.save
    end
  end

  def set_contains_urls
    if value.blank?
      self.contains_urls.clear if self.contains_urls.present?
    else
      begin
        self.contains_urls = value.scan(/(?:href|src)="(.*?)"/).flatten.uniq.compact.collect(&:strip)
      rescue
        self.contains_urls
      end
    end
    self._parent.value_contains_urls = self.contains_urls
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.value %})
      h << %(  {% value.value %})
      h << %(  {% if value.files %})
      h << %(    {{ value.files }})
      h << %(  {% endif %})
      h << %({% endif %})
      h.join("\n")
    end
  end
end
