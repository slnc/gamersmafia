ActionController::Base.perform_caching             = false

class PhpbbImporter < ActiveRecord::Base
  
end


r_users = {720=>28650, 589=>34296, 65=>33830, 196=>33939, 327=>34060, 786=>34484, 655=>34360, 524=>34239, 131=>33881, 262=>33999, 393=>34122, 721=>34420, 590=>34297, 459=>34185, 66=>33831, 197=>33940, 328=>34061, 787=>34485, 656=>34361, 132=>33882, 263=>34000, 394=>34123, 722=>34421, 591=>34298, 460=>34186, 198=>33941, 329=>34062, 67=>33832, 788=>34486, 657=>34362, 526=>34240, 133=>33883, 264=>34001, 395=>34124, 2=>12528, 723=>34422, 592=>34299, 461=>34187, 199=>33942, 330=>34063, 68=>33833, 789=>34487, 658=>34363, 527=>34241, 265=>34002, 396=>34125, 3=>33779, 134=>33884, 724=>34423, 593=>34300, 462=>34188, 200=>33943, 331=>34064, 69=>33834, 790=>34488, 659=>34364, 528=>34242, 266=>34003, 397=>34126, 4=>33780, 135=>12771, 725=>34424, 594=>34301, 463=>34189, 332=>22502, 70=>33835, 201=>33944, 791=>34489, 660=>34365, 529=>34243, 267=>34004, 398=>34127, 5=>33781, 136=>33885, 726=>34425, 595=>34302, 464=>34190, 333=>18873, 71=>33836, 202=>33945, 792=>34490, 661=>34366, 530=>34244, 399=>34128, 6=>33782, 137=>33886, 268=>34005, 727=>34426, 596=>34303, 465=>34191, 334=>34065, 72=>33837, 203=>33946, 793=>34491, 662=>34367, 531=>34245, 400=>34129, 7=>33077, 138=>33887, 269=>34006, 728=>34427, 597=>34304, 466=>34192, 73=>33838, 204=>33947, 335=>34066, 794=>34492, 663=>34368, 532=>34246, 401=>34130, 8=>33783, 139=>33888, 270=>34007, 729=>34428, 598=>34305, 467=>34193, 74=>25105, 205=>33948, 336=>34067, 795=>34493, 664=>31646, 533=>34247, 9=>33784, 140=>33889, 271=>34008, 402=>34131, 730=>34429, 599=>34306, 468=>34194, 75=>33839, 206=>33949, 337=>34068, 665=>34369, 534=>34248, 10=>33785, 141=>33890, 272=>34009, 403=>16275, 731=>34430, 600=>34307, 469=>34195, 76=>33840, 207=>33950, 338=>34069, 666=>34370, 535=>34249, 11=>33786, 142=>33891, 273=>34010, 404=>34132, 732=>34431, 601=>34308, 470=>34196, 77=>33841, 208=>33951, 339=>34070, 667=>34371, 536=>34250, 12=>33787, 274=>34011, 405=>34133, 733=>34432, 602=>34309, 471=>34197, 78=>33842, 209=>33952, 340=>34071, 668=>14255, 406=>34134, 13=>33788, 144=>33892, 275=>34012, 734=>34433, 603=>34310, 79=>33843, 210=>33953, 341=>34072, 669=>34372, 407=>34135, 14=>33789, 145=>33893, 276=>34013, 735=>34434, 604=>34311, 473=>34198, 80=>15072, 211=>18815, 342=>34073, 670=>34373, 408=>34136, 15=>9447, 146=>19941, 277=>34014, 736=>34435, 605=>34312, 474=>34199, 81=>12447, 212=>33954, 343=>34074, 671=>34374, 540=>34251, 409=>34137, 16=>33790, 147=>33894, 278=>11245, 737=>34436, 606=>34313, 475=>34200, 82=>33844, 213=>33955, 344=>12569, 672=>34375, 541=>34252, 410=>34138, 17=>33791, 148=>33895, 279=>34015, 738=>34437, 607=>34314, 83=>9537, 214=>33956, 345=>34075, 673=>34376, 542=>34253, 411=>34139, 18=>33792, 149=>33896, 280=>1246, 739=>34438, 608=>34315, 477=>34201, 84=>33845, 215=>25422, 346=>34076, 674=>34377, 543=>34254, 412=>34140, 19=>33793, 150=>33897, 281=>34016, 740=>34439, 609=>34316, 478=>34202, 85=>33846, 216=>33957, 347=>34077, 675=>12088, 544=>34255, 413=>34141, 20=>17979, 151=>33898, 282=>34017, 741=>34440, 610=>34317, 479=>34203, 86=>20155, 217=>33958, 348=>34078, 676=>34378, 545=>34256, 414=>34142, 21=>33794, 152=>33899, 283=>34018, 742=>34441, 611=>34318, 480=>34204, 87=>33847, 218=>33959, 349=>34079, 677=>34379, 546=>34257, 415=>34143, 22=>33795, 153=>33900, 284=>34019, 743=>34442, 612=>34319, 88=>33848, 219=>9184, 350=>34080, 678=>34380, 547=>34258, 416=>34144, 23=>12541, 154=>33901, 285=>34020, 744=>34443, 613=>34320, 89=>33849, 220=>33960, 351=>34081, 679=>34381, 548=>34259, 417=>34145, 24=>33796, 155=>21446, 286=>34021, 745=>34444, 614=>34321, 483=>34205, 90=>33850, 221=>33961, 352=>34082, 680=>34382, 549=>34260, 418=>34146, 25=>9886, 156=>33902, 287=>34022, 746=>34445, 615=>34322, 484=>34206, 91=>18498, 222=>33962, 353=>30564, 681=>23248, 550=>34261, 419=>34147, 26=>21089, 157=>33903, 288=>34023, 747=>34446, 616=>34323, 92=>12692, 223=>33963, 354=>34083, 682=>34383, 551=>34262, 420=>34148, 27=>18100, 158=>33904, 289=>34024, 748=>34447, 617=>34324, 486=>34207, 93=>33851, 224=>33964, 355=>34084, 683=>34384, 552=>10494, 421=>34149, 28=>33797, 159=>33905, 290=>34025, 749=>34448, 618=>34325, 487=>34208, 94=>33852, 225=>33965, 356=>34085, 684=>34385, 553=>34263, 422=>34150, 29=>33798, 160=>33906, 291=>34026, 750=>27978, 619=>34326, 488=>34209, 95=>18308, 226=>33966, 357=>34086, 685=>34386, 554=>34264, 423=>34151, 30=>33799, 161=>33907, 292=>34027, 751=>34449, 620=>34327, 489=>34210, 96=>33853, 227=>33967, 358=>34087, 686=>34387, 555=>34265, 424=>34152, 31=>33800, 162=>33908, 293=>34028, 752=>34450, 621=>34328, 97=>33854, 228=>33968, 359=>34088, 687=>34388, 556=>34266, 425=>34153, 32=>33801, 163=>33909, 294=>34029, 753=>34451, 622=>34329, 491=>34211, 98=>14202, 229=>33969, 360=>34089, 688=>34389, 557=>34267, 426=>34154, 164=>33910, 295=>34030, 33=>33802, 754=>34452, 623=>34330, 99=>33855, 230=>33970, 361=>34090, 689=>34390, 558=>34268, 427=>34155, 165=>33911, 296=>34031, 34=>33803, 755=>34453, 624=>34331, 231=>33971, 362=>34091, 100=>33856, 690=>34391, 559=>34269, 428=>34156, 166=>16584, 297=>34032, 35=>33804, 756=>34454, 625=>34332, 494=>34212, 232=>33972, 363=>34092, 101=>33857, 691=>34392, 560=>34270, 429=>34157, 298=>34033, 36=>18505, 167=>33912, 757=>34455, 626=>34333, 495=>34213, 233=>33973, 364=>34093, 102=>33858, 692=>34393, 561=>34271, 430=>34158, 299=>16116, 37=>33805, 168=>33913, 758=>34456, 627=>34334, 496=>34214, 365=>34094, 103=>12835, 234=>33974, 693=>32772, 562=>34272, 431=>34159, 300=>34034, 38=>33806, 169=>33914, 759=>34457, 628=>34335, 497=>34215, 366=>34095, 104=>33859, 235=>33975, 694=>34394, 563=>34273, 432=>34160, 39=>33807, 170=>33915, 301=>34035, 760=>34458, 629=>34336, 498=>34216, 367=>34096, 105=>33860, 236=>33976, 695=>34395, 564=>34274, 433=>34161, 40=>33808, 171=>33916, 302=>34036, 761=>34459, 630=>34337, 499=>34217, 106=>33861, 237=>28859, 368=>34097, 696=>34396, 565=>34275, 434=>34162, 41=>33809, 172=>33917, 303=>34037, 762=>34460, 631=>2022, 500=>34218, 107=>33862, 238=>33977, 369=>34098, 697=>34397, 566=>34276, 435=>34163, 42=>33810, 173=>22254, 304=>34038, 763=>34461, 632=>34338, 501=>34219, 108=>33863, 239=>33978, 370=>34099, 698=>34398, 567=>34277, 436=>34164, 43=>12459, 174=>33918, 305=>34039, 764=>34462, 633=>34339, 109=>33864, 240=>33979, 371=>34100, 699=>34399, 568=>34278, 437=>34165, 44=>33811, 175=>33919, 306=>34040, 765=>34463, 634=>34340, 503=>34220, 110=>33865, 241=>33980, 372=>34101, 700=>34400, 569=>34279, 438=>34166, 45=>33812, 176=>33920, 307=>34041, 766=>34464, 635=>34341, 504=>34221, 111=>33866, 242=>33981, 373=>34102, 701=>34401, 570=>34280, 439=>34167, 46=>33813, 177=>33921, 308=>34042, 767=>34465, 636=>34342, 505=>34222, 112=>33867, 243=>33982, 374=>34103, 702=>34402, 571=>34281, 440=>34168, 47=>33814, 178=>33922, 309=>34043, 768=>34466, 637=>34343, 506=>34223, 113=>33868, 244=>33983, 375=>34104, 703=>34403, 572=>34282, 441=>34169, 48=>33815, 179=>33923, 310=>34044, 769=>34467, 638=>34344, 507=>34224, 114=>33869, 245=>33984, 376=>34105, 704=>34404, 573=>34283, 442=>34170, 49=>33816, 180=>33924, 311=>34045, 770=>34468, 639=>34345, 508=>34225, 115=>33870, 246=>19556, 377=>34106, 705=>34405, 574=>8630, 443=>34171, 50=>33817, 181=>33925, 312=>29505, 771=>34469, 640=>34346, 116=>33871, 247=>33985, 378=>34107, 706=>34406, 575=>34284, 444=>34172, 51=>33818, 182=>33926, 313=>34046, 772=>34470, 641=>34347, 510=>34226, 117=>33872, 248=>33986, 379=>34108, 707=>34407, 576=>34285, 445=>34173, 52=>33819, 183=>33927, 314=>34047, 773=>34471, 642=>34348, 511=>34227, 118=>33873, 249=>33987, 380=>34109, 708=>34408, 446=>34174, 53=>33820, 184=>33928, 315=>34048, 774=>34472, 643=>34349, 512=>34228, 119=>18926, 250=>33988, 381=>34110, 709=>34409, 578=>34286, 447=>34175, 54=>33821, 185=>33929, 316=>34049, 775=>34473, 644=>34350, 513=>34229, 120=>33874, 251=>33989, 382=>34111, 710=>34410, 579=>34287, 448=>34176, 55=>33822, 186=>33930, 317=>34050, 776=>34474, 645=>34351, 514=>34230, 121=>7365, 252=>33990, 383=>34112, 711=>34411, 580=>34288, 449=>34177, 56=>33823, 187=>33931, 318=>34051, 777=>34475, 646=>34352, 515=>34231, 122=>33875, 253=>18337, 384=>34113, 712=>34412, 581=>34289, 450=>34178, 57=>33824, 188=>6325, 319=>34052, 778=>34476, 647=>32298, 516=>34232, 123=>24274, 254=>33991, 385=>34114, -1=>33778, 713=>34413, 582=>34290, 451=>34179, 189=>33932, 320=>34053, 779=>34477, 648=>34353, 124=>33876, 255=>33992, 386=>34115, 714=>34414, 583=>34291, 452=>34180, 59=>33825, 190=>33933, 321=>34054, 780=>34478, 649=>34354, 518=>34233, 125=>19482, 256=>33993, 387=>34116, 715=>34415, 584=>34292, 453=>34181, 60=>33826, 191=>33934, 322=>34055, 781=>34479, 650=>34355, 519=>34234, 126=>33877, 257=>33994, 388=>34117, 716=>34416, 585=>34293, 454=>34182, 61=>33827, 192=>33935, 323=>34056, 782=>34480, 651=>34356, 520=>34235, 127=>33878, 258=>33995, 389=>34118, 717=>34417, 586=>34294, 455=>34183, 62=>33828, 193=>33936, 324=>34057, 783=>34481, 652=>34357, 521=>34236, 128=>33879, 259=>33996, 390=>34119, 718=>34418, 587=>26017, 456=>34184, 63=>33829, 194=>33937, 325=>34058, 784=>34482, 653=>34358, 522=>34237, 129=>33880, 260=>33997, 391=>34120, 719=>34419, 588=>34295, 64=>12784, 195=>33938, 326=>34059, 785=>34483, 654=>34359, 523=>34238, 261=>33998, 392=>34121}


