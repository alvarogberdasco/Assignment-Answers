
require  'bio'
require 'stringio'


thaliana = ARGV[0]
pombe = ARGV[1]

#Creates the final report with the pairs of orthologues.
#@param [String] filename The name of the report
#@return [File] The final report
def create_report(filename)
  if File.exists?(filename)
    File.delete(filename)
  end
  return (File.open(filename, "w"))
end

final_report = create_report("orthologues.txt")
final_report.puts "List of putative orthologue pairs between Arabidopsis thaliana and Schizosaccharomyces pombe:\n"

#Creating the DataBase Folder and deleting the older one
#Creating the database using the command makeblastdb, calling it from ruby
system("rm -r Databases")
system("mkdir Databases")
system("makeblastdb -in '#{thaliana}' -dbtype 'nucl' -out ./Databases/#{thaliana}")
system("makeblastdb -in '#{pombe}' -dbtype 'prot' -out ./Databases/#{pombe}")


#Chosing the E-value threshold from
#Ward, N., & Moreno-hagelsieb, G. (2014). Quickly Finding Orthologs as Reciprocal Best Hits with BLAT , LAST , and UBLAST : How Much Do We Miss ?,
# 9(7), 1–6. https://doi.org/10.1371/journal.pone.0101850
e_value = 10**-6

#Creating an appropriate blast factory to perform a certain type of blast 
#on a database
factory1 = Bio::Blast.local('tblastn', "./Databases/#{thaliana}")
factory2 = Bio::Blast.local('blastx',"./Databases/#{pombe}")

#Creating fastaformat for reading sequence per sequence
fasta1 = Bio::FastaFormat.open(thaliana)
fasta2 = Bio::FastaFormat.open(pombe)
fasta_seqs = Hash.new
fasta1.each do |seq1|
  fasta_seqs[(seq1.entry_id).to_s] = (seq1.seq).to_s
end

#Iterating over each sequence in the search_file
count = 0
fasta2.each do |search_f2| 
  report = factory1.query(search_f2)
  if report.hits[0]
    if report.hits[0].evalue <= e_value
      search_id = (search_f2.entry_id).delete("\n").to_s

      id_f1= report.hits[0].definition.split("|")[0].delete(" ").to_s #Obteining the id of the match

      query_f1 = fasta_seqs[id_f1]

      report2 = factory2.query(query_f1)

      if report2.hits[0]
        id_f2 = report2.hits[0].definition.split("|")[0].delete(" ").to_s #Obtaining the id of the best match's best match

        if search_id == id_f2 #Checking whether or not the sequences are reciprocal best matches
            final_report.puts "#{id_f1}\s<-->\s#{id_f2}"
            count+=1
        end
      end
    end
  end
end

final_report.puts "Number of putative orthologues: #{count}"


