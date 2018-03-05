class Webmail::FiltersController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Filter

  before_action :imap_login, except: [:index]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/filter"), { action: :index } ]
    @webmail_other_account_path = :webmail_filters_path
  end

  def fix_params
    @imap.account_scope.merge(cur_user: @cur_user, imap: @imap)
  end

  public

  def index
    @items = @model.
      user(@cur_user).
      imap_setting(@cur_user, @imap_setting).
      search(params[:s]).
      page(params[:page]).
      per(50)
  end

  def download
    s_params = params[:s] || {}

    @items = @model.user(@cur_user).
      imap_setting(@cur_user, @imap_setting).
      search(s_params)

    send_enum enum_csv, type: 'text/csv; charset=Shift_JIS', filename: "personal_filters_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?

    file = params[:item].try(:[], :in_file)
    if file.nil? || ::File.extname(file.original_filename) != ".csv"
      raise I18n.t("errors.messages.invalid_csv")
    end

    table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each do |row|
      conditions = row[@model.t(:conditions)].to_s.split("\n").collect do |value|
        JSON.parse(value, symbolize_names: true)
      end
      item = @model.find_or_initialize_by(conditions: conditions)
      @model.fields.each_key do |key|
        next if key == '_id'
        next if key == 'conditions'
        item.write_attribute(key, row[@model.t(key)].try(:strip))
      end
    end

    render_update true, location: { action: :index }, render: { file: :import }
  end

  def apply
    set_item

    mailbox = params[:mailbox].presence
    return render(file: :show) if mailbox.blank?

    @imap.examine(mailbox)
    uids = @item.uids_search([])
    count = @item.uids_apply(uids)
    return render(file: :show) if count == false

    @imap.mailboxes.update_status

    respond_to do |format|
      format.html { redirect_to({ action: :show }, notice: t('webmail.notice.multiple.filtered', count: count)) }
      format.json { head :no_content }
    end
  end

  private

  def enum_csv
    fields = @model.fields.sort
    Enumerator.new do |y|
      y << encode(fields.collect { |name, field| @model.t(name) })
      @items.each do |item|
        row = fields.collect do |name, field|
          if name == 'conditions'
            item.send(name).collect(&:to_json).join("\n")
          else
            item.send(name)
          end
        end
        y << encode(row)
      end
    end
  end

  def encode(str)
    str.to_csv.encode('CP932', invalid: :replace, undef: :replace)
  end
end
