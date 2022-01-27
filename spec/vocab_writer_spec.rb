require_relative 'spec_helper'
require 'rdf/turtle'
require 'rdf/vocab/writer'
describe RDF::Vocabulary::Writer do
  after(:each) do
    Object.send(:remove_const, :Foo)
  end
  let!(:ttl) {%{
    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
    <http://example.org/Class> a rdfs:Class ; rdfs:Datatype "Class" .
    <http://example.org/prop> a rdf:Property ; rdfs:Datatype "prop" .
  }}
  let!(:graph) {
    RDF::Graph.new << RDF::Turtle::Reader.new(ttl)
  }
  let!(:serialization) {RDF::Vocabulary::Writer.buffer(class_name: "Foo", module_name: "Bar", base_uri: "http://example.org/") {|w| w << graph}}

  [
    /module Bar/,
    /class Foo/,
    %r{term :Class,\s+"http://www.w3.org/2000/01/rdf-schema#Datatype": "Class".freeze,\s+type: "http://www.w3.org/2000/01/rdf-schema#Class"}m.freeze,
    %r{property :prop,\s+"http://www.w3.org/2000/01/rdf-schema#Datatype": "prop".freeze,\s+type: "http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"}m.freeze,
  ].each do |regexp,|
    it "matches #{regexp}" do
      expect(serialization).to match(regexp)
    end
  end

  context "Embedded Concept" do
    let!(:ttl) {%{
      @prefix jur: <http://sweet.jpl.nasa.gov/2.3/humanJurisdiction.owl#>.
      @prefix dce: <http://purl.org/dc/elements/1.1/>.
      @prefix dct: <http://purl.org/dc/terms/>.
      @prefix foaf: <http://xmlns.com/foaf/0.1/>.
      @prefix owl: <http://www.w3.org/2002/07/owl#>.
      @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
      @prefix skos: <http://www.w3.org/2004/02/skos/core#>.
      @prefix country: <http://eulersharp.sourceforge.net/2003/03swap/countries#>.
      country:af
      	a jur:Country;
      	rdfs:isDefinedBy <http://eulersharp.sourceforge.net/2003/03swap/countries#>;
      	skos:exactMatch [
      		a skos:Concept; skos:inScheme country:iso3166-1-alpha-2; skos:notation "af"^^country:iso3166-1-alpha-2DT], [
      		a skos:Concept; skos:inScheme country:iso3166-1-alpha-3; skos:notation "afg"^^country:iso3166-1-alpha-3DT];
      	foaf:name """Afghanistan"""@en.
    }}
    let!(:serialization) {RDF::Vocabulary::Writer.buffer(class_name: "Foo", module_name: "Bar", base_uri: "http://eulersharp.sourceforge.net/2003/03swap/countries#") {|w| w << graph}}

    [
      /module Bar/,
      /class Foo/,
      /term :af/,
      /exactMatch: \[term\(/,
      %r{type: "http://www.w3.org/2004/02/skos/core#Concept"}.freeze,
      /notation: %\(af\)/.freeze,
      %r{inScheme: "http://eulersharp.sourceforge.net/2003/03swap/countries#iso3166-1-alpha-2"}.freeze,
      /notation: %\(afg\)/.freeze,
      %r{inScheme: "http://eulersharp.sourceforge.net/2003/03swap/countries#iso3166-1-alpha-3"}.freeze,
      %r{"http://xmlns.com/foaf/0.1/name": "Afghanistan"}.freeze,
      %r{isDefinedBy: "http://eulersharp.sourceforge.net/2003/03swap/countries#"}.freeze,
      %r{type: "http://sweet.jpl.nasa.gov/2.3/humanJurisdiction.owl#Country"}.freeze,
    ].each do |regexp,|
      it "matches #{regexp}" do
        expect(serialization).to match(regexp)
      end
    end
  end

  context "owl:unionOf" do
    let!(:ttl) {%{
      @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
      @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
      @prefix owl: <http://www.w3.org/2002/07/owl#> .
      <http://example.org/ClassList> a rdfs:Class;
        rdfs:label "ClassList";
        rdfs:subClassOf [owl:unionOf (<http://example.org/C1> <http://example.org/C2>)] .
    }}
    let!(:serialization) {RDF::Vocabulary::Writer.buffer(class_name: "Foo", module_name: "Bar", base_uri: "http://example.org/") {|w| w << graph}}

    [
      /module Bar/,
      /class Foo/,
      /term :ClassList/,
      /label: "ClassList"/.freeze,
      /subClassOf: term\(/,
      %r{unionOf: list\("http://example.org/C1", "http://example.org/C2"\)},
      %r{type: "http://www.w3.org/2000/01/rdf-schema#Class"}.freeze,
    ].each do |regexp,|
      it "matches #{regexp}" do
        expect(serialization).to match(regexp)
      end
    end
  end
end
