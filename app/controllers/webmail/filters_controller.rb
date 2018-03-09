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
      @item = @model.new
      @item.errors.add :base, I18n.t("errors.messages.invalid_csv")
      return false
    end

    conf = @imap_setting.imap_settings(@cur_user.imap_default_settings)
    table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each do |row|
      conditions = row[@model.t(:conditions)].to_s.split("\n").collect do |value|
        JSON.parse(value, symbolize_names: true)
      end
      item = @model.find_or_initialize_by(
        host: conf[:host],
        account: conf[:account],
        conjunction: value(row, :conjunction),
        conditions: conditions,
        action: value(row, :action),
        mailbox: value(row, :mailbox),
        user_id: @cur_user.id
      )
      @model::EXPORT_ATTRIBUTES.each do |attribute|
        next if attribute == 'conditions'
        item.write_attribute(attribute, value(row, attribute))
      end
      item.save
    end

    render_update true, location: { action: :index }
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
    attributes = @model::EXPORT_ATTRIBUTES
    Enumerator.new do |y|
      y << encode(attributes.collect { |attribute| @model.t(attribute) })
      @items.each do |item|
        row = attributes.collect do |attribute|
          if attribute == 'conditions'
            item.send(attribute).collect(&:to_json).join("\n")
          else
            item.send(attribute)
          end
        end
        y << encode(row)
      end
    end
  end

  def encode(str)
    str.to_csv.encode('CP932', invalid: :replace, undef: :replace)
  end

  def value(row, key)
    row[@model.t(key)].try(:strip)
  end
end
