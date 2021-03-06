module ActiveMerchant
  module Billing
    class TargetpayIdealGateway < Gateway
      
      # url will be completed below
      URL = "https://www.targetpay.com/ideal/"
      
      def initialize(options={})
        requires!(options, :rtlo)
        @options = options
        super
      end
      
      def setup_purchase(money, options)
        requires!(options, :bank, :description, :reporturl, :returnurl)
        
        raise ArgumentError.new("Amount should be >= EUR 1,00")     if money < 100
        raise ArgumentError.new("Amount should be <= EUR 10000,00") if money > 1000000
        raise ArgumentError.new("Description should =~ /^[0-9A-Z]{1,32}$/i") if !(options[:description] =~ /^[0-9A-Z\ ]{1,32}$/i)

        @response = build_response_start(commit('start', {
          :amount      => money,
          :bank        => options[:bank],
          :description => CGI::escape(options[:description] || ""),
          :reporturl   => options[:reporturl],
          :returnurl   => options[:returnurl],
          :rtlo        => @options[:rtlo]
        }))
      end
      
      def redirect_url_for(token)
        @response.url if @response.token == token
      end
      
      def details_for(token)
        build_response_check(commit('check', {
          :once  => "1",
          :rtlo  => @options[:rtlo],
          :test  => ActiveMerchant::Billing::Base.test? ? "1" : "0",
          :trxid => token
        }))
      end
      
      private
      
      def commit(action, parameters)
        url   = URL + action + "?#{parameters.collect { |k,v| "#{k}=#{v}" }.join("&") }"
        uri   = URI.parse(url)
        http  = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.get(uri.request_uri).body
      end
      
      def build_response_start(response)
        vars = {}
        message = response
        success = false
        if response[0..5] == "000000"
          success = true
          args = response[7..-1].split("|")
          vars[:transactionid] = args[0]
          vars[:url] = args[1]
        end
        TargetpayIdealStartResponse.new(success, message, vars)
      end
      
      def build_response_check(response)
        message = response
        success = false
        if response[0..5] == "000000"
          success = true
        end        
        TargetpayIdealCheckResponse.new(success, message)
      end      
    end
  end
end
