# This script outputs one GitHub issue per line with the following format:
# :title :issue_id :first_label
#
# USAGE
# Download a .json file with all the issues with:
#  curl -u ":user" https://api.github.com/repos/gamersmafia/gamersmafia/issues?per_page=1000 > gm_issues.json
#
# Replace :user with your GitHub username. You will be asked for your password.
#
# Run this script over the file.
require 'rubygems'
require 'json'

result = JSON.parse(open("gm_issues.json").read)
result.each do |issue|
  line = "#{csv_line} #{issue["title"]} ##{issue["number"]}"
  if issue["labels"].size > 0
    line = "#{line} (#{issue["labels"][0]["name"]})"
  end
  puts line
end
