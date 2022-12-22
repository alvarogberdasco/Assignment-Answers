require './Functions.rb'

filename = ARGV[0]



if ARGV.length != 1 #https://code-mven.com/argv-the-command-line-arguments-in-ruby
  warn 'Wrong number of arguments.'
  puts 'To run the program: ruby main.rb file'
  abort
end

genes = get_gene_info(filename)
puts "Total number of retrieved genes: #{genes.length}"


has_ctt = {}
has_no_ctt = []

genes.each do |id, embl| # id is the gene id and embl the embl gene object.
  pos_temp = search_target(id, embl, has_no_ctt)
  if pos_temp
    has_ctt[id] = pos_temp
  end
end

puts 'Creating no_ctt_genes.txt with not-matching genes...'
no_ctt_file = File.open('./no_ctt_genes.txt','w')
no_ctt_file.puts "Genes that don't have cttctt sequence: #{has_no_ctt.length}"
no_ctt_file.puts has_no_ctt

puts "Creating final_gene_features.gff3 with genes' features..."
annotate_features(has_ctt, 'final_gene_features.gff3')