module A
  module Muzzo
    module AI
      class Couple
        require 'pp'
        
        attr_accessor :player1
        attr_accessor :player2
        attr_accessor :sorted_names
        
        def initialize(p1, p2)
          @player1 = p1
          @player2 = p2
          @sorted_names = [player1[:name], player2[:name]].sort
        end
        
        def equal?(other)
          other_players = [other.player1, other.player2]
          other_players.include?(player1) and other_players.include?(player2)
        end
        
        def <=>(other)
          sorted_names.to_s <=> other.sorted_names.to_s
        end
        
        def to_s
          pp [player1, player2]
        end
        
        def pp_print
          pp "#{player1[:name]}:#{player1[:percentile75]} - #{player2[:name]}:#{player2[:percentile75]}"
        end
        
        def score(percentile = :percentile75)
          player1[percentile.to_sym] + player2[percentile.to_sym]
        end
      end
    end
  end
end