
class Gene

    @@idlist=Array.new
    @@genelist=Array.new
    attr_accessor :id  
    attr_accessor :name
    attr_accessor :mutant_phenotype
    attr_accessor :linked

    def initialize(id:nil, name:nil, mutant_phenotype:nil,linked:"not linked") 
        @id = id 
        @name = name
        @mutant_phenotype = mutant_phenotype
        @linked = linked
        @@genelist.append(self)
        @@idlist.append(@id)
    end
    
    def Gene.get_id
        return @@idlist
    end

    def Gene.get_list
        return @@genelist
    end
end

