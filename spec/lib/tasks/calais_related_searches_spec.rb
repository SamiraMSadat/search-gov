require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "rake"

describe "Calais related searches rake tasks" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require "lib/tasks/calais_related_searches"
    Rake::Task.define_task(:environment)
  end

  describe "usasearch:calais_related_searches" do

    describe "usasearch:calais_related_searches:compute" do
      before do
        @task_name = "usasearch:calais_related_searches:compute"
      end

      it "should have 'environment' as a prereq" do
        @rake[@task_name].prerequisites.should include("environment")
      end

      it "should create/update related searches based on yesterday's popular search terms" do
        CalaisRelatedSearch.should_receive(:populate_with_new_popular_terms)
        @rake[@task_name].invoke
      end
    end

  end
end