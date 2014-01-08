# coding: utf-8
require 'spec_helper'

describe ElasticBoostedContent do
  fixtures :affiliates
  let(:affiliate) { affiliates(:basic_affiliate) }

  before do
    ElasticBoostedContent.recreate_index
    affiliate.boosted_contents.destroy_all
    affiliate.locale = 'en'
  end

  describe ".search_for" do
    describe "results structure" do
      context 'when there are results' do
        before do
          affiliate.boosted_contents.create!(title: 'Tropical Hurricane Names',
                                             description: 'This is a bunch of names',
                                             url: 'http://www.nhc.noaa.gov/aboutnames.shtml',
                                             status: 'active',
                                             publish_start_on: Date.current)
          affiliate.boosted_contents.create!(title: 'More Hurricane names involving tropical',
                                             description: 'This is a bunch of other names',
                                             url: 'http://www.nhc.noaa.gov/aboutnames1.shtml',
                                             status: 'active',
                                             publish_start_on: Date.current)
          ElasticBoostedContent.commit
        end

        it 'should return results in an easy to access structure' do
          search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, size: 1, offset: 1, language: affiliate.locale)
          search.total.should == 2
          search.results.size.should == 1
          search.results.first.should be_instance_of(BoostedContent)
          search.offset.should == 1
        end

        context 'when those results get deleted' do
          before do
            affiliate.boosted_contents.destroy_all
            ElasticBoostedContent.commit
          end

          it 'should return zero results' do
            search = ElasticBoostedContent.search_for(q: 'hurricane', affiliate_id: affiliate.id, size: 1, offset: 1, language: affiliate.locale)
            search.total.should be_zero
            search.results.size.should be_zero
          end
        end
      end

    end
  end

  describe "highlighting results" do
    before do
      affiliate.boosted_contents.create!(title: 'Tropical Hurricane Names',
                                         status: 'active',
                                         description: 'Worldwide Tropical Cyclone Names',
                                         url: 'http://www.nhc.noaa.gov/aboutnames.shtml',
                                         publish_start_on: Date.current)
      ElasticBoostedContent.commit
    end

    context 'when no highlight param is sent in' do
      it 'should highlight appropriate fields with <strong> by default' do
        search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, language: affiliate.locale)
        first = search.results.first
        first.title.should == "<strong>Tropical</strong> Hurricane Names"
        first.description.should == "Worldwide <strong>Tropical</strong> Cyclone Names"
      end
    end

    context 'when field has HTML entity like an ampersand' do
      before do
        affiliate.boosted_contents.create!(title: 'Peas & Carrots',
                                           status: 'active',
                                           description: 'html entities',
                                           url: 'http://www.nhc.noaa.gov/peas.shtml',
                                           publish_start_on: Date.current)
        ElasticBoostedContent.commit
      end

      it 'should escape the entity but show the highlight' do
        search = ElasticBoostedContent.search_for(q: 'carrot', affiliate_id: affiliate.id, language: affiliate.locale)
        first = search.results.first
        first.title.should == "Peas &amp; <strong>Carrots</strong>"
        search = ElasticBoostedContent.search_for(q: 'entities', affiliate_id: affiliate.id, language: affiliate.locale)
        first = search.results.first
        first.title.should == "Peas &amp; Carrots"
      end
    end

    context 'when highlight is turned off' do
      it 'should not highlight matches' do
        search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, language: affiliate.locale, highlighting: false)
        first = search.results.first
        first.title.should == "Tropical Hurricane Names"
        first.description.should == "Worldwide Tropical Cyclone Names"
      end
    end

    context 'when title is really long' do
      before do
        long_title = "President Obama overcame furious lobbying by big banks to pass Dodd-Frank Wall Street Reform, to prevent the excessive risk-taking that led to a financial crisis while providing protections to American families for their mortgages and credit cards."
        affiliate.boosted_contents.create!(title: long_title,
                                           status: 'active',
                                           description: 'Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/long.shtml',
                                           publish_start_on: Date.current)
        ElasticBoostedContent.commit
      end

      it 'should show everything in a single fragment' do
        search = ElasticBoostedContent.search_for(q: 'president credit cards', affiliate_id: affiliate.id, language: affiliate.locale)
        first = search.results.first
        first.title.should == "<strong>President</strong> Obama overcame furious lobbying by big banks to pass Dodd-Frank Wall Street Reform, to prevent the excessive risk-taking that led to a financial crisis while providing protections to American families for their mortgages and <strong>credit</strong> <strong>cards</strong>."
      end
    end
  end

  describe "filters" do
    context "when there are active and inactive boosted contents" do
      before do
        affiliate.boosted_contents.create!(title: 'Tropical Hurricane Names',
                                           status: 'active',
                                           description: 'Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/active.shtml',
                                           publish_start_on: Date.current)
        affiliate.boosted_contents.create!(title: 'Retired Tropical Hurricane names',
                                           status: 'inactive',
                                           description: 'Retired Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/inactive.shtml',
                                           publish_start_on: Date.current)
        ElasticBoostedContent.commit
      end

      it "should return only active boosted contents" do
        search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, size: 2, language: affiliate.locale)
        search.total.should == 1
        search.results.first.is_active?.should be_true
      end
    end

    context 'when there are matches across affiliates' do
      let(:other_affiliate) { affiliates(:power_affiliate) }

      before do
        other_affiliate.locale = 'en'
        values = { title: 'Tropical Hurricane Names',
                   status: 'active',
                   description: 'Worldwide Tropical Cyclone Names',
                   url: 'http://www.nhc.noaa.gov/other.shtml',
                   publish_start_on: Date.current }
        affiliate.boosted_contents.create!(values)
        other_affiliate.boosted_contents.create!(values)

        ElasticBoostedContent.commit
      end

      it "should return only matches for the given affiliate" do
        search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, language: affiliate.locale)
        search.total.should == 1
        search.results.first.affiliate.name.should == affiliate.name
      end
    end

    context 'when publish_start_on date has not been reached' do
      before do
        affiliate.boosted_contents.create!(title: 'Current Tropical Hurricane Names',
                                           status: 'active',
                                           description: 'Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/current.shtml',
                                           publish_start_on: Date.current)
        affiliate.boosted_contents.create!(title: 'Future Tropical Hurricane names',
                                           status: 'active',
                                           description: 'Tomorrow Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/tomorrow.shtml',
                                           publish_start_on: Date.tomorrow)
        ElasticBoostedContent.commit
      end

      it 'should omit those results' do
        search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, size: 2, language: affiliate.locale)
        search.total.should == 1
        search.results.first.title.should =~ /^Current/
      end
    end

    context 'when publish_end_on date has been reached' do
      before do
        affiliate.boosted_contents.create!(title: 'Current Tropical Hurricane Names',
                                           status: 'active',
                                           description: 'Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/current.shtml',
                                           publish_start_on: Date.current)
        affiliate.boosted_contents.create!(title: 'Future Tropical Hurricane names',
                                           status: 'active',
                                           description: 'Tomorrow Worldwide Tropical Cyclone Names',
                                           url: 'http://www.nhc.noaa.gov/tomorrow.shtml',
                                           publish_start_on: 1.week.ago.to_date,
                                           publish_end_on: Date.current)
        ElasticBoostedContent.commit
      end

      it 'should omit those results' do
        search = ElasticBoostedContent.search_for(q: 'Tropical', affiliate_id: affiliate.id, size: 2, language: affiliate.locale)
        search.total.should == 1
        search.results.first.title.should =~ /^Current/
      end
    end
  end

  describe "recall" do
    before do
      boosted_content = affiliate.boosted_contents.build(title: 'Obamå and Bideñ',
                                                         status: 'active',
                                                         description: 'Yosemite publications spelling',
                                                         url: 'http://www.nhc.noaa.gov/aboutnames.shtml',
                                                         publish_start_on: Date.current)
      boosted_content.boosted_content_keywords.build(value: 'Corazón')
      boosted_content.boosted_content_keywords.build(value: 'fair pay act')
      boosted_content.save!
      ElasticBoostedContent.commit
    end

    describe 'keywords' do
      it 'should be case insensitive' do
        ElasticBoostedContent.search_for(q: 'cORAzon', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
      end

      it 'should perform ASCII folding' do
        ElasticBoostedContent.search_for(q: 'coràzon', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
      end

      it 'should only match full keyword phrase' do
        ElasticBoostedContent.search_for(q: 'fair pay act', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
        ElasticBoostedContent.search_for(q: 'fair pay', affiliate_id: affiliate.id, language: affiliate.locale).total.should be_zero
      end
    end

    describe "misspellings and fuzzy matches" do
      it 'should return results for slight misspellings after the first two characters' do
        oops = %w{yossemite yosemity speling publicaciones}
        oops.each do |misspeling|
          ElasticBoostedContent.search_for(q: misspeling, affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
        end
      end
    end

    describe "title and description" do
      it 'should be case insentitive' do
        ElasticBoostedContent.search_for(q: 'OBAMA', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
        ElasticBoostedContent.search_for(q: 'BIDEN', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
      end

      it 'should perform ASCII folding' do
        ElasticBoostedContent.search_for(q: 'øbåmà', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
        ElasticBoostedContent.search_for(q: 'bîdéÑ', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
      end

      context "when query contains problem characters" do
        ['"   ', '   "       ', '+++', '+-', '-+'].each do |query|
          specify { ElasticBoostedContent.search_for(q: query, affiliate_id: affiliate.id, language: affiliate.locale).total.should be_zero }
        end

        %w(+++obama --obama +-obama).each do |query|
          specify { ElasticBoostedContent.search_for(q: query, affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1 }
        end
      end

      context 'when affiliate is English' do
        before do
          affiliate.boosted_contents.create!(title: 'The affiliate interns use powerful engineering computers',
                                             status: 'active',
                                             description: 'Organic feet symbolize with oceanic views',
                                             url: 'http://www.nhc.noaa.gov/aboutnames2.shtml',
                                             publish_start_on: Date.current)
          ElasticBoostedContent.commit
        end

        it 'should do minimal English stemming with basic stopwords' do
          appropriate_stemming = ['The computer with an intern and affiliates', 'Organics symbolizes a the view']
          appropriate_stemming.each do |query|
            ElasticBoostedContent.search_for(q: query, affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
          end
          overstemmed_queries = %w{internal internship symbolic ocean organ computing powered engine}
          overstemmed_queries.each do |query|
            ElasticBoostedContent.search_for(q: query, affiliate_id: affiliate.id, language: affiliate.locale).total.should be_zero
          end
        end
      end

      context 'when affiliate is Spanish' do
        before do
          affiliate.locale = 'es'
          affiliate.boosted_contents.create!(title: 'Leyes y el rey',
                                             status: 'active',
                                             description: 'Beneficios y ayuda financiera verificación Lotería de visas 2015',
                                             url: 'http://www.nhc.noaa.gov/aboutnames2.shtml',
                                             publish_start_on: Date.current)
          ElasticBoostedContent.commit
        end

        it 'should do minimal Spanish stemming with basic stopwords' do
          appropriate_stemming = ['ley con reyes', 'financieros']
          appropriate_stemming.each do |query|
            ElasticBoostedContent.search_for(q: query, affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
          end
          overstemmed_queries = %w{verificar finanzas}
          overstemmed_queries.each do |query|
            ElasticBoostedContent.search_for(q: query, affiliate_id: affiliate.id, language: affiliate.locale).total.should be_zero
          end
        end

        it 'should handle custom synonyms' do
          ElasticBoostedContent.search_for(q: 'visa', affiliate_id: affiliate.id, language: affiliate.locale).total.should == 1
        end
      end
    end

  end

  context "when searching raises an exception" do
    it "should return nil" do
      ES::client.should_receive(:search).and_raise StandardError
      ElasticBoostedContent.search_for(q: 'query', affiliate_id: affiliate.id, language: affiliate.locale).should be_nil
    end
  end

end