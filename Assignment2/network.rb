class InteractionNetwork

  attr_accessor :gene_original #The object of the first gene used to search for interactions
  attr_accessor :network #attribute that will contain the members of the network
  attr_accessor :all_genes #hash with all the gene objects
  attr_accessor :go_annotations #attribute that will contain the KEGG annotations
  attr_accessor :kegg_annotations #attribute that will contain the GO annotations
  require 'rest-client'
  require 'json'
  
  def initialize(params = {}) #the values of the properties that the new object Interaction Network will have
    @gene_original = params.fetch(:gene_original, nil) 
    @all_genes = params.fetch(:all_genes, Hash.new)
    @network = Array.new
    recursive_function(@gene_original) #applies the recursive function to obtain the network members
    @go_annotations = Hash.new
    @kegg_annotations = Hash.new
    obtain_kegg_network #applies the recursive function to obtain the KEGG annotations of the original genes involved in the network
    obtain_go_network #applies the recursive function to obtain the GO annotations of the original genes involved in the network
    @network = @network.sort_by{|obj| obj.agi_locus} #order the genes objects in the network by the AGI locus. 
  end
      
  
  def recursive_function(gene_obj) #Recursive function that will look for the members of a network. 
    if @network.include? (gene_obj) #if the network already contains the gene object, end the function. 
        return    
    end         
    @network << gene_obj #store the Gene object in the attribute network (an array)
    gene_obj.interactions.each {|gene_int| #for each interaction (gen)
        if @all_genes.has_key? (gene_int.downcase) #if that gen is a key pf the hash with the gene objects:
            int_obj = @all_genes[gene_int.downcase] #store that object in a variable           
            recursive_function(int_obj) #apply the function again
     
        end}               
     
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
  
  
  
  def obtain_kegg_network #Function that store all the KEGG annotations of the original genes of the network.
    @network.each{|gene_id| #for each gene object of the network
      if gene_id.level.to_i == 1  #if the gene is a original gene (level 1)
        result_kegg_pathways = fetch("http://togows.org/entry/kegg-genes/ath:#{gene_id.agi_locus}/pathways.json")#search for the KEGG annotations by the AGI locus. 
        kegg_pathways_json = JSON.parse(result_kegg_pathways) #transform the results into a JSON format
        if kegg_pathways_json == [] #if that gene hasn't KEGG annotations, skip to the next gene.
            next
        end
        kegg_pathways_gene = kegg_pathways_json[0] #store the array that contains the KEGG annotations 
        kegg_pathways_gene.each {|key,value| unless @kegg_annotations.has_key?(key) #store the hash with the KEGG ID and the patways' name unless the hash has already that KEGG key. 
            @kegg_annotations[key] = value #The key is the KEGG ID and the value is the KEGG pathway name.
        end}
      else
         next
      end}
  end
  
  def obtain_go_network #Function that store all the GO annotations of the original genes of the network.
    @network.each{|gene_id|#for each gene object of the network
    if gene_id.level.to_i == 1 #if the gene is a original gene (level 1)
      result_go_pathways = fetch("http://togows.org/entry/ebi-uniprot/#{gene_id.agi_locus}/dr.json")#search for the GO annotations by the AGI locus. 
      go_pathways_json = JSON.parse(result_go_pathways) #transform the results into a JSON format
      if go_pathways_json.empty? #if that gene does not have GO annotations, skip. 
         next
      else
         #select only the biological process of the GO annotations:
         go_biological_process = go_pathways_json[0]["GO"].select!{|array| array.any?{|element| element =~ /P:/}} #select only those arrays that contain the biological processes
         go_biological_process.each{|result| @go_annotations[result[0]] = result[1]} #the key will be the GO ID and the values will be the GO pathways. 
      end
    else
      next 
    end}
  end
    
end