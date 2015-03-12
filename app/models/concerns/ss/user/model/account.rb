class SS::User::Model::Account
  include Mongoid::Document
  include SS::Fields::Sequencer
  include Comparable

  sequence_field :id
  replace_field "_id", Integer
  field :uid, type: String
  field :group_id, type: Integer

  validates :uid, presence: true, uniqueness: { scope: :group_id }, length: { maximum: 40 }
  validate :validate_uid, if: ->{ uid.present? }
  validates :group_id, presence: true
  validate :validate_group_id, if: ->{ group_id.present? }

  public
    def group
      SS::Group.find(group_id)
    end

    def <=>(other)
      ret = uid <=> other.uid
      ret = group_id <=> other.group_id if ret == 0
      ret
    end

  private
    def validate_uid
      errors.add :uid, :invalid if self.uid.include?("@")
    end

    def validate_group_id
      errors.add :group_id, :invalid if SS::Group.where(id: group_id).first.nil?
      errors.add :group_id, :invalid unless group.try(:root?)
    end
end
