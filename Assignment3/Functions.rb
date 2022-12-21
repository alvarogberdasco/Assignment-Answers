require 'bio'
require 'rest-client'
require 'csv'


# Function to access the web.
#
# @note Function donated by Mark Wilkinson.
# @note Requires the rest-client ruby gem.
# @author Mark_Wilkinson.
# @param [String] url the URL of the page to download.
# @param [Hash] headers the headers of the web accession if needed.
# @param [String] user the username if so requires the web accession.
# @param [String] pass the password if so requires the web accession.
# @return [Boolean] false if the web accession failed.
# @return [RestClient::Response] response from the web accession if it succeded.
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
      return response  
    rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  
    rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  
end
  
  
# Function to get information about the genes of a file from the embl database.
#
# @note Requires the bio ruby gem to work.
# @param [File] file File with the list of genes to be retrieved from the embl database.
# @return [nil] if it is impossible to get gene information.
# @return [Hash] genes Hash of Bio::EMBL objects if there is at least 
#   one gene in the file with available information on embl.
def get_gene_info(file)  
    genes = {}
    File.foreach(file) do |line|
      line = line.strip
      res = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{line}")
      unless res
        $stderr.puts "There is no embl information for gene #{line}"
        next
      end
      embl = Bio::EMBL.new(res.body)
      genes[line.to_sym] = embl unless embl.seq.nil?
    end
    return genes
end
  
# Function to get the cctcct positions of a gene. Loops through all the exon features of a
#   Bio::EMBL object and retrieves the positions of the cttctt sequences.
#
# @param [String] id of the gene.
# @param [Bio::EMBL] embl Bio::EMBL object containing the information about that gene.
# @param [Array] no_ctt Array with genes without target sequence.
# @param [Integer] pos Position of the gene.
# @return [nil] if no match was found in the exon feature.
# @return [Array] positions_of_gene if at least one match was found in the exon feature,
#   array containing all the positions of each cctcct. 
def search_target(id, embl, no_ctt, pos=1)
    target = /cttctt/ # Regular expression for the cttctt sequence
    target_regexp = /(?=(cttctt))/ # https://stackoverflow.com/questions/10237474/regular-expressions-with-lookahead-in-ruby
    positions_of_gene = []
    embl.features do |feat|
      next unless feat.feature == "exon" # skip if it is not an exon
      
      location = feat.locations.locations[0]
      temp_location = feat.position    
      seq = embl.naseq.splice(temp_location)
      next if seq.empty?
      if target.match(seq)
        repeats = []
        seq.scan(target_regexp) do
          repeats << [Regexp.last_match.offset(0).first + 1, Regexp.last_match.offset(0).first + 6]
        end
        exon_location = /(?<start>\d+)..(?<end>\d+)/.match(temp_location)
        repeat_positions = []
        
        repeats.each do |repeat|
          if location.strand == 1
            start = exon_location['start'].to_i + repeat[0] - 1 + pos - 1
            stop = exon_location['start'].to_i + repeat[1] - 1 + pos - 1
            repeat_pos = [start,stop]
          elsif location.strand == -1
            start = exon_loc['end'].to_i - (repeat[1] - 1) + pos - 1
            stop = exon_loc['end'].to_i - (repeat[0] - 1) + pos - 1
            repeat_pos = [start,stop]
     
          end
          
          repeat_positions |= [repeat_pos]
        end
        positions_of_gene |= repeat_positions
        
      end
    end
    if positions_of_gene.empty?
      no_ctt.push(id)
    end
    return positions_of_gene unless positions_of_gene.empty?
end
  
# Function to create the Bio::Feature objects of the cttctt repeats of a given gene.
#
# @note Requires the bio ruby gem.
# @param [Hash] position Hash with gene ids and their cttctt coordinates.
# @param [CSV] output File with the annotated features in gff3 format.
# @return [Array] features_list array of new Bio::Feature objects of the cttctt repeats.
def annotate_features(position, output)
    features = [] 
    position.each do |key, value|
      count = 1
      value.each do |pos|
        feat = Bio::Feature.new('CTTCTT', "#{pos[0]}..#{pos[1]}")
        feat.append(Bio::Feature::Qualifier.new('repeat_sequence', 'cttctt'))
        feat.append(Bio::Feature::Qualifier.new('region', 'exon'))
        if pos[0].to_i > pos[1].to_i  # Checking the order of the positions (forward or reverse)
        feat.append(Bio::Feature::Qualifier.new('strand', '-'))
          strand = '-'
        else
          feat.append(Bio::Feature::Qualifier.new('strand', '+'))
          strand = '+'
        end      
        CSV.open("#{output}", 'a',col_sep: "\t", headers: true) do |tsv|
          tsv << [key, 'region_CTTCTT', 'exon', pos[0], pos[1], '.', strand, '.', "ID= #{key}.#{count}"]
        end
        count += 1  # To change ID number
        features |= [feat]      
      end
    end
    return features
end