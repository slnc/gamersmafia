namespace :doc do
  desc "Generate documentation for the application"
  Rake::RDocTask.new("applib") { |rdoc|
    rdoc.rdoc_dir = 'doc/applib'
    rdoc.title    = "Documentaci&oacute;n GM Engine"
    rdoc.options << '--all' << '--line-numbers' << '--inline-source' << '-c utf8'
    rdoc.rdoc_files.include('doc/README_FOR_APP')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('vendor/plugins/*/lib/**/*.rb')
  }
end

namespace :doc do
  desc "Fix Rdoc style"
  task :fixstyle do
    files = FileList['doc/fix_doc_files/*']
    files.each do |file|
      FileUtils.cp(file, 'doc/applib')
    end
  end
end
