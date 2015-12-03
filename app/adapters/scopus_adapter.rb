class ScopusAdapter
  attr_accessor :id, :title, :alt_title, :abstract, :keywords, :pubyear, :language, :issn, :eissn, :sourcetitle, :sourcevolume, :sourceissue, :sourcepages, :author, :doi_url, :extid, :xml, :datasource, :sourceid, :publication_identifiers
  
  # TODO: Proper types for Scopus needed
  PUBLICATION_TYPES = {
    "journal" => "journal-articles",
    "conferenceproceeding" => "conference-papers"
  }

  include ActiveModel::Serialization
  include ActiveModel::Validations

  DOI_URL_PREFIX = 'http://dx.doi.org/'
  APIKEY = APP_CONFIG['datasource_api_keys']['scopus']


  def initialize hash
    @doi = hash[:doi]
    @xml = hash[:xml]
    parse_xml
  end

  def self.authors(xml)
    authors = []
    sequences = []
    xml.search('//entry/author').map do |author|
      sequence = author.attr('seq')
      next if sequences.include? sequence # Omit author if it is a duplication

      first_name = author.search('given-name').text
      last_name = author.search('surname').text
      full_author = author.search('authname').text
      authors << {
        first_name: first_name,
        last_name: last_name,
        full_author_string: full_author
      }
      sequences << sequence
    end
    authors
  end
 
  # Try to match publication type from xml data into GUP type
  def self.publication_type_suggestion(xml)
    original_pubtype = xml.search('//feed/entry/aggregationType').text
    original_pubtype = original_pubtype.downcase.gsub(/[^a-z]/,'')
    if PUBLICATION_TYPES[original_pubtype].nil?
      puts "No suggestion found for type: #{original_pubtype} id: #{id}"
    end
    return PUBLICATION_TYPES[original_pubtype]
  end

  def parse_xml
    @xml = force_utf8(@xml)

    xml = Nokogiri::XML(@xml).remove_namespaces!
    
    if xml.search('//feed/entry/error').text.present?
      error_msg = xml.search('//feed/entry/error').text
      puts "Error in ScopusAdapter: #{error_msg}"
      errors.add(:generic, "Error in ScopusAdapter: #{error_msg}")
      return
    end  

    if !xml.search('//feed/entry/title').text.present?
      puts "Error in ScopusAdapter: No content"
      errors.add(:generic, "Error in ScopusAdapter: No content")
      return 
    end  

    @pubyear = ""
    if xml.search('//entry/coverDate').text.present?
      @pubyear = xml.search('//entry/coverDate').text.byteslice(0..3)
    end

    @abstract = xml.search('//entry/description').text

    @keywords = "" 
    if xml.search('//entry/authkeywords').text.present?
      @keywords = xml.search('//entry/authkeywords').text.split(' | ').join(', ')
    end

    # Take care of author ids TBD...

    #@author = xml.search('//entry/author/authname').map do |author|
    #  [author.text]
    #end.join("; ")


    @title = xml.search('//entry/title').text
    @issn = xml.search('//entry/issn').text
    @eissn = xml.search('//entry/eIssn').text    
    @sourcetitle = xml.search('//entry/publicationName').text
    @sourcevolume = xml.search('//entry/volume').text
    @sourcepages =xml.search('//entry/pageRange').text

    @extid = xml.search('//entry/identifier').text
    @doi_url = DOI_URL_PREFIX + xml.search('//entry/doi').text

    # Parse publication_identifiers
    @publication_identifiers = []
    ## Parse DOI
    doi_value = xml.search('//entry/doi').text
    if doi_value.present?
      @publication_identifiers << {
        identifier_value: doi_value,
        identifier_code: 'doi'
      }
    end

    ## Parse Scopus-ID
    scopus_value = xml.search('//entry/identifier').text
    if scopus_value.present? && (scopus_value.include? ("SCOPUS_ID:"))
      scopus_value.slice! ("SCOPUS_ID:")
      @publication_identifiers << {
        identifier_value: scopus_value,
        identifier_code: 'scopus-id'
      }

    end
  end

  def self.find id

    headers = {"X-ELS-APIKey" => APIKEY, "X-ELS-ResourceVersion" => "XOCS", "Accept" => "application/atom+xml"}
    response = RestClient.get "http://api.elsevier.com/content/search/index:SCOPUS?count=1&start=0&view=COMPLETE&query=DOI(#{id})", headers

    #puts response
    #puts response.code
    self.new doi:id, xml: response
  end

  def self.find_by_id id
    self.find id
  rescue => error
    puts "Error in ScopusAdapter: #{error}"
    return nil  
  end
private
  def force_utf8(str)
    if !str.force_encoding("UTF-8").valid_encoding?
      str = str.force_encoding("ISO-8859-1").encode("UTF-8")
    end
    return str
  end
end

