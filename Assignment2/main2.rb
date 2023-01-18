require 'rest-client'
require './gene.rb'
require './network.rb'

file = ARGV[0] #save the file in a variable.


#Function that saves the genes of the list in an array:
def read_file_genes(file)
  genes_list = Array.new
  lines = IO.readlines(file)
  lines.each {|gene| genes_list << gene.chomp}
  
return genes_list
end


#Obtaining the interaction network for the genes in the list
genes_list = read_file_genes(file).sort #array that contains the lines of the file
hash_interactions = Hash.new #hash that will contain the genes objects

#each value of the hash is a Gene object that corresponds with a gene from the original list 
genes_list.each {|gene| 
hash_interactions["#{gene.downcase}"] = Gene.new(:agi_locus => "#{gene.downcase}",:level => 1)} 

#Storing the new genes (Level 2) and looking for interactions
genes_list2 = Array.new() #array that will contain the genes of level 2 (which correspond with the genes that interact with the original genes)
hash_interactions.values.each {|gene_obj| gene_obj.interactions.each {|gene| genes_list2 << gene}} #store in the array the genes contained in the attribute interactions of genes level = 1.

#Storing in the hash the new genes as Gene Object:
genes_list2.each {|gene| 
hash_interactions["#{gene.downcase}"] = Gene.new(:agi_locus => "#{gene.downcase}",:level => 2)} 

#Storing the genes contained in the attribute interactions of genes level = 2
genes_list3 = Array.new()#array that will contain the genes of level 3 (which correspond with the genes that interact with genes of level 2)
hash_interactions.values[168..-1].each {|gene_obj| 
  if gene_obj.level == 2
    gene_obj.interactions.each {|gene| genes_list3 << gene}
  else
    next
  end}

#Storing the new genes in the hash
genes_list3.each {|gene|
   if hash_interactions.has_key?(gene) #if there is already a Gene object with the same AGI locus, skip to the next gene 
       next   
   else 
     hash_interactions["#{gene.downcase}"] = Gene.new(:agi_locus => "#{gene.downcase}",:level => 3)
   end} 


#Deleting genes without interactions
hash_interactions_updated = Hash.new #new hash that will contain only those genes that have interactions
hash_interactions.values.each{|gene_obj| #each value of the hash is a Gene object.
  if gene_obj.interactions.length < 1 #if that gene don't have any interactions, skip. 
    next
  end
  if gene_obj.level > 1 and gene_obj.interactions.length < 2 #if it is a gene from level 2 or 3 and have 0 or 1 interaction, skip.
    next
  end
  hash_interactions_updated[gene_obj.agi_locus] = gene_obj}#store the rest of the genes objects in the new hash. 


######### 2.2. SORTING THE HASH BY THE AGI_LOCUS (this will allows us after to compare the gene in networks in order to avoid networks with the same genes)
sorted_keys_hash = Array.new(hash_interactions_updated.keys.sort)
hash_updated_sorted = Hash.new

sorted_keys_hash.each{|key| hash_updated_sorted[key] = hash_interactions_updated[key]}

#Obtaining interaction networks with network class
list_of_networks = Array.new #array that contain will contain the networks found

hash_updated_sorted.values.each {|gene|                            
  if list_of_networks.any?{|int_network| int_network.network.any?{|int| int.agi_locus.to_s == gene.agi_locus.to_s}} #para no hacer redes repetidas
    next
  else
    network = InteractionNetwork.new(:gene_original => gene,:all_genes => hash_updated_sorted)                               
    list_of_networks << network
  end}

#Storing networks that have at least two file's genes
def remove_networks_no_functional(array_of_networks,new_list_networks)
  array_of_networks.each {|int_network_obj| int_network = int_network_obj.network #store the network (array) in a variable
    if int_network.count{|gene| gene.level.to_i == 1} < 2 #if there is less than two of the original genes in the network, skip to the another network.
       next
    else
       new_list_networks << int_network_obj #store the network in the new list 
    end}
  return new_list_networks
end

list_networks_updated = remove_networks_no_functional(list_of_networks,Array.new) #applies the function to the list of total networks obtained


#Creating report
report = File.open("report","w")

report << "#{list_networks_updated.length} networks have been found using a value of IntAct miscore of 0.45.\n"
list_networks_updated.each {|net| report << "\n\n\nNetwork: Contains #{net.network.length} genes\n"
   report << "The file's genes of this network are: \n"
   net.network.each{|gene|
    if gene.level.to_i == 1
      report << gene.agi_locus.upcase.to_s + "\n"
    end}
   report << "\n" + "The KEGG annotations of the original genes of this network are:\n\n"
   net.kegg_annotations.each {|key,value| report << "KEGG ID: " + key.to_s + "\t\t" + "Pathway name: " + value.to_s + "\n"}
   report << "\n\n" + "The GO annotations of the original genes of this network are:\n\n"
   net.go_annotations.each {|key,value| report << "GO ID: " + key.to_s + "\t\t" + "Pathway name: " + value.to_s + "\n"}}
  
report.close