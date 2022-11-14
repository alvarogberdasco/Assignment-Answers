require './Gene.rb'
require './SeedStock.rb'

class Cross

    @@crosslist=Array.new
    attr_accessor :Parent1
    attr_accessor :Parent2
    attr_accessor :F2_Wild
    attr_accessor :F2_P1
    attr_accessor :F2_P2
    attr_accessor :F2_P1P2
    
    def initialize(parent1:nil, 
        parent2:nil, 
        f2_Wild:nil, 
        f2_P1:nil, 
        f2_P2:nil, 
        f2_P1P2:nil)

    @Parent1 =parent1
    @Parent2 =parent2
    @F2_Wild =f2_Wild
    @F2_P1 =f2_P1
    @F2_P2 =f2_P2
    @F2_P1P2 =f2_P1P2
    @@crosslist.append(self)
    end

    def Cross.get_list
        return @@crosslist
    end

    def chi_sq

        total_observations = @F2_Wild + @F2_P1 + @F2_P2 + @F2_P1P2
        expected_frec = [total_observations * 9/16, total_observations * 3/16, total_observations * 1/16]
        chi_w = (@F2_Wild - expected_frec[0]) **2 / expected_frec[0]
        chi_p1 = (@F2_P1 - expected_frec[1]) **2 / expected_frec[1]
        chi_p2 = (@F2_P2 - expected_frec[1]) **2 / expected_frec[1]
        chi_p1p2 = (@F2_P1P2 - expected_frec[2]) **2 / expected_frec[2]
        chi_final = chi_w + chi_p1 + chi_p2 + chi_p1p2
        chi_critic = 7.815 #

        if chi_final > chi_critic
            sidx1 = Seed.get_seed_stock.find_index("#{@Parent1}") #https://stackoverflow.com/questions/44030515/in-ruby-how-do-i-find-the-index-of-one-of-an-array-of-elements
            g1 = Seed.get_list[sidx1].mutant_gene_id
            gidx1 = Gene.get_id.find_index("#{g1}")

            sidx2 = Seed.get_seed_stock.find_index("#{@Parent2}")
            g2 = Seed.get_list[sidx2].mutant_gene_id
            gidx2 = Gene.get_id.find_index("#{g2}")

            puts "RECORDING: #{Gene.get_list[gidx1].name} is genetically linked to #{Gene.get_list[gidx2].name} with chisquare score of #{chi_final}"
            puts
            puts "FINAL REPORT:"
            puts "#{Gene.get_list[gidx1].name} is linked to #{Gene.get_list[gidx2].name}"
            puts "#{Gene.get_list[gidx2].name} is linked to #{Gene.get_list[gidx1].name}"
            puts
            Gene.get_list[gidx1].linked = "linked to #{Gene.get_list[gidx2].name}"
            Gene.get_list[gidx2].linked = "linked to #{Gene.get_list[gidx1].name}"
        end
    end
    
end