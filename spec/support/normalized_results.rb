# frozen_string_literal: true

shared_examples 'a search with normalized results' do
  let(:normalized_result_keys) { [:description, :url, :title] }

  it 'returns normalized results' do
    expect(normalized_results.length).to eq(5)

    normalized_results.each_with_index do |result, index|
      expect(result.keys).to contain_exactly(*normalized_result_keys)
      expect(result[:title]).to eq("title #{index}")
      expect(result[:description]).to eq("content #{index}")
      expect(result[:url]).to eq("http://foo.gov/#{index}")
    end
  end
end