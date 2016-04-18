class SS::UserGroupHistory
  include SS::Document
  include SS::Reference::User

  attr_accessor :cur_site

  seqid :id
  field :cms_site_id, type: Integer
  field :gws_site_id, type: Integer
  embeds_ids :groups, class_name: 'SS::Group'
  embeds_ids :inc_groups, class_name: 'SS::Group'
  embeds_ids :dec_groups, class_name: 'SS::Group'

  validates :user_id, presence: true
  #validates :group_ids, presence: true

  before_save :set_site_id, if: -> { @cur_site.present? }

  default_scope -> {
    order_by created: -1
  }

  private
    def set_site_id
      klass = @cur_site.class.to_s
      if klass == 'Gws::Group'
        self.gws_site_id = @cur_site.id
      elsif klass == 'Cms::Site'
        self.cms_site_id = @cur_site.id
      end
    end
end
