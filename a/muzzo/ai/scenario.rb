module A
  module Muzzo
    module AI
      class Scenario
        require 'descriptive_statistics'
        require 'pp'
        attr_accessor :couples
        attr_accessor :percentile
        
        def initialize(couples, percentile = :percentile75)
          @couples = couples
          @percentile = percentile
        end
        
        def equal?(other)
          return false if couples.size != other.couples.size
          
          found = 0
          couples.each do |couple|
            found += 1 if other.couples.include?(couple)
          end
          found == couples.size
        end
        
        def ==(other)
          self.equal?(other)
        end
        
        def sort
          couples.sort
        end
        
        def sort!
          @couples = self.sort
        end
        
        def to_s
          pp couples.to_s
        end
        
        def pp_print(print_variance = false)
          couples.each do |c|
            c.pp_print
          end
          puts self.variance if print_variance
        end
        
        def variance
          scores = []
          couples.each do |couple|
            scores << couple.score(percentile)
          end
          scores.variance
        end
        
        def <=>(other)
          variance <=> other.variance
        end
      end
    end
  end
end