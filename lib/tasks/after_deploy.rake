# -*- encoding : utf-8 -*-
namespace :gm do
  desc "Tasks to be executed after deploying"
  task :after_deploy => :environment do
    `rake db:migrate`
    `rake assets:precompile`
    `./script/delayed_job restart`
    Skin.update_default_skin_zip
    Skin.find_by_hid("defaul").gen_compressed
    `rake gm:update_default_skin_styles`
    Cms.uncompress_ckeditor_if_necessary
    CacheObserver.expire_fragment("/common/gmversion")
    `gcc -o /tmp/embed script/embed_ttf/embed.c && /tmp/embed public/fonts/gm_icons.ttf`
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
    Term.single_toplevel(:slug => 'gmversion').link(n)
    Term.single_toplevel(:slug => 'gm').link(n)
    Term.single_toplevel(:name => 'actualizaciones.gm').link(n)
  end
end
