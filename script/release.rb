#!/usr/bin/env ruby
# Script that sends changelog emails and creates new release tags whenever the
# master branch is updated.

require 'iconv'
require 'net/smtp'

# You must pass opts[:body] and opts[:subject]
def send_email(to,opts={})
  opts[:server]      ||= 'localhost'
  opts[:from]        ||= 'webmaster@gamersmafia.com'
  opts[:from_alias]  ||= 'webmaster'

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
  `git fetch --tags git://github.com/gamersmafia/gamersmafia.git`
  git_st = `git status`
  if git_st.include?("# Changed but not updated:")
    puts "Working directory is dirty, cannot create release."
    return
  end

  all_tags = `git tag | grep release`.strip.split("\n")
  do_email = true
  if all_tags.size < 2
    puts "Not enough tags to do diff. No email will be sent."
    do_email = false
  end

  diff_start_tag, diff_end_tag = all_tags.sort[-2..-1]
  git_interval = "#{diff_start_tag}..#{diff_end_tag}"

  short_log = `git log master --no-merges --pretty=format:"- %s" #{git_interval}`
  ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
  # We need to do this because some commit messages appear to have invalid utf8
  # characters.
  # This specific hack comes from:
  #   http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
  short_log = ic.iconv(short_log + ' ')[0..-2]
  if short_log.strip == ''
    puts "No new commits since last release #{git_interval}. Nothing to report."
    return
  end
  commits_count = short_log.count("\n") + 1

  detailed_log = `git log --no-merges master --pretty=format:"%s%+h - %an - %cr%w(72, 3, 3)%n%+b" #{git_interval}`
  detailed_log = ic.iconv(detailed_log + ' ')[0..-2]
  if do_email
    body = "#{detailed_log}"
    changes = "cambio#{commits_count  > 1 ? "s" : ""}"
    send_email(
        "gm-hackers@googlegroups.com",
        :subject => "GM actualizada a #{diff_end_tag}: #{commits_count} #{changes}",
        :body => body)
  end
end

tag_and_notify
