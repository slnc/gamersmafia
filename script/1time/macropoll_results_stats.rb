results = {}
polls = User.db_query("SELECT * FROM macropolls ORDER BY created_on DESC")
puts "Total de encuestas: #{polls.size}"
polls.each do |dbr|
  begin
    anzwers = YAML::load(dbr['answers'])
  rescue ArgumentError
    puts "IGNORADO #{dbr['created_on']} #{dbr['user_id']}"
    raise ArgumentError
  else
    anzwers.each do |k,v|
      results[k] ||= {}
      results[k][v] ||= 0
      results[k][v] += 1
    end
  end
end

results.each do |k,v|
  puts k
  v.each do |k2,v2|
    puts "    #{k2}: #{v2}"
  end
end
