module Ias
  VALID_IAS = %w(
    jabba
    mralariko
    mrachmed
    mrcheater
    mrgod
    mrman
    nagato
  )

  @@cache_ias = {}
  def self.ia(login)
    @@cache_ias[login] ||= User.find(
        :first, :conditions => ["LOWER(login) = LOWER(?)", login])
  end

  def self.method_missing(method_name)
    if !VALID_IAS.include?(method_name.downcase.to_s)
      raise "Invalid IA name #{method_name}"
    end

    self.ia(method_name)
  end

  def self.random_huttese_sentence
    HUTTESE_SENTENCES.sample
  end

  HUTTESE_SENTENCES = [
      "harl tish ding.",
      "wah ning chee kosthpa murishani tytung ye wanya yoskah.",
      "Bargon u noa-a-uyat.",
      "Bargon wan chee kospah.",
      "Bargon yanah coto da eetha.",
      "Beeska mu-moolee bu Halapu.",
      "Bona nai kachu.",
      "Cha skrunee da pat.",
      "Chas kee nyowkee koo chooskoo.",
      "Coona tee-tocky malia?",
      "Dobra do poolyee yama.",
      "Dobra do nupee nupee um baw wah du poolyee yama.",
      "Ee yaba ma dooki massa. Eeth wong che coh pa na-geen, nah meeto toe bunky dunko. Lo choda!",
      "Goo paknee ata pankpa.",
      "Keel-ee calleya ku kah.",
      "Keh lee chalya chulkah in ting cooing koosooah.",
      "Klop poo pah.",
      "La pim nallya so bata de wompa.",
      "Luto eetheen.",
      "Mala tram pee chock makacheesa.",
      "Make-cheesay.",
      "Mwa droida bunno bunna droida.",
      "Noolee moolee bana kee cheel",
      "Pasa tah ono kolki mallya. Ee youngee d",
      "Smeeleeya whao toupee upee.",
      "See fah luto twentee, ee yaba.",
      "Soong peetch alay.",
      "Song kul rul yay pul-yaya ulwan spastika kushunkoo oponowa tweepi.",
      "Uba sanuba charra mon.",
      "Uth laynuma.",
      "Wa wanna coe moulee rah?",
      "Wanta dah moolee-rah? or Wanta wonka-rah dah?",
      "Wonkee chee sa kreespa?",
      "Yanee dah poo noo.",
      "Applied businessEdit",
      "Ap-xmasi keepuna!",
      "Blastoh",
      "Bona nai kachu.",
      "Boonowa tweepi.",
      "Cheska lopey x",
      "Chespo kutata kreesta krenko, nyakoska!",
      "Da beesga coo palyeeya pityee bo tenya go kaka juju hoopa.",
      "Do bata gee mwaa tusawa!",
      "Hagwa boska blastoh!",
      "Hagwa doopee.",
      "Hay lapa no ya!",
      "Je killya um pasa doe beeska wumpa.",
      "Jeeska da sookee koopa moe nanya.",
      "Kako Kreespa!",
      "Kapa tonka.",
      "Kava doompa D",
      "Kee hasa do blastoh.",
      "Keepuna!",
      "Kickeeyuna mo Wooky doo tee puna puna!",
      "Mikiyuna! Pasta mo rulya! Do bata gee mwaa tusawa!",
      "Moova dee boonkee ree slagwa.",
      "Pasta mo rulya!",
      "Tonta tonka.",
      "Waajo koosoro?",
      "DiningEdit",
      "Boga noga",
      "Cheska yo ho kimbabaloomba?",
      "Dopa na rocka rocka?",
      "Gardulla (drink)",
      "Gocola",
      "Hotsa Chuba",
      "Howdunga",
      "Jimunee Ronto Pagona",
      "Keebadas Binggona",
      "Lickmoomoo",
      "Mubasa Hok",
      "Ne ompee doe gaga punta?",
      "Patogga",
      "Sando G",
      "Scuzzi Spits",
      "Sleemo Poy",
      "Smak Telia",
      "Tatooni Junko Huttese alcoholic beverage[1]",
      "Tee ava un puffee lumpa?",
      "Waffmula",
      "Yafullkee",
      "Yatooni Boska Huttese alcoholic beverage[1]",
      "Yocola",
      "EntertainmentEdit",
      "Andoba ne lappee, kolka.",
      "Banya kee fofo Aduki, kolka.",
      "La lova num botaffa",
      "Cheska lopey x",
      "Kavaa kyotopa bu banda backa?",
      "Kavaa kyotopa bu whirlee backa?",
      "Koose cheekta nei.",
      "TravelEdit",
      "Cheesba hataw yuna puna?",
      "Jee oto ta Huttuk koga.",
      "Jee oto vo blastoh.",
      "Jee vopa du mooljee guma.",
      "Kava nopees do bampa woola?",
      "Kuna kee wabdah noleeya.",
      "Kuna kee wabdah nenoleeya.",
      "Jeskawa no rupee dee holo woopee?",
      "To pla da banki danko, jospi!",
      "At the racetrackEdit",
      "Buttmalia",
      "Chawa",
      "Choppa chawa",
      "Meecooda joggdu stafa do tah poda",
      "Noobie oonatee raca, rookie poodoo?",
      "Nu",
      "Roachee mah bom bom, cheespa kreespa",
      "Tah pee-chah ah kulkee flunka",
      "Leeah fam doosta!",
      "Keelya afda skocha punchee?",
  ]
end
