#!/usr/bin/env ruby
# Script that sends changelog emails and creates new release tags whenever the
# production repository is updated.
require 'net/smtp'

# You must pass opts[:body] and opts[:subject]
def send_email(to,opts={})
  opts[:server]      ||= 'localhost'
  opts[:from]        ||= 'nagato@gamersmafia.com'
  opts[:from_alias]  ||= 'nagato'

  raise "Missing subject" unless opts[:subject]
  raise "Missing body" unless opts[:body]

  msg = <<END_OF_MESSAGE
Content-Type: text/plain; charset=UTF-8
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE

  Net::SMTP.start(opts[:server]) do |smtp|
    smtp.send_message msg, opts[:from], to
  end
end

def tag_and_notify
  git_st = `git status`
  if git_st.include?("# Changed but not updated:")
    puts "Working directory is dirty, cannot create release."
  end

  all_tags = `git tag | grep release`.strip.split("\n")
  do_email = true
  if all_tags.size == 0
    puts "No previous tags found, no email will be sent."
    do_email = false
  end

  last_tag = all_tags.sort.last
  git_interval = "#{last_tag}..HEAD"
  short_log = `git log production --pretty=format:"- %s" #{git_interval}`
  commits_count = short_log.split("\n").size
  if commits_count == 0
    puts "No new commits since last release #{last_tag}. Nothing to report."
    return
  end

  tag_prefix = "release-#{Time.now.strftime("%Y%m%d")}"
  daily_id = all_tags.count {|item| item.include?(tag_prefix)}
  padded_id = "%02d" % (daily_id + 1)
  new_tag = "#{tag_prefix}-#{padded_id}"

  detailed_log = `git log production --pretty=format:"[%s]\n%an - %H - %ar\n\n%b\n" #{git_interval}`
  if do_email
    body = "#{short_log}\n\n\nDETALLES\n#{detailed_log}"
    changes = "cambio#{commits_count  > 1 ? "s" : ""}"
    send_email(
        "gm-hackers@googlegroups.com",
        :subject => "GM actualizada a #{new_tag}: #{commits_count} #{changes}",
        :body => body)
  end
  `git tag -a -m #{new_tag} #{new_tag}`
end

tag_and_notify
