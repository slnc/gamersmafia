require File.dirname(__FILE__) + '/../test_helper'

class ClansSponsorTest < ActiveSupport::TestCase

  def test_should_fail_if_empty_clan
    c = ClansSponsor.new({:name => 'Mermelada Ocarina'})
    assert_equal false, c.save
    assert_not_nil c.errors[:clan_id]
  end

  def test_should_be_added_if_everything_ok
    @clan = Clan.find(1)
    @sponsor = @clan.clans_sponsors.create({:name => 'Mermelada Ocarina'})
    assert @sponsor.kind_of?(ClansSponsor)
  end

  def test_should_log_if_added_correctly
    test_should_be_added_if_everything_ok
    assert_equal "Añadido #{@sponsor.name} a la lista de sponsors", @clan.clans_logs_entries.find(:first, :order => 'id DESC').message
  end

  def test_should_be_modifiable
    assert_equal true, ClansSponsor.find_by_name('Ensaladillas Godzilla').save
  end

  def test_should_be_destroyable
    test_should_be_added_if_everything_ok
    assert_equal true, @sponsor.destroy.frozen?
    assert_equal nil, @clan.clans_sponsors.find_by_name('Mermelada Ocarina')
  end

  def test_should_log_if_destroyed
    test_should_be_destroyable
    assert_equal "Eliminado #{@sponsor.name} de la lista de sponsors", @clan.clans_logs_entries.find(:first, :order => 'id DESC').message
  end
end
