gmt = Term.single_toplevel(:slug => 'gm')
Content.orphaned.each do |orphan|
  root = Term.single_toplevel(:slug => orphan.url[7..(orphan.url.index('.')-1)])
  root = gmt if root.nil?
  puts orphan.url[7..(orphan.url.index('.')-1)]
  if root
	  taxo = "#{ActiveSupport::Inflector.pluralize(orphan.real_content.class.name)}Category"
	  newt = root.children.find(:first, :conditions => ['taxonomy = ?', taxo])
	  if newt
	    newt.link(orphan)
	    puts "linking.."
	  else
	    puts "orphan #{orphan.name} has root #{root.id} but NO CHILD!!"
	  end
  else
	  puts "orphan #{orphan.name} has NO root"
  end
end
