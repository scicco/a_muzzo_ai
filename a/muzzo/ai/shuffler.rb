require 'descriptive_statistics'
require 'csv'
require 'pry'
require 'ruby-progressbar'

module A
  module Muzzo
    module AI
      require_relative 'scenario'
      require_relative 'couple'
      
      class Shuffler
        attr_accessor :filename
        
        attr_accessor :players
        attr_accessor :number_of_players
        
        attr_accessor :role_file
        attr_accessor :roles
        attr_accessor :indifferent_role
        
        attr_accessor :vote_file
        attr_accessor :votes
        attr_accessor :unknown_vote
        
        attr_accessor :min_strength_bound
        attr_accessor :max_strength_bound
        
        attr_accessor :jokes
        attr_accessor :do_jokes
        
        def players_by_role(players, role)
          players.select { |player| player[:role] == role.to_s or player[:role] == @indifferent_role[0] }
        end
        
        def players_except_role(players, role)
          players.reject { |player| player[:role] == role.to_s and player[:role] != @indifferent_role[0] }
        end
        
        def role_by_name(name)
          found = false
          result = nil
          @roles.each do |role|
            role_name = role[0]
            if name.include?(role_name)
              result = role[1]
              found = true
              break
            end
          end
          unless found
            puts "Every name of Player in excel column must contain one of these #{@roles.map { |role_pair| role_pair[0] }.join(' , ')}"
            raise "WTF name is this: #{name}"
          end
          result
        end
        
        def collect_player_names
          players = []
          ::CSV.foreach(@filename, headers: false) do |row|
            (2..(@number_of_players + 1)).each do |index|
              players << {
                name: row[index],
                role: role_by_name(row[index]),
                index: index,
                votes: [],
                percentile95: 0,
                percentile90: 0,
                percentile85: 0,
                percentile80: 0,
                percentile75: 0
              }
            end
            break
          end
          raise 'Houston we got a problem' if @number_of_players != players.size
          players
        end
        
        def import_data(players)
          ::CSV.foreach(@filename, headers: true) do |row|
            timestamp = row[0]
            email = row[1]
            (2..(@number_of_players + 1)).each_with_index do |row_index, player_index|
              #puts "row_index: #{row_index} player_index: #{player_index}"
              begin
                players[player_index][:votes] << translate_vote(row[row_index])
              rescue => e
                continue if e == 'skip this one'
              end
            end
          end
        end
        
        def compute_percentiles(players)
          players.each do |player|
            [99, 98, 95, 90, 85, 80, 75, 50].each do |percentage|
              percentile_name = "percentile#{percentage}"
              player[percentile_name.to_sym] = player[:votes].percentile(percentage)
            end
          end
        end
        
        def translate_vote(vote)
          raise 'skip this one' if vote == @unknown_vote
          found = false
          result = nil
          @votes.each do |vote_pair|
            name = vote_pair[0]
            if name == vote
              found = true
              result = vote_pair[1]
              break
            end
          end
          unless found
            puts "WTF VOTE IS THIS!!! #{vote}"
            raise 'skip this one'
          end
          result
        end
        
        def popular_role(players)
          count = {}
          players.each do |player|
            count[player[:role].downcase.to_sym] ||= 0
            count[player[:role].downcase.to_sym] += 1
          end
          sorted = count.sort_by { |k, v| v }.to_h
          pp 'SORTED ROLES ARE: '
          pp sorted
          sorted.keys.last.upcase
        end
        
        def unpopular_role(players)
          count = {}
          players.each do |player|
            count[player[:role].downcase.to_sym] ||= 0
            count[player[:role].downcase.to_sym] += 1
          end
          sorted = count.sort_by { |k, v| v }.to_h
          pp 'SORTED ROLES ARE: '
          pp sorted
          sorted.keys.first.upcase
        end
        
        def check_strength(player1, player2, percentile)
          sum = player1[percentile.to_sym].to_f + player2[percentile.to_sym].to_f
          (sum >= @min_strength_bound and sum <= @max_strength_bound)
        end
        
        def is_a_forbidden_couple(couple)
          forbidden = false
          couple_obj = Couple.new(couple[0], couple[1])
          @forbidden_couples.each do |forbidden_couple|
            if couple_obj.has_same_player_name?(forbidden_couple)
              forbidden = true
              break
            end
          end
          forbidden
        end
        
        def dedup_couples(couples)
          cleaned = []
          couples.each do |couple|
            next if cleaned.include?([couple[1], couple[0]])
            cleaned << couple
          end
          cleaned
        end
        
        def couples_by_name(couples, name)
          couples.select { |couple| couple[0][:name] == name or couple[1][:name] == name }
        end
        
        def couple_by_name(couples, name)
          couples_by_name(couples, name).sample
        end
        
        def clean_couples(couples, new_match)
          couples.reject { |couple| couple[0][:name] == new_match[0][:name] or couple[1][:name] == new_match[0][:name] or
            couple[0][:name] == new_match[1][:name] or couple[1][:name] == new_match[1][:name]
          }
        end
        
        def print_joke
          return if @jokes.nil?
          joke = @jokes.shuffle.pop
          @jokes = @jokes - [joke]
          puts joke
        end
        
        def shuffle_players(players, percentile)
          possible_combinations = players.product(players)
          
          couples = []
          possible_combinations.each do |couple|
            next if couple[0][:role].to_s != @indifferent_role[0] and couple[0][:role] == couple[1][:role]
            next if couple[0][:name] == couple[1][:name]
            next unless check_strength(couple[0], couple[1], percentile)
            next if is_a_forbidden_couple(couple)
            couples << couple
          end
          
          couples = dedup_couples(couples)
          
          scenarios = []
          
          progressbar = ProgressBar.create(total: 10_000)
          5_000.times do |i|
            if i % 2000 == 0 and @max_strength_bound == 13 and @do_jokes == true
              system('clear')
              print_joke
            end
            progressbar.increment
            
            scenario = generate_scenario(couples)
            next unless scenario.size == (@number_of_players / 2)
            scenario_obj = Scenario.new(scenario.map { |couple| Couple.new(couple[0], couple[1]) }, percentile)
            next if scenarios.include?(scenario_obj)
            next if check_existence(scenarios, scenario_obj)
            scenarios << scenario_obj
          end
          
          scenarios
        end
        
        def check_existence(scenarios, new_scenario)
          found = false
          scenarios.each do |scenario|
            found = scenario.equal?(new_scenario)
            break if found
          end
          found
        end
        
        def generate_scenario(couples)
          scenario = []
          until couples.empty?
            # get player
            # sample couple
            # clean couples
            # iterate
            playa = couples.first[0]
            new_match = couple_by_name(couples, playa[:name])
            scenario << new_match
            couples = clean_couples(couples, new_match)
          end
          scenario
        end
        
        
        def load_jokes_stuff
          begin
            @joke_file = YAML.load_file('jokes.yml')
            @jokes = @joke_file[:jokes]
          rescue Errno::ENOENT
          end
          @do_jokes = (!@jokes.nil? and @jokes.size > 0)
        end
        
        def load_votes
          @vote_file = YAML.load_file('votes.yml')
          raise 'Missing votes.yml' unless @vote_file[:votes].size > 0
          @votes = @vote_file[:votes]
          @unknown_vote = @vote_file[:unknown]
        end
        
        def load_roles
          @role_file = YAML.load_file('roles.yml')
          raise 'Missing roles.yml' unless @role_file[:roles].size > 0
          @roles = @role_file[:roles]
          @indifferent_role = @role_file[:indifferent]
          @roles << @indifferent_role
        end
        
        def load_forbidden_couples
          @forbidden_couples_file = YAML.load_file('forbidden_couples.yml')
          forbidden_couples = @forbidden_couples_file[:couples]
          pp forbidden_couples
          @forbidden_couples = []
          forbidden_couples.each do |forbidden_couple|
            @forbidden_couples << Couple.new({name: forbidden_couple[0]}, {name: forbidden_couple[1]})
          end
          @forbidden_couples
        end
        
        def start(number_of_players)
          number_of_players ||= 18
          @players = []
          @number_of_players = number_of_players
          @filename = 'responses.csv'
          
          load_jokes_stuff
          load_votes
          load_roles
          load_forbidden_couples
          
          @players = collect_player_names
          
          import_data(@players)
          
          compute_percentiles(@players)
          
          votes = []
          
          puts '*' * 80
          puts ' The Players are: '
          puts '*' * 80
          @players.each do |player|
            puts "#{player[:name]}:#{player[:percentile98]}:#{player[:role]}"
            votes << player[:percentile98]
          end
          
          average = votes.inject(&:+) / @number_of_players.to_f
          best_average = 9.0
          puts '*' * 80
          puts "Average is: #{average}"
          puts "variance is: #{votes.variance}"
          puts '*' * 80
          puts ''
          puts ''
          puts ''
          average_adjust_factor = average / best_average / 4
          
          @min_strength_bound = 10
          @max_strength_bound = 12
          @min_strength_bound += average_adjust_factor
          @max_strength_bound -= average_adjust_factor
          
          best_results = []
          [98, 90, 80, 75].each do |percentage|
            10.times do |i|
              percentile_name = "percentile#{percentage}"
              @min_strength_bound -= average_adjust_factor
              @min_strength_bound = [1, @min_strength_bound].max
              @max_strength_bound += average_adjust_factor
              @max_strength_bound = [13, @max_strength_bound].min
              
              @do_jokes = @max_strength_bound == 13
              results = shuffle_players(@players, percentile_name.to_sym)
              if results.size > 0
                best_results << results[0..10].sample
                @min_strength_bound = 10
                @max_strength_bound = 12
                @min_strength_bound += average_adjust_factor
                @max_strength_bound -= average_adjust_factor
                break
              end
            end
          end
          
          puts ''
          puts '*' * 80
          puts '  <DRUM ROLLS>...'
          sleep(5)
          puts ''
          puts '*' * 80
          puts '* THE TEAMS ARE: '
          puts '*' * 80
          sleep(3)
          best_results.sort!
          if best_results.size > 0
            best_results.first.pp_print
            puts ''
            puts "calculated using: #{best_results.first.percentile.to_s}"
          else
            puts ''
            puts 'There no possible solution for these votes'
          end
        end
      end
    end
  end
end