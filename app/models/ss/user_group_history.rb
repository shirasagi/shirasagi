class SS::UserGroupHistory
  include SS::Document
  include SS::Reference::User

  attr_accessor :cur_site

  seqid :id
  field :cms_site_id, type: Integer
  field :gws_site_id, type: Integer
  field :group_names, type: Array
  field :inc_group_names, type: Array
  field :dec_group_names, type: Array
  field :groups_hash, type: Hash
  field :inc_groups_hash, type: Hash
  field :dec_groups_hash, type: Hash

  embeds_ids :groups, class_name: 'SS::Group'
  embeds_ids :inc_groups, class_name: 'SS::Group'
  embeds_ids :dec_groups, class_name: 'SS::Group'

  validates :user_id, presence: true
  #validates :group_ids, presence: true

  before_save :set_site_id, if: -> { @cur_site.present? }
  before_save :set_group_names

  default_scope -> {
    order_by created: -1
  }

  def group_names
    self[:group_names] || groups.map(&:name)
  end

  private
    def set_site_id
      klass = @cur_site.class.to_s
      if klass == 'Gws::Group'
        self.gws_site_id = @cur_site.id
      elsif klass == 'Cms::Site'
        self.cms_site_id = @cur_site.id
      end
    end

    def set_group_names
      self.group_names     = groups.map(&:name)
      self.inc_group_names = inc_groups.map(&:name)
      self.dec_group_names = dec_groups.map(&:name)
      self.groups_hash     = groups.map { |m| [m.id, m.name] }.to_h
      self.inc_groups_hash = inc_groups.map { |m| [m.id, m.name] }.to_h
      self.dec_groups_hash = dec_groups.map { |m| [m.id, m.name] }.to_h
    end
end
