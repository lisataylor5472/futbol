
class StatTracker
  attr_reader :games, :teams, :game_teams, :home_goals, :away_goals, :season

  def initialize(locations)
    @games = CSV.read locations[:games], headers: true, header_converters: :symbol
    @teams = CSV.read locations[:teams], headers: true, header_converters: :symbol
    @game_teams = CSV.read locations[:game_teams], headers: true, header_converters: :symbol
    @home_goals = []
    @away_goals = []
    @season = []
  end

  def self.from_csv(locations)
    StatTracker.new(locations)
  end

  def highest_total_score
    game_with_max = @games.max_by do |row|
      row[:away_goals].to_i + row[:home_goals].to_i
    end
    return game_with_max[:away_goals].to_i + game_with_max[:home_goals].to_i
  end

  def lowest_total_score
    game_with_min = @games.min_by do |row|
      row[:away_goals].to_i + row[:home_goals].to_i
    end
    return game_with_min[:away_goals].to_i + game_with_min[:home_goals].to_i
  end

  def percentage_home_wins
    home_wins = @game_teams.count do |game|
      game[:hoa] == "home" && game[:result] == "WIN"
    end
    (home_wins.to_f / @game_teams.count.to_f).round(2)
  end

  def percentage_visitor_wins
    visitor_wins = @game_teams.count do |game|
      game[:hoa] == "away" && game[:result] == "WIN"
    end
    (visitor_wins.to_f / @game_teams.count.to_f).round(2)
  end

  def average_goals_per_game
    total_goals = @games.sum do |row|
      row[:away_goals].to_i + row[:home_goals].to_i
    end.to_f/@games.count
    total_goals.round(2)
  end

  def average_goals_by_season
    h = Hash.new(0)
    count = Hash.new(0)
    @games.each do |row|
      h[row[:season]] += row[:home_goals].to_f + row[:away_goals].to_f
      count[row[:season]] += 1
    end
    h.each do |key, val|
      h[key] = (val/count[key]).round(2)
    end
    h
  end

  def team_info(id) #Team Stats
    h = {}
    team = @teams.find do |row|
      row[:team_id] == id
    end
    h["Team ID"] = team[:team_id]
    h["Franchise ID"] = team[:franchiseid]
    h["Team Name"] = team[:teamname]
    h["Abbreviation"] = team[:abbreviation]
    h["Link"] = team[:link]
    h
  end

  def tie
    @games.find_all do |game|
      game[:home_goals] == game[:away_goals]
    end
  end

  def percentage_ties
    (tie.count.to_f / games.count * 100).round(3)
  end

  def season_finder(game_id) #Team Stats
    game = @games.find do |row|
      game_id == row[:game_id]
    end
    game[:season]
  end

  def games_played_in_season(team_id, season_id) #Teams Stats
    game_ids = []
    @games.each do |row|
      if row[:season] == season_id && (row[:away_team_id] == team_id || row[:home_team_id] == team_id)
        game_ids << row[:game_id]
      end
    end
    csv_games = []
    @game_teams.each do |row|
      game_ids.each do |id|
        if row[:game_id] == id && row[:team_id] == team_id
          csv_games << row
        end
      end
    end
    csv_games
  end

  def avg_wins_by_season(team_id, season_id) #Team Stats
    wins = 0
    games = games_played_in_season(team_id, season_id)
    games.each do |game|
      if game[:result] == "WIN"
        wins += 1
      elsif game[:result] == "TIE"
        wins += 0.5
      end
    end
    wins / games_played_in_season(team_id, season_id).count
  end

  def all_seasons_played(team_id)
    seasons_played = []
    @games.map do |row|
      if row[:away_team_id] == team_id || row[:home_team_id] == team_id
        seasons_played << row[:season]
      end
    end
    seasons_played.uniq
  end

  def best_season(team_id)
    h = {}
    all_seasons_played(team_id).each do |season_id|
      h[season_id] = avg_wins_by_season(team_id, season_id)
    end

    best = h.max_by do |season, avg|
      avg
    end
    best[0]
  end
end
