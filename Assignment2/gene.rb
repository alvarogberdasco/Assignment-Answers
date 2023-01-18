class Gene 
  attr_accessor :interactions #attribute that will contain the genes that interact with the gene
  attr_accessor :agi_locus #attribute that will contain the AGI locus of that gene (the id)
  attr_accessor :level #attribute that indicate at what depth corresponds the gene at. 
  require 'rest-client'
  
  def initialize(params = {})#the values of the properties that the new object Gene will have
      @agi_locus = params.fetch(:agi_locus,nil)
      @interactions = obtain_interactions(@agi_locus).sort #sort the list of interactions by the AGI locus
      @level = params.fetch(:level,nil).to_i #atribute to distinguish the origin of the gen. If it is from the original list = 1,
      #if it is a gene from the list_2 then = 2 and if it is a gene from the list_3 then = 3.
  end
  
  def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
    response = RestClient::Request.execute({
      method: :get,
      url: url.to_s,
      user: user,
      password: pass,
      headers: headers})
    return response
    
  rescue RestClient::ExceptionWithResponse => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end 

  def obtain_interactions(agi_locus) #function that will look for the interactions of the gene and store them. 
    result = fetch("www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{agi_locus}?format=tab25")  
    list = Array.new #list that will contain the interactions.
    if result #if that gene has interactions:
        res = Array.new(result.body.split("\n")) #array in which each element is an interaction
        res.each{|line| line = line.split("\t") #line if an array in which each element is a column of the interaction. 
        if line[9].match(/Arabidopsis thaliana/) == nil #if that interaction is from another organism that is not Arabidopsis thaliana, skip to the next interaction. 
          next
        end
        if line[10].match(/Arabidopsis thaliana/) == nil
          next
        end          
        if line[4].match(/A[tT][1-5]g/) == nil #if that interaction doesn't have a AGI locus, skip to the next interaction. 
          next
        end
        if line[5].match(/A[tT][1-5]g/) == nil
          next
        end
        if line[14].match(/\d.\d{2}/)[0].to_f < 0.45 #if the miscore of that interaction is lower than 0.45, skip to the next interaction.
          next
        end    
        int1 = line[4].match(/A[tT][1-5]g\d+/)[0] #obtain the AGI locus of the gen 
        
        int2 = line[5].match(/A[tT][1-5]g\d+/)[0]#obtain the AGI locus of the gen 
                  
        if list.include? int1.downcase #to avoid insert repeated interactions 
          next
        end         
        
        if list.include? int2.downcase
          next
        end
        
        if int1.casecmp(@agi_locus) == 0 #to ignore the case of the letters. If the strings are equals, it returns 0. So if the interactor 1 is the AGI locus insert the other interactor.
           list << int2.downcase
        else
            list << int1.downcase
        end}
        
    else    
      list << ""
    end
       
       return list.select{|int| int != agi_locus} #avoid to insert the AGI locus of the original gen.       
  end
  
end