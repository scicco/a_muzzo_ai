module A
  module Muzzo
    module AI
      class Couple
        require 'pp'

        attr_accessor :player1
        attr_accessor :player1name
        attr_accessor :player2
        attr_accessor :player2name
        attr_accessor :sorted_names
        
        def initialize(p1, p2)
          @player1 = p1
          @player1name = player1[:name].gsub(/\s\(.+\)/,'')
          @player2 = p2
          @player2name = player2[:name].gsub(/\s\(.+\)/,'')
          @sorted_names = [player1[:name], player2[:name]].sort
        end
        
        def equal?(other)
          other_players = [other.player1, other.player2]
          other_players.include?(player1) and other_players.include?(player2)
        end
        
        def has_same_player_name?(other)
          other_players = [other.player1name, other.player2name]
          other_players.include?(player1name) and other_players.include?(player2name)
        end
        
        def <=>(other)
          sorted_names.to_s <=> other.sorted_names.to_s
        end
        
        def to_s
          pp [player1, player2]
        end
        
        def pp_print
          pp "#{player1[:name]}:#{sprintf("%.2f",player1[:percentile98])} - #{player2[:name]}:#{player2[:percentile98]}"
        end
        
        def score(percentile = :percentile98)
          player1[percentile.to_sym] + player2[percentile.to_sym]
        end
      end
    end
  end
end