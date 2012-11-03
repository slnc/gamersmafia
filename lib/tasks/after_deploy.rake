# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    Rake::Task["db:migrate"].invoke
    Rake::Task["assets:precompile"].invoke
    `./script/delayed_job restart`
    compress_js
    Skin.update_default_skin_zip
    Rake::Task["gm:update_default_skin_styles"].invoke

    Cms.uncompress_ckeditor_if_necessary
    CacheObserver.expire_fragment("/common/gmversion")
    `touch #{Rails.root}/tmp/restart.txt`
    publish_news(AppR.ondisk_git_version_full, AppR.ondisk_git_version)
  end

  private
  def publish_news(version_full, version)
    title = "Gamersmafia actualizada a la versión #{version}"
    if News.published.find_by_title(title)
      Rails.logger.warn("Found news for #{version}. Skipping news creation..")
      return
    end

    last = News.published.find(
        :first,
        :conditions => "title LIKE E'Gamersmafia actualizada a la versión %'",
        :order => 'created_on DESC')
    if last.nil?
      start_rev = "HEAD~20"
    else
      start_rev = last.title.split(" ")[-1]
    end
    if /^[0-9]+$/ =~ start_rev
      start_rev = "release-#{start_rev[0..-3]}-#{start_rev[-2..-1]}"
    end

    interval = "#{start_rev}..#{AppR.ondisk_git_version_full}"
    html_log = Formatting.git_log_to_html(
        `git log --no-merges production --pretty=full #{interval}`)

    n = News.create(
        :title => title,
        :description => html_log,
        :user_id => 1,
        :state => Cms::DRAFT)
    Term.single_toplevel(:slug => 'gmversion').link(n.unique_content)
    Term.single_toplevel(:slug => 'gm').link(n.unique_content)
    Term.single_toplevel(:name => 'actualizaciones.gm').link(n.unique_content)
  end

  def compress_js
    # TODO(slnc): eliminar los archivos de syntaxhighlighter, apenas se están
    # usando.
    js_libraries = %w(
      web.shared/jquery-1.7.1
      web.shared/jquery.scrollTo-1.4.0
      jquery-ui-1.7.2.custom
      jquery_ujs
      jquery.facebox
      jquery.elastic.source
      web.shared/jgcharts-0.9
      web.shared/slnc
      app
      tracking
      app.bbeditor
      colorpicker
      syntaxhighlighter/shCore
      syntaxhighlighter/shBrushPhp
      syntaxhighlighter/shBrushPython
      jquery.autocomplete
    )

    dst = "#{Rails.root}/public/gm.js"
    f = open(dst, 'w')
    js_libraries.each do |library|
      f.write(open("#{Rails.root}/public/javascripts/#{library}.js").read)
    end
    f.close

    # Don't change line-break to any arbitrary value without checking that it
    # works across all browsers. line-break 500 makes yuicompressor cut regular
    # expressions by half and produces syntax error.
    `java -jar #{Rails.root}/script/yuicompressor-2.4.2.jar #{dst} -o #{dst} --line-break 0`
  end
end
