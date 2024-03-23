class Risk
  def battle(attack:, defense:)
    until attack == 0 || defense == 0
      attack, defense = fight(attack: attack, defense: defense)
    end

    [attack, defense]
  end

  def odds(attack:, defense:, times:)
    sim(attack: attack, defense: defense, times: times).count { |attack_remainder, defense_remainder|
      attack_remainder.positive?
    }.fdiv(times)
  end

  def chart(attack:, defense:, times:)
    attack_chart = Hash.new(0)
    attack.times do |i| attack_chart[i] = 0 end; attack_chart[attack] = 0
    defense_chart = Hash.new(0)
    defense.times do |i| defense_chart[i] = 0 end; defense_chart[defense] = 0

    sim(attack: attack, defense: defense, times: times).each do |attack_remainder, defense_remainder|
      attack_chart[attack_remainder] += 1
      defense_chart[defense_remainder] += 1
    end

    {attacker: attack_chart, defender: defense_chart}
  end

  def print_chart(attack:, defense:, times:)
    num_digits = [attack, defense].max.to_s.length
    chart_hash = chart(attack: attack, defense: defense, times: times)

    puts 'attacker:'
    chart_hash[:attacker].sort_by { |remainder, count| remainder }.each do |remainder, count|
      puts remainder.to_s.rjust(num_digits) + ': ' + count.to_s
    end

    puts 'defender:'
    chart_hash[:defender].sort_by { |remainder, count| remainder }.each do |remainder, count|
      puts remainder.to_s.rjust(num_digits) + ': ' + count.to_s
    end

    nil
  end

  def chart_chart(attack:, defense:, times:)
    max = [attack, defense].max
    num_digits = max.to_s.length
    chart_hash = chart(attack: attack, defense: defense, times: times)
    width = 100

    puts ' ' * (width - 10) + 'attacker' + ' ' * (6 + num_digits) + 'defender'
    (0..max).each do |i|
      attacker_num = (chart_hash[:attacker][i].fdiv(times) * width).round
      defender_num = (chart_hash[:defender][i].fdiv(times) * width).round

      print ' ' * (width - attacker_num)
      print '=' * attacker_num
      print '|' + i.to_s.rjust(num_digits) + '|'
      puts '=' * defender_num
    end

    nil
  end


  private

  def fight(attack:, defense:)
    attack_rolls = Array.new([attack, 3].min) { roll }
    defense_rolls = Array.new([defense, 2].min) { roll }

    attack_rolls.sort.reverse.zip(defense_rolls.sort.reverse).each do |attack_roll, defense_roll|
      break unless attack_roll && defense_roll

      if defense_roll < attack_roll
        defense -= 1
      else
        attack -= 1
      end
    end

    [attack, defense]
  end

  def roll
    rand(1..6)
  end

  def sim(attack:, defense:, times:)
    Array.new(times) { battle(attack: attack, defense: defense) }
  end
end