#r_users = {} # key: user_id en mysql, value: user_id en gm

PhpbbImporter.establish_connection(
                                   :adapter  => "mysql",
:host     => "localhost",
:username => "mysql",
:password => "",
:database => "test",
:encoding => 'utf8'
)

if nil then 
# importamos usuarios
total = PhpbbImporter.db_query("SELECT count(*) as count from phpbb_users")[0]['count'].to_i
print "Importando usuarios (#{total} a importar)"

stats = {'0' => 0, '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0, '7' => 0, '8' => 0}
PhpbbImporter.db_query("SELECT * FROM phpbb_users ORDER BY user_id").each do |dbu|
  un = User.new({:login => dbu['username'],
    :password => dbu['user_password'],
    :email => dbu['user_email'],
    :icq => dbu['user_icq'],
    :homepage => dbu['user_website'],
    :city => dbu['user_from'],
    :icq => dbu['user_icq'],
    :msn => dbu['user_msnm'],
    :birthday => dbu['user_birthday'],
    :sex => dbu['user_gender'], # TODO 0 -> female? 1 -> male
    :lastseen_on => Time.at(dbu['user_lastvisit'].to_i),
    :ipaddr => [dbu['user_registered_ip']].pack('H*').unpack('C*').join('.')
  })
  
  un.login = "#{un.login.ljust(3, 'a')}" if un.login.size < 3
  un.login = un.login.normalize if !( /^[-a-zA-Z0-9_~.\[\]\(\)\:=|*^]{3,18}$/ =~ un.login)
  un.login = un.login[0..17] if un.login.size > 17
  un.email = "#{un.login}@nonexistant.com" if !(Cms::EMAIL_REGEXP =~ un.email.to_s )
  un.ipaddr = '127.0.0.1' if !(Cms::IP_REGEXP =~ un.ipaddr)
  dbu['username'] = un.login
  
  # (0) Si existe un usuario con el mismo login, el mismo email y misma contraseña -> perfect match
  # Warning para todos los demás
  # (1) Si coinciden login y email pero no contraseña se queda la contraseña de la web que visitase por última vez
  # (2) Si coinciden login y password pero no el email presuponemos que es la misma persona, se actualiza el email de la cuenta q se usó por última vez
  # (3) Si solo coinciden login si la cuenta de gm no se está usando desde hace más de 3 meses y tiene karma 0 se renombra la cuenta vieja para liberar el nick y se crea cuenta nueva
  # (4) Si solo coinciden login en caso de que (3) no se cumpla (renombramos la cuenta importada)
  # (5) Si no existe el nick pero hay otro usuario con mismo email si la contraseña coincide se migran las cuentas
  # (6) Si no existe el nick pero hay otro usuario con mismo email y distinta contraseña se unen tb
  # (7) En cualquier otro caso se crea la cuenta nueva
  # (8) Si hay otra cuenta con el mismo email asumimos que son la misma persona y los unimos
  if (u = User.find(:first, :conditions => ['lower(login) = lower(?)  AND lower(email) = lower(?) and password = ?', dbu['username'], dbu['user_email'], dbu['user_password']]))
    un = u 
    # TODO TODO TODO
    stats['0'] += 1
  elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?)  AND lower(email) = lower(?)', dbu['username'], dbu['user_email']]))
    un = u 
    print "login & email ok, password missmatch (#{dbu['username']})\n"
    stats['1'] += 1
  elsif (u = User.find(:first, :conditions => ['lower(email) = lower(?)', dbu['user_email']]))
    un = u 
    print "email ok, login & password missmatch (#{dbu['username']})\n"
    stats['1'] += 1
  elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?)  AND password = ?', dbu['username'], dbu['user_password']]))
    un = u
    print "login & password ok, email missmatch (#{dbu['username']})\n"
    stats['2'] += 1
  elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?) AND cache_karma_points = 0 AND lastseen_on < now() - \'3 months\'::interval', dbu['username']]))
    new_name_i = 1
    o_login = u.login
    u.login = "#{o_login}#{new_name_i}"
    u.email = "#{u.login}@nonexistant.com" if !(Cms::EMAIL_REGEXP =~ u.email.to_s )
    while !u.save
      puts 'foo'
      puts u.errors.full_messages
      new_name_i += 1
      u.login = "#{o_login}#{new_name_i}"
    end
    print "login ok, email & password missmatch, gm account unused (#{dbu['username']})\n"
    stats['3'] += 1
  elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?)', dbu['username']]))
    new_name_i = 1
    o_login = un.login
    un.login = "#{o_login}#{new_name_i}"
    while !un.save # TODO si la cuenta no se guarda por otra causa esto peta
      puts 'faa'
      puts un.errors.full_messages
      new_name_i += 1
      un.login = "#{o_login}#{new_name_i}"
    end
    User.db_query("UPDATE users SET password = '#{dbu['user_password']}' WHERE id = #{un.id}")
    print "login ok, email & password missmatch, renaming imported account (#{dbu['username']})\n"
    stats['4'] += 1
  else # no nick conflict
    if (u = User.find(:first, :conditions => ['lower(email) = lower(?) and password = ?', dbu['user_email'], dbu['user_password']]))
      un = u
      print "email & password match (#{dbu['username']})\n"
      stats['5'] += 1
    elsif (u = User.find(:first, :conditions => ['lower(email) = lower(?)', dbu['user_email']]))
      un = u
      print "email match (#{dbu['username']})\n"
      stats['6'] += 1
    else
      print "new account (#{dbu['username']})\n"
      stats['7'] += 1
    end
  end
  
  if un.new_record?
    un.save 
    User.db_query("UPDATE users SET password = '#{dbu['user_password']}' WHERE id = #{un.id}")
  end
  
  if un.new_record?
    puts "#{un.login} todavía tiene errores, imposible guardar"
    puts un.errors.full_messages
    raise Exception
  end
  
  # un tiene ahora el objeto user en gm guardado
  r_users[dbu['user_id'].to_i] = un.id
  User.db_query("UPDATE users SET created_on = '#{Time.at(dbu['user_regdate'].to_i).strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{un.id}")  
