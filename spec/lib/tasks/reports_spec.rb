require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "rake"

describe "Report generation rake tasks" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require "lib/tasks/reports"
    Rake::Task.define_task(:environment)
    Query.delete_all
    Query.create(:query => 'obama', :timestamp => Date.yesterday, :ipaddr => '1.2.3.4', :affiliate => Affiliate::USAGOV_AFFILIATE_NAME, :locale => 'en', :is_bot => false, :agent => 'Mozilla/5.0')
    @fake_top_queries = Query.top_queries(Date.yesterday.beginning_of_day, Date.yesterday.end_of_day)
    @fake_top_queries.size.should > 0
    @csv_output = "Query,Count\nobama,1\n"
    
    @affiliate_names = %w{affiliate1 affiliate2 affiliate3}
    File.open('/tmp/affiliates.out', 'w+') do |file|
      file.puts('name')
      @affiliate_names.each do |affiliate_name|
        file.puts(affiliate_name)
      end
    end
  end

  describe "usasearch:reports" do
    describe "usasearch:reports:generate_monthly_top_queries" do
      before do
        @task_name = "usasearch:reports:generate_monthly_top_queries"
        AWS::S3::Base.stub!(:establish_connection).and_return true
        AWS::S3::Bucket.stub!(:find).and_return true
        AWS::S3::S3Object.stub!(:store).and_return true
      end

      it "should have 'environment' as a prereq" do
        @rake[@task_name].prerequisites.should include("environment")
      end
      
      it "should establish an AWS S3 connection" do
        AWS::S3::Base.should_receive(:establish_connection!).once
        @rake[@task_name].invoke()
      end
      
      it "should check to make sure the bucket for search reports exists" do
        AWS::S3::Bucket.should_receive(:find).with(AWS_BUCKET_NAME).once
        @rake[@task_name].invoke()
      end
      
      context "when the reports bucket does not exist" do
        before do
          AWS::S3::Bucket.stub!(:find).and_raise "Can't find bucket"
          AWS::S3::Bucket.stub!(:create).and_return true
        end
        
        it "should create the bucket if it doesn't exist" do
          AWS::S3::Bucket.should_receive(:create).with(AWS_BUCKET_NAME).once
          @rake[@task_name].invoke()
        end
      end
      
      context "report generation" do
        it "should default to yesterday, and produce reports for both English and Spanish locales (30K/4K results respectively), as well as all affiliates" do
          %w{en es}.each do |locale|
            Query.should_receive(:top_queries).with(Date.yesterday.beginning_of_month.beginning_of_day, Date.yesterday.end_of_month.end_of_day, locale, 'usasearch.gov', locale == 'en' ? 30000 : 4000, true).once.and_return @fake_top_queries
          end
          @affiliate_names.each do |affiliate_name|
            Query.should_receive(:top_queries).with(Date.yesterday.beginning_of_month.beginning_of_day, Date.yesterday.end_of_month.end_of_day, 'en', affiliate_name, 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke()
        end
      
        it "should generate all reports for the date specified" do
          day = Date.today
          %w{en es}.each do |locale|
            Query.should_receive(:top_queries).with(day.beginning_of_month.beginning_of_day, day.end_of_month.end_of_day, locale, 'usasearch.gov', locale == 'en' ? 30000 : 4000, true).once.and_return @fake_top_queries
          end
          @affiliate_names.each do |affiliate_name|
            Query.should_receive(:top_queries).with(day.beginning_of_month.beginning_of_day, day.end_of_month.end_of_day, 'en', affiliate_name, 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke(day.to_s)        
        end
      
        it "should skip usasearch.gov reports when the generate_usasearch parameter is set to false" do
          day = Date.yesterday
          @affiliate_names.each do |affiliate_name|
            Query.should_receive(:top_queries).with(day.beginning_of_month.beginning_of_day, day.end_of_month.end_of_day, 'en', affiliate_name, 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke(day.to_s, false)
        end
      
        it "should skip affiliate report generation if the generate_affiliate parameter is set to false" do
          day = Date.yesterday
          %w{en es}.each do |locale|
            Query.should_receive(:top_queries).with(day.beginning_of_month.beginning_of_day, day.end_of_month.end_of_day, locale, 'usasearch.gov', locale == 'en' ? 30000 : 4000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke(day.to_s, true, false)        
        end
      
        it "should upload the generated csv for each locale to S3 with a filename corresponding to the date specified" do
          %w{en es}.each do |locale|
            AWS::S3::S3Object.should_receive(:store).with("reports/#{locale}_top_queries_#{Date.yesterday.strftime('%Y%m')}.csv", @csv_output, AWS_BUCKET_NAME)
          end
          Query.stub!(:top_queries).and_return @fake_top_queries
          @affiliate_names.each do |affiliate_name|
            AWS::S3::S3Object.should_receive(:store).with("reports/#{affiliate_name}_top_queries_#{Date.yesterday.strftime('%Y%m')}.csv", @csv_output, AWS_BUCKET_NAME)
          end
          @rake[@task_name].invoke()
        end
      end
    end
    
    describe "usasearch:reports:generate_daily_top_queries" do
      before do
        @task_name = "usasearch:reports:generate_daily_top_queries"
        AWS::S3::Base.stub!(:establish_connection).and_return true
        AWS::S3::Bucket.stub!(:find).and_return true
        AWS::S3::S3Object.stub(:store).and_return true
      end

      it "should have 'environment' as a prereq" do
        @rake[@task_name].prerequisites.should include("environment")
      end
      
      it "should establish an AWS S3 connection" do
        AWS::S3::Base.should_receive(:establish_connection!).once
        @rake[@task_name].invoke()
      end
      
      it "should check to make sure the bucket for search reports exists" do
        AWS::S3::Bucket.should_receive(:find).with(AWS_BUCKET_NAME).once
        @rake[@task_name].invoke()
      end
      
      context "when the reports bucket does not exist" do
        before do
          AWS::S3::Bucket.stub!(:find).and_raise "Can't find bucket"
          AWS::S3::Bucket.stub!(:create).and_return true
        end
        
        it "should create the bucket if it doesn't exist" do
          AWS::S3::Bucket.should_receive(:create).with(AWS_BUCKET_NAME).once
          @rake[@task_name].invoke()
        end
      end
      
      context "report generation" do        
        it "should default to yesterday, and produce reports for both English and Spanish locales (1k each), as well as all affiliates" do
          %w{en es}.each do |locale|
            Query.should_receive(:top_queries).with(Date.yesterday.beginning_of_day, Date.yesterday.end_of_day, locale, 'usasearch.gov', 1000, true).once.and_return @fake_top_queries
          end
          @affiliate_names.each do |affiliate_name|
            Query.should_receive(:top_queries).with(Date.yesterday.beginning_of_day, Date.yesterday.end_of_day, 'en', affiliate_name, 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke()
        end
      
        it "should generate all reports for the date specified" do
          day = Date.today
          %w{en es}.each do |locale|
            Query.should_receive(:top_queries).with(day.beginning_of_day, day.end_of_day, locale, 'usasearch.gov', 1000, true).once.and_return @fake_top_queries
          end
          @affiliate_names.each do |affiliate_name|
            Query.should_receive(:top_queries).with(day.beginning_of_day, day.end_of_day, 'en', affiliate_name, 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke(day.to_s)        
        end
      
        it "should skip usasearch.gov reports when the generate_usasearch parameter is set to false" do
          day = Date.yesterday
          @affiliate_names.each do |affiliate_name|
            Query.should_receive(:top_queries).with(day.beginning_of_day, day.end_of_day, 'en', affiliate_name, 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke(day.to_s, false)
        end
      
        it "should skip affiliate report generation if the generate_affiliate parameter is set to false" do
          day = Date.yesterday
          %w{en es}.each do |locale|
            Query.should_receive(:top_queries).with(day.beginning_of_day, day.end_of_day, locale, 'usasearch.gov', 1000, true).once.and_return @fake_top_queries
          end
          @rake[@task_name].invoke(day.to_s, true, false)        
        end
      
        it "should upload the generated csv for each locale to S3 with a filename corresponding to the date specified" do
          %w{en es}.each do |locale|
            AWS::S3::S3Object.should_receive(:store).with("reports/#{locale}_top_queries_#{Date.yesterday.strftime('%Y%m%d')}.csv", @csv_output, AWS_BUCKET_NAME)
          end
          Query.stub!(:top_queries).and_return @fake_top_queries
          @affiliate_names.each do |affiliate_name|
            AWS::S3::S3Object.should_receive(:store).with("reports/#{affiliate_name}_top_queries_#{Date.yesterday.strftime('%Y%m%d')}.csv", @csv_output, AWS_BUCKET_NAME)
          end
          @rake[@task_name].invoke()
        end
      end
    end 
  end
end