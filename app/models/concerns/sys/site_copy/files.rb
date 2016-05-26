module Sys::SiteCopy::Files
  extend ActiveSupport::Concern

  private
    #共有ファイル:OK
    # 元サイトから共有ファイルを全て複製サイトへ複製
    ###
    # 元サイトから複製サイトへ、共有ファイルを複製する。
    ###
    def create_dupfiles_for_dupsite
      if !@site_old.kind_of?(Cms::Site) || !@site.kind_of?(Cms::Site)
        logger.fatal 'Expected the 2 arguments. - [0] => Cms::Site, [1] => Cms::Site'
        return false
      end
      # 元サイトに紐付く共有ファイルを取得.
      # JSON ライクに取り扱いたいので配列化.
      old_file_model_list = Cms::File.where(:site_id => @site_old._id).order('updated ASC').to_a

      old_file_model_list.each do |base_file_model_obj|
        # ファイルModelを生成
        new_file_model_obj = copy_cmsfile_for_dupcms(base_file_model_obj)
        # 元ファイルModelに VirtualAttribute が含まれる場合, それも複製Modelへ追加
        base_file_model_obj.attributes.keys.each do |base_obj_field|
          next if %w(id _id created updated).include? base_obj_field # 余計なものは飛ばす
          if !Cms::File.fields.keys.include? base_obj_field
            new_file_model_obj[base_obj_field] = base_file_model_obj[base_obj_field]
          end
        end
        # 複製した添付ファイルの実体とModelを保存
        if !new_file_model_obj.save_files
            # 保存に失敗
            logger.fatal new_file_model_obj.errors.full_messages
        end
      end # end / old_file_model_list.each
    end

    ###
    # 複製元サイトのファイルModelを複製し、複製サイトへ紐付けた状態で生成する
    # @param  {Cms::File} base_file_model_obj
    # @return {Cms::File}
    ###
    def copy_cmsfile_for_dupcms(base_file_model_obj)
      psude_params = {
        :in_files         => [gen_dup_tmpfile(base_file_model_obj)],
        :permission_level => base_file_model_obj.permission_level,
        :group_ids        => base_file_model_obj.group_ids,
        :user_id          => base_file_model_obj.user_id,
        :cur_site         => @site
      }
      Cms::File.new psude_params
    end

    ###
    # 元ファイルから新規テンポラリファイルを作成
    # @param  {Cms::File} base_file_model_obj
    # @return {ActionDispatch::Http::UploadedFile}
    ###
    def gen_dup_tmpfile(base_file_model_obj)
        base_file_data = File.open(base_file_model_obj.path, 'r+b')
        tmp_file_obj   = Tempfile.new(base_file_model_obj.filename)
        IO.copy_stream(base_file_data, tmp_file_obj)
        base_file_hash = {
          :tempfile => tmp_file_obj,
          :filename => base_file_model_obj.filename,
          :type     => base_file_model_obj.content_type,
          :head     => "Content-Disposition: form-data;
           name=\"item[in_files][]\";
           filename=\"#{base_file_model_obj.filename}\"\r\n
           Content-Type: #{base_file_model_obj.content_type}\r\n"
        }
        ActionDispatch::Http::UploadedFile.new(base_file_hash)
    end
end
