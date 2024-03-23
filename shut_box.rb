class ShutBox
  attr_reader :options, :to_beat, :score_win_odds, :cached_odds, :roll_options

  def initialize(high_num:, to_beat: nil)
    @options = []
    for i in 1..high_num
      options << i
    end
    @to_beat = to_beat
    @score_win_odds = Hash.new
    max_score = ((high_num * (high_num + 1)) / 2) - 1
    for i in 0..max_score
      if to_beat
        if i < to_beat
          score_win_odds[i] = 1
        elsif i == to_beat
          score_win_odds[i] = 1.fdiv(2) #tie
        else
          score_win_odds[i] = 0
        end
      else
        box = ShutBox.new(high_num: high_num, to_beat: i)
        score_win_odds[i] = 1 - box.win_prob
      end
    end
    @cached_odds = {}
    @roll_options = {}
  end

  def best_play(roll)
    best_play_for_options(roll, options)
  end

  def do_play(play)
    play.each { |p| options.delete(p) }
    options
  end

  def win_prob
    win_odds(odds_hash(options))
  end


  private

  def best_play_for_options(roll, remaining_options)
    plays_to_odds = {}
    play_options(roll, remaining_options).each do |play|
      played_remaining_options = remaining_options.select { |o| !play.include?(o) }
      plays_to_odds[play] = odds_hash(played_remaining_options)
    end
    best_play = plays_to_odds.max_by { |play, odds| win_odds(odds) }
      
    best_play && best_play.first
  end


  def play_options(roll, remaining_options)
    all_options(roll).select do |option|
      option.all? { |o| remaining_options.include?(o) }
    end
  end

  def all_options(roll)
    return roll_options[roll] if roll_options[roll]

    all = []
    all << [roll]
    two_splits(roll).each { |split| all << split }
    three_splits(roll).each { |split| all << split }
    four_splits(roll).each { |split| all << split }

    roll_options[roll] = all
    all
  end

  def two_splits(num)
    splits = []
    for i in 1...num
      remainder = num - i
      splits << [i, remainder] if i < remainder
    end

    splits
  end
  
  def three_splits(num)
    splits = []
    for i in 1...num
      for j in 1...i
        remainder = num - i - j
        splits << [i, j, remainder] if j < remainder
      end
    end

    splits
  end

  def four_splits(num)
    splits = []
    for i in 1...num
      for j in 1...i
        for k in 1...j
          remainder = num - i - j - k
          splits << [i, j, k, remainder] if k < remainder
        end
      end
    end

    splits
  end
    
  def odds_hash(remaining_options)
    return cached_odds[remaining_options] if cached_odds[remaining_options]
    return {0 => 1} if remaining_options.empty?

    scores_to_chances = Hash.new(0)
    roll_chances(number_of_dice(remaining_options)).each do |roll, roll_chance|
      next_play = best_play_for_options(roll, remaining_options)
      if next_play
        played_remaining_options = remaining_options.select { |o| !next_play.include?(o) }
        odds_hash(played_remaining_options).each do |next_score, score_chance|
          scores_to_chances[next_score] += roll_chance * score_chance
        end
      else
        scores_to_chances[score(remaining_options)] += roll_chance
      end
    end
    cached_odds[remaining_options] = scores_to_chances

    scores_to_chances
  end

  def number_of_dice(o)
    return 1 if o.max <= 6

    2
  end

  def roll_chances(num_dice)
    chances = Hash.new(0)
    if num_dice == 1
      for i in 1..6
        chances[i] += 1.fdiv(6)
      end
    elsif num_dice == 2
      for i in 1..6
        for j in 1..6
          chances [i + j] += 1.fdiv(36)
        end
      end
    else
      raise "Oops!"
    end

    chances
  end

  def score(o)
    o.reduce(:+) || 0
  end

  def win_odds(odds)
    chance = 0
    odds.each do |s, o|
      chance += score_win_odds[s] * o
    end

    chance
  end
end
