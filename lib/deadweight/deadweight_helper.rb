class Deadweight
  module DeadweightHelper
    def self.tokenize_selector(selector)
      tokenizer = Nokogiri::CSS::Tokenizer.new
      tokenizer.scan_setup(selector)
      tokens = []
      while token = tokenizer.next_token
        tokens << token
      end
      tokens
    end

    def tokenize_selector(*args)
      DeadweightHelper.tokenize_selector(*args)
    end
  end
end