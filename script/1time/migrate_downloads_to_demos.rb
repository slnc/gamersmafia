puts "DESACTIVAR file_column :file de DEMO"

#:all, :conditions => "id IN (select id from downloads_categories a where lower(name) like  '%demos%' and downloads_count > 0)").each do |dc|

next if [1366, 1289].include?(dc.id)

dc = DownloadsCategory.find(1314)
dc.get_all_children.each do |dcc_id|
  DownloadsCategory.find(dcc_id).find(:all).each { |download| download.mute_to_demo }
end
