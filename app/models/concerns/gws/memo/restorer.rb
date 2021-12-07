module Gws::Memo::Restorer
  extend ActiveSupport::Concern

  def set_blank_val
    self.star = {}
    self.deleted = {}
    self.filtered = {}
    self.file_ids = []
    self.user_settings = []
  end

  def set_cur_user(data_user)
    user = find_user(data_user)
    if user
      self.cur_user = user
      @sent_by_cur_user = (@cur_user.id == user.id)
    else
      self.cur_user = @cur_user
    end
  end

  def set_to_members(data_to_members)
    self.to_member_ids = []
    data_to_members.each do |data_user|
      user = find_user(data_user)
      self.to_member_ids += [user.id] if user
    end
  end

  def set_cc_member_ids(data_cc_members)
    self.cc_member_ids = []
    data_cc_members.each do |data_user|
      user = find_user(data_user)
      self.cc_member_ids += [user.id] if user
    end
  end

  def set_bcc_member_ids(data_bcc_members)
    self.bcc_member_ids = []
    data_bcc_members.each do |data_user|
      user = find_user(data_user)
      self.bcc_member_ids += [user.id] if user
    end
  end

  private

  def find_user(data)
    id = data['_id']
    name = data['name']

    return nil if id.nil? || name.nil?

    user = Gws::User.unscoped.find(id) rescue nil

    return nil if user.try(:name) != name

    user
  end
end