end
stats.keys.sort.each { |k| print "#{k} | #{stats[k]}\n" }

p r_users
sum = 0
stats.values.each { |v| sum += v}
print "Total cases: #{total} | Handled cases: #{sum}\n"

end


total_topics = PhpbbImporter.db_query("SELECT count(*) as count from phpbb_topics")[0]['count'].to_i
total_comments = PhpbbImporter.db_query("SELECT count(*) as count from phpbb_posts")[0]['count'].to_i - total_topics
done_topics = 0
done_comments = 0
# importamos foros
PhpbbImporter.db_query("SELECT * FROM phpbb_forums ORDER BY forum_id").each do |dbf|
  tc = TopicsCategory.find(:first, :conditions => ['root_id = 542 and parent_id = 542 and name = ? and description = ?', dbf['forum_name'], dbf['forum_desc']])
  tc = TopicsCategory.create({:root_id => 542, :parent_id => 542, :name => dbf['forum_name'], :description => dbf['forum_desc']}) if tc.nil?
  PhpbbImporter.db_query("SELECT * FROM phpbb_topics WHERE forum_id = #{dbf['forum_id']} ORDER BY topic_id").each do |dbt|
    done_topics += 1
    next if tc.topics.find_by_title(dbt['topic_title'])
    puts "Topic: #{dbt['topic_title']}"
    dbpt = PhpbbImporter.db_query("SELECT * from phpbb_posts_text WHERE post_id = #{dbt['topic_first_post_id']}")[0] 
    dbp = PhpbbImporter.db_query("SELECT * from phpbb_posts WHERE post_id = #{dbt['topic_first_post_id']}")[0]
    topic = Topic.create({:hits_anonymous => dbt['topic_views'].to_i, :cache_comments_count => dbt['topic_replies'].to_i, :state => Cms::PUBLISHED, :user_id => r_users[dbt['topic_poster'].to_i], :title => dbt['topic_title'], :text => Comments.formatize(dbpt['post_text']).gsub("\r", "\n"), :created_on => Time.at(dbp['post_time'].to_i), :updated_on => Time.at(dbp['post_edit_time'].to_i),:topics_category_id => tc.id})
    if topic.new_record?
      puts topic.errors.full_messages
      raise Exception
    end
    ct = topic.unique_content
    PhpbbImporter.db_query("SELECT * FROM phpbb_posts WHERE topic_id = #{dbt['topic_id']} AND post_id <> #{dbp['post_id']} ORDER BY post_id").each do |dbpp|
      dbpp2 = PhpbbImporter.db_query("SELECT * from phpbb_posts_text WHERE post_id = #{dbpp['post_id']}")[0]
      done_comments += 1
      begin
        c = Comment.new({:content_id => ct.id, 
          :user_id => r_users[dbpp['poster_id'].to_i], 
          :host => [dbpp['poster_ip']].pack('H*').unpack('C*').join('.'), 
          :created_on => Time.at(dbpp['post_time'].to_i),
          :updated_on => Time.at(dbpp['post_edit_time'].to_i),
          :comment => Comments.formatize(dbpp2['post_text'].gsub("\r", "\n"))})
          c.save
        rescue ActiveRecord::StatementInvalid
        puts "error al guardar comentario con texto #{dbpp2['post_text']}"
      end
      if c.new_record?
        puts c.errors.full_messages
        #raise Exception
      end        
    end
    puts "topics_done: #{done_topics.to_f / total_topics} | comments_done: #{done_comments.to_f / total_comments}"
  end
end

puts "Completado"
