class OaiDocuments
  class DC
    def self.create_record publication
      xml = ::Builder::XmlMarkup.new
      xml.tag!("oai_dc:dc", 
               'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/", 
               'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
               'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
               'xsi:schemaLocation' => %{http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd}) do
        publication.current_version.get_authors_full_name.each do |author| 
          xml.tag!('oai_dc:creator', author.strip)
        end unless !publication.current_version.get_authors_full_name
        
        xml.tag!('oai_dc:date', publication.current_version.pubyear) unless !publication.current_version.pubyear
        
        xml.tag!('oai_dc:description', publication.current_version.abstract.strip) unless !publication.current_version.abstract
        
        xml.tag!('oai_dc:identifier', get_uri_identifier(publication.id))

        if is_monography?(publication.current_version.publication_type)
          xml.tag!('oai_dc:identifier', publication.current_version.isbn.strip) unless !publication.current_version.isbn
        end      
        # TODO: Normalize language values
        xml.tag!('oai_dc:language', publication.current_version.publanguage.strip) unless !publication.current_version.publanguage
        
        xml.tag!('oai_dc:publisher', publication.current_version.publisher.strip + (publication.current_version.place ? ', ' + publication.current_version.place.strip : '')) unless !publication.current_version.publisher
        
        if !is_monography?(publication.current_version.publication_type)
          xml.tag!('oai_dc:relation', publication.current_version.isbn.strip) unless !publication.current_version.isbn
        end

        if !is_monography?(publication.current_version.publication_type)
          xml.tag!('oai_dc:relation', publication.current_version.sourcetitle.strip + (publication.current_version.sourcevolume ? ', ' + publication.current_version.sourcevolume.strip : '') + (publication.current_version.sourceissue ? ' (' + publication.current_version.sourceissue.strip + ')' : '') + (publication.current_version.sourcepages ? ', ' + publication.current_version.sourcepages.strip : '')) unless !publication.current_version.sourcetitle
        end

        xml.tag!('oai_dc:relation', publication.current_version.issn.strip) unless !publication.current_version.issn
        xml.tag!('oai_dc:relation', publication.current_version.eissn.strip) unless !publication.current_version.eissn

        if publication.current_version.series && publication.current_version.series.first && publication.current_version.series.first.title
          publication.current_version.series2publications.each do |s2p|
            xml.tag!('oai_dc:relation', s2p.serie.title.strip + (s2p.serie.issn ? ' (' + s2p.serie.issn.strip + ')' : '') + (s2p.serie_part ? ', ' + s2p.serie_part.strip : ''))
          end
        end
        
        publication.current_version.keywords.split(",").each do |keyword| 
          xml.tag!('oai_dc:subject', keyword.strip)
        end unless !publication.current_version.keywords

        publication.current_version.categories.each do |category|
          xml.tag!('oai_dc:subject', category.sv_name_path + '|' + category.name_sv)
          xml.tag!('oai_dc:subject', category.en_name_path + '|' + category.name_en)
        end unless !publication.current_version.categories
        
        xml.tag!('oai_dc:title', publication.current_version.title.strip + (publication.current_version.alt_title ? ' - ' + publication.current_version.alt_title.strip : '')) unless !publication.current_version.title
        
        # TODO: Normalize and standardize publication type values
        xml.tag!('oai_dc:type', publication.current_version.publication_type.code.strip) unless (!publication.current_version.publication_type || !publication.current_version.publication_type.code)
      end
      xml.target!
    end


    def self.get_uri_identifier id
      APP_CONFIG['public_base_url'] + APP_CONFIG['publication_path'] + id.to_s
    end

    def self.is_monography? publication_type
      monographs.include?(publication_type)
    end

    def self.monographs
      ['publication_book',
       'publication_edited-book',
       'publication_report',
       'publication_doctoral-thesis',
       'publication_licenciate-thesis']
    end


  end
end
