class Gws::Column::CopyService
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :model, :item, :overwrites, :new_item

  # rubocop:disable Lint/UnreachableLoop
  def call
    ::Tempfile.open([ "gws", ".zip" ], "#{Rails.root}/tmp") do |tempfile|
      backup_service = Gws::Column::BackupService.new(cur_site: cur_site, cur_user: cur_user, model: model)
      backup_service.criteria = model.unscoped.where(id: item.id)
      backup_service.filename = tempfile.path
      backup_service.call

      restore_service = Gws::Column::RestoreService.new(cur_site: cur_site, cur_user: cur_user)
      restore_service.filename = tempfile.path
      unless restore_service.valid?
        errors.add :base, :invalid_zip
        break
      end

      orig_form_id = nil
      restore_service.each_form do |form|
        # インスタンス編集を直接操作し new_record? が true になるように調整する
        form.instance_variable_set(:@new_record, true)
        form.instance_variable_set(:@destroyed, false)

        orig_form_id = form.id.to_s
        form.id = BSON::ObjectId.new
        form.attributes = overwrites
        result = form.save
        unless result
          SS::Model.copy_errors(form, self)
          break
        end

        @new_item = form
        break
      end

      break if errors.present?

      column_ids = {}
      radio_button_columns = []
      restore_service.each_column do |column|
        next if column.form_id.to_s != orig_form_id

        # インスタンス編集を直接操作し new_record? が true になるように調整する
        column.instance_variable_set(:@new_record, true)
        column.instance_variable_set(:@destroyed, false)

        column.id = BSON::ObjectId.new
        column_ids[column.id_was.to_s] = column.id.to_s
        column.form_id = @new_item.id
        radio_button_columns << column if column._type == "Gws::Column::RadioButton"
        result = column.save
        unless result
          SS::Model.copy_errors(form, @item)
        end
      end

      radio_button_columns.each do |column|
        column.branch_section_ids = column.branch_section_ids.map { |id| column_ids[id] }
        column.save
      end
    ensure
      if restore_service
        restore_service.close rescue nil
      end
    end

    errors.blank?
  end
  # rubocop:enable Lint/UnreachableLoop
end
