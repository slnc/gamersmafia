i = 0
failures = 0
prev_pc = 0
total = Content.count.to_f
Content.find(:all).each do |c|
  begin
    created_on = c.real_content.created_on
  rescue ActiveRecord::RecordNotFound:
    failures += 1
  else
    User.db_query("UPDATE contents SET created_on = '#{created_on}' WHERE id = #{c.id}")
    # c.save
    i += 1
    cur_pc = ((i / total) * 100).to_i
    if cur_pc != prev_pc
      prev_pc  = cur_pc
      puts "#{prev_pc}% (#{i} de #{total})"
    end
  end
end

puts "total: #{i} |  failures: #{failures} | success: #{i}"
