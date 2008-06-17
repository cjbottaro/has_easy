module Izzle
  module HasEasy
    module AssocationExtension
      
      def save
        do_save(false)
      end
      
      def save!
        do_save(true)
      end
      
      def []=(name, value)
        proxy_owner.set_has_easy_thing(proxy_reflection.name, name, value)
      end
      
      def [](name)
        proxy_owner.get_has_easy_thing(proxy_reflection.name, name)
      end
      
      private
      
      def do_save(with_bang)
        proxy_target.each do |thing|
          thing.model_cache = proxy_owner
          with_bang ? thing.save! : thing.save
        end
      end
      
    end
  end
end