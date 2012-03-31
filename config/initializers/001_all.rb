if App.enable_tidy? && !File.exists?(App.tidy_path)
  App.enable_tidy = false
  Rails.logger.warn("Tidy enabled but libtidy.so (#{App.tidy_path}) not found.")
end
