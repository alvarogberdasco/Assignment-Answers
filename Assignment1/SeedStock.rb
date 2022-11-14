
class Seed

    @@seed_stocklist=Array.new
    @@seedlist=Array.new
    attr_accessor :seed_stock  
    attr_accessor :mutant_gene_id
    attr_accessor :last_planted
    attr_accessor :storage
    attr_accessor :grams_remaining
    
    def initialize(seed_stock:nil, 
        mutant_gene_id:nil, 
        last_planted:nil, 
        storage:nil, 
        grams_remaining:nil) 

        @seed_stock=seed_stock  
        @mutant_gene_id=mutant_gene_id
        @last_planted=last_planted
        @storage=storage
        @grams_remaining=grams_remaining
        @@seedlist.append(self)
        @@seed_stocklist.append(@seed_stock)
    end

    def Seed.get_seed_stock
        return @@seed_stocklist
    end

    def Seed.get_list
        return @@seedlist
    end

    def plant(grams)
        
        @grams_remaining = @grams_remaining.to_i - grams
        if @grams_remaining <= 0
            puts "OK, don't panic, but it seems you ran out of seed #{@seed_stock}"
            @grams_remaining = 0
        end  
        @last_planted = DateTime.now.strftime('%-d/%-m/%Y')  #https://stackoverflow.com/questions/7415982/how-do-i-get-the-current-date-time-in-dd-mm-yyyy-hhmm-format
        CSV.open("new_seed_stock.tsv","w+", col_sep: "\t") do |seed|
            seed << ["Seed_Stock", "Mutant_Gene_ID", "Last_Planted", "Storage", "Grams_Remaining"]
            Seed.get_list.drop(1).each do |record|
            seed << [record.seed_stock, record.mutant_gene_id, record.last_planted, record.storage, record.grams_remaining]
            end 
        end 
        
    end    
end