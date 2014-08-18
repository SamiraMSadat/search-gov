# coding: utf-8
require 'spec_helper'

describe "image_searches/index.mobile.haml" do
  fixtures :affiliates, :image_search_labels, :navigations
  let(:affiliate) { affiliates(:usagov_affiliate) }

  context "when there are 5 Oasis pics and Bing image search is not enabled" do
    before do
      affiliate.is_bing_image_search_enabled = false
      assign(:affiliate, affiliate)
      results = (1..5).map do |i|
        Hashie::Rash.new(title: "title #{i}", url: "http://flickr/#{i}", display_url: "http://flickr/#{i}",
                         thumbnail: { url: "http://flickr/thumbnail/#{i}" })
      end
      results.stub(:total_pages).and_return(1)
      @search = double(ImageSearch, query: "test", affiliate: affiliate, module_tag: 'OASIS',
                       queried_at_seconds: 1271978870, results: results, startrecord: 1, total: 5, per_page: 20, page: 1)
      assign(:search, @search)
      assign(:search_params, { affiliate: affiliate.name, query: 'test' })
    end

    it "should show 5 Oasis pics" do
      selector = '#results .result.image'
      render
      rendered.should have_selector(selector, count: 5)
    end

    it "should be Powered by DIGITALGOV Search" do
      render
      rendered.should contain("Powered by DIGITALGOV Search")
    end
  end

  context "when there are 20 Oasis pics and Bing image search is enabled" do
    before do
      affiliate.is_bing_image_search_enabled = true
      assign(:affiliate, affiliate)
      results = (1..20).map do |i|
        Hashie::Rash.new(title: "title #{i}", url: "http://flickr/#{i}", display_url: "http://flickr/#{i}",
                         thumbnail: { url: "http://flickr/thumbnail/#{i}" })
      end
      results.stub(:total_pages).and_return(1)
      @search = double(ImageSearch, query: "test", affiliate: affiliate, module_tag: 'OASIS',
                       queried_at_seconds: 1271978870, results: results, startrecord: 1, total: 20, per_page: 20, page: 1)
      ImageSearch.stub(:===).and_return true
      assign(:search, @search)
      assign(:search_params, { affiliate: affiliate.name, query: 'test' })
    end

    it "should show 20 Oasis pics" do
      selector = '#results .result.image'
      render
      rendered.should have_selector(selector, count: 20)
    end

    it "should be Powered by DIGITALGOV Search" do
      render
      rendered.should contain("Powered by DIGITALGOV Search")
    end

    it "should have a link to retry search with Bing" do
      content = "Try your search again"
      render
      rendered.should have_selector(:a, content: content, href: '/search/images?affiliate=usagov&cr=true&query=test')
    end
  end

  context "when there are no Oasis pics and Bing image search is not enabled" do
    before do
      affiliate.is_bing_image_search_enabled = false
      assign(:affiliate, affiliate)
      @search = double(ImageSearch, query: "test", affiliate: affiliate, error_message: nil, module_tag: nil,
                       queried_at_seconds: 1271978870, results: [], startrecord: 0, total: 0, per_page: 20, page: 0)
      assign(:search, @search)
      assign(:search_params, { affiliate: affiliate.name, query: 'test' })
    end

    it "should say no results found" do
      render
      rendered.should contain("no results found")
    end
  end

  context "when there are no Oasis results and Bing image search is enabled" do
    before do
      affiliate.is_bing_image_search_enabled = true
      assign(:affiliate, affiliate)
      results = (1..20).map do |i|
        Hashie::Rash.new(title: "title #{i}", url: "http://bing/#{i}", display_url: "http://bing/#{i}",
                         thumbnail: { url: "http://bing/thumbnail/#{i}" })
      end
      results.stub(:total_pages).and_return(1)
      @search = double(ImageSearch, query: "test", affiliate: affiliate, module_tag: 'IMAG',
                       queried_at_seconds: 1271978870, results: results, startrecord: 1, total: 20, per_page: 20, page: 1)
      @search.stub(:is_a?).with(ImageSearch).and_return true
      ImageSearch.stub(:===).and_return true
      assign(:search, @search)
      assign(:search_params, { affiliate: affiliate.name, query: 'test' })
    end

    it "should show 20 Bing pics" do
      selector = '#results .result.image'
      render
      rendered.should have_selector(selector, count: 20)
    end

    it "should be Powered by Bing" do
      render
      rendered.should contain("Powered by Bing")
    end

  end

end