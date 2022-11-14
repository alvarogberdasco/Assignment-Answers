require "./Gene.rb"
require "./SeedStock.rb"
require "./HybridCross.rb"

require "csv"

CSV.foreach("gene_information.tsv", col_sep: "\t") do |line| #https://linuxtut.com/how-to-handle-tsv-files-and-csv-files-in-ruby-b8798/
  gene = Gene.new(:id => line[0], :name => line[1], :mutant_phenotype => line[2])
  
end

CSV.foreach("seed_stock_data.tsv", col_sep: "\t") do |line| 

  seed = Seed.new(:seed_stock => line[0], :mutant_gene_id => line[1], 
    :last_planted => line[2], :storage => line[3], :grams_remaining => line[4]) 

end 


CSV.foreach("cross_data.tsv", col_sep: "\t") do |line|
  cross = Cross.new(:parent1 => line[0], :parent2 => line[1],
    :f2_Wild => line[2].to_i, :f2_P1 => line[3].to_i, 
    :f2_P2 => line[4].to_i, :f2_P1P2 => line[5].to_i)
  
end 

puts 'We will plant 7g of each seed variety:'
puts

Seed.get_list.drop(1).each do |p| #https://stackoverflow.com/questions/3615700/ruby-what-is-the-easiest-way-to-remove-the-first-element-from-an-array
  p.plant(7)
end

puts
puts 'The new state of the seed stock is:'
puts File.open("new_seed_stock.tsv").read
puts

Cross.get_list.drop(1).each do |c|
  c.chi_sq
end



