# -*- encoding : utf-8 -*-
require 'test_helper'

class ClansSponsorTest < ActiveSupport::TestCase

  test "should_fail_if_empty_clan" do
    c = ClansSponsor.new({:name => 'Mermelada Ocarina'})
    assert_equal false, c.save
    assert_not_nil c.errors[:clan_id]
  end

  test "should_be_added_if_everything_ok" do
    @clan = Clan.find(1)
    @sponsor = @clan.clans_sponsors.create({:name => 'Mermelada Ocarina'})
    assert @sponsor.kind_of?(ClansSponsor)
  end

  test "should_log_if_added_correctly" do
    test_should_be_added_if_everything_ok
    assert_equal "Añadido #{@sponsor.name} a la lista de sponsors", @clan.clans_logs_entries.find(:first, :order => 'id DESC').message
  end

  test "should_be_modifiable" do
    assert_equal true, ClansSponsor.find_by_name('Ensaladillas Godzilla').save
  end

  test "should_be_destroyable" do
    test_should_be_added_if_everything_ok
    assert_equal true, @sponsor.destroy.frozen?
    assert_equal nil, @clan.clans_sponsors.find_by_name('Mermelada Ocarina')
  end

  test "should_log_if_destroyed" do
    test_should_be_destroyable
    assert_equal "Eliminado #{@sponsor.name} de la lista de sponsors", @clan.clans_logs_entries.find(:first, :order => 'id DESC').message
  end
end
