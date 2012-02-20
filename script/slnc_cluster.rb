require File.dirname(__FILE__) + '/../config/boot'
require 'clusterer'

# results = ['Hola mundo, me llamo Juan y tengo poco sexo', 'Me gusta programar en Python', 'La gente no sabe programar mucho en mi universidad', 'Este año he ido a japon y he aprendido mucho'].collect { |o| Foo.new(o) }

#class Foo
#  def initialize(str)
#    @body = str
#  end
#
#  def title
#   @body
#  end
#
#  def snippet
#    ''
#  end
#
#  def body
#   @body
#  end
#end
#
#
#def proc_for_clustering(input)
#  newstr = input.clone
#  newstr.gsub!('á', 'a')
#      newstr.gsub!('é', 'e')
#      newstr.gsub!('í', 'i')
#      newstr.gsub!('ó', 'o')
#      newstr.gsub!('ú', 'u')
#      newstr.gsub!('Á', 'A')
#      newstr.gsub!('É', 'E')
#      newstr.gsub!('Í', 'I')
#      newstr.gsub!('Ó', 'O')
#      newstr.gsub!('Ú', 'U')
#      newstr.gsub!('ñ', 'n')
#      newstr.gsub!('Ñ', 'n')
#  newstr.gsub!(/<\/?[^>]*>/, "")
#  newstr.gsub!(/(#[0-9]+)/, "")
#  newstr.gsub!(/\[\/?[^\]*]/, "")
#  newstr
#end
#
#def write_cluster_results(clusters)
#File.open("temp1b.html","w") do |f|
#  f.write("<ul>")
#  clusters.each do |clus|
#    f.write("<li>")
#    f.write("<h4>")
#    clus.centroid.to_a.sort{|a,b| b[1] <=> a[1]}.slice(0,5).each {|w| f.write("#{w[0]} - #{format '%.2f',w[1]}, ")}
#    f.write("</h4>")
#    f.write("<ul>")
#    clus.documents.each do |doc|
#      result = doc.object
#      f.write("<li>")
#      f.write("<span class='title'>")
#      f.write(result.title)
#      f.write("</span>")
#      f.write("<span class='snippet'>")
#      f.write(result.snippet)
#      f.write("</span>")
#      f.write("</li>")
#    end
#    f.write("</ul>")
#  end
#  f.write("</ul>")
#  f.write("</li>")
#end  
#end



results = User.find(1).comments.find(:all, :order => 'created_on DESC', :limit => 100).collect { |c| Foo.new(proc_for_clustering(c.comment)) }

require 'clusterer'
cat = 845.to_s
cat_ids = TopicsCategory.find(845).all_children_ids
results = Topic.find(:all, :conditions => 'topics_category_id IN (' << cat_ids.join(',') < ')', :order => 'created_on desc', :limit => 2000).collect { |c| Foo.new(proc_for_clustering(c.title), proc_for_clustering(c.main)) }  and nil
topics_ids = Topic.find(:all, :conditions => 'topics_category_id IN (' << cat_ids.join(',') < ')', :order => 'created_on DESC', :limit => 2000).collect { |c| c.id }  and nil
results2 = Comment.find(:all, :conditions => "content_id in (select id from contents where content_type_id = 6 AND external_id IN (" << topics_ids.join(',') << "))").collect { |c| Foo.new(proc_for_clustering(c.comment)) }  and nil 
resultsfull = results + results2 and nil

cat = 209.to_s
results = Tutorial.find(:all, :conditions => 'tutorials_category_id = ' << cat, :order => 'created_on desc', :limit => 100).collect { |c| Foo.new(proc_for_clustering(c.title), proc_for_clustering(c.main)) }  and nil
tutorials_ids = Tutorial.find(:all, :conditions => 'tutorials_category_id = ' << cat, :order => 'created_on desc', :limit => 100).collect { |c| c.id }  and nil
results2 = Comment.find(:all, :conditions => "content_id in (select id from contents where content_type_id = 6 AND external_id IN (" << tutorials_ids.join(',') << "))").collect { |c| Foo.new(proc_for_clustering(c.comment)) }  and nil 
resultsfull = results + results2 and nil

cat = 3379.to_s
results = News.find(:all, :conditions => 'news_category_id = ' << cat, :order => 'created_on desc', :limit => 100).collect { |c| Foo.new(proc_for_clustering(c.title), proc_for_clustering(c.main)) }  and nil
news_ids = News.find(:all, :conditions => 'news_category_id = ' << cat, :order => 'created_on desc', :limit => 100).collect { |c| c.id }  and nil
results2 = Comment.find(:all, :conditions => "content_id in (select id from contents where content_type_id = 6 AND external_id IN (" << news_ids.join(',') << "))").collect { |c| Foo.new(proc_for_clustering(c.comment)) }  and nil 
resultsfull = results # + results2 and nil

cat = 3379.to_s
results = User.find_by_login('Champion').blogentries.find(:all).collect { |c| Foo.new(proc_for_clustering(c.title), proc_for_clustering(c.main)) }  and nil
news_ids = News.find(:all, :conditions => 'news_category_id = ' << cat, :order => 'created_on desc', :limit => 100).collect { |c| c.id }  and nil
results2 = Comment.find(:all, :conditions => "content_id in (select id from contents where content_type_id = 6 AND external_id IN (" << news_ids.join(',') << "))").collect { |c| Foo.new(proc_for_clustering(c.comment)) }  and nil 
resultsfull = results # + results2 and nil

clusters = Clusterer::Clustering.cluster(:kmeans, resultsfull, :no_stem => true, :tokenizer => :simple_tokenizer, :no_of_clusters => 12) {|r|
  r.title.to_s.gsub(/<\/?[^>]*>/, "") + " " + r.snippet.to_s.gsub(/<\/?[^>]*>/, "")}  and nil
write_cluster_results(clusters)


#:no_of_clusters => 3