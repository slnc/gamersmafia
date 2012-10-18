# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    Rake::Task["db:migrate"].invoke
    Rake::Task["assets:precompile"].invoke
    compress_js
    Skin.update_default_skin_zip
    Rake::Task["gm:update_default_skin_styles"].invoke

    Cms.uncompress_ckeditor_if_necessary
    CacheObserver.expire_fragment("/common/gmversion")
    `touch #{Rails.root}/tmp/restart.txt`
    publish_news(AppR.ondisk_git_version)
  end

  private
  def publish_news(version)
    html_log = Cms.plain_text_to_html(
        open("#{Rails.root}/public/storage/gitlog").read)
    title = "Gamersmafia actualizada a la versión #{version}"
    if News.find_by_title(title)
      Rails.logger.warn("Found news for #{version}. Skipping news creation..")
      return
    end
    n = News.create(
        :title => title,
        :description => html_log,
        :user_id => 1,
        :state => Cms::DRAFT)
    Term.single_toplevel(:slug => 'gmversion').link(n.unique_content)
    Term.single_toplevel(:slug => 'gm').link(n.unique_content)
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
