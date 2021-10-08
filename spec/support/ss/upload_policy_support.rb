def upload_policy_before_settings(value)
  SS.config.replace_value_at(:ss, :upload_policy, value)
  Fs.mkdir_p(SS.config.ss.sanitizer_input)
  Fs.mkdir_p(SS.config.ss.sanitizer_output)
end

def upload_policy_after_settings
  SS.config.replace_value_at(:ss, :upload_policy, nil)
  Fs.rm_rf(SS.config.ss.sanitizer_input)
  Fs.rm_rf(SS.config.ss.sanitizer_output)
end

def sanitizer_mock_restore(file)
  Fs.rm_rf file.path
  output_path = "#{SS.config.ss.sanitizer_output}/#{file.id}_filename_100_marked.#{file.extname}"
  Fs.mv file.sanitizer_input_path, output_path
  file.sanitizer_restore_file(output_path)
  return output_path
end
