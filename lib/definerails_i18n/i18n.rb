module DefineRails
  module Internationalization
    extend ActiveSupport::Concern

    module ClassMethods

      def use_definerails_i18n(options = {})
        options = {
          setup_default_url_options: true,
          setup_locale_on_before_action: true,
          enable_cookie_support: true,
          cookie_name: :hl,
          enable_param_support: true,
          param_name: :hl
        }.merge(options)

        if options[:enable_cookie_support]
          cattr_accessor :ui_language_cookie_name
          self.ui_language_cookie_name = options[:cookie_name].to_sym
        end

        if options[:enable_param_support]
          cattr_accessor :ui_language_param_name
          self.ui_language_param_name = options[:param_name].to_sym

          if options[:setup_default_url_options]
            include DefineRails::Internationalization::Method_DefaultUrlOptions
          end

        end

        if options[:setup_locale_on_before_action]
          before_action :definerails__set_locale
        end

        include DefineRails::Internationalization::Methods
      end

    end

    module Method_DefaultUrlOptions
      extend ActiveSupport::Concern

      module ClassMethods

        def default_url_options(options={})
          self.add_language_to_default_url_options options
        end

      end
    end

    module Methods
      extend ActiveSupport::Concern

      module ClassMethods

        def add_language_to_default_url_options(options={})
          options.merge(self.ui_language_param_name => I18n.locale)
        end

      end

      def definerails__set_locale
        new_locale = definerails__get_user_locale || I18n.default_locale

        I18n.locale = new_locale

        lang_cookie_name = self.ui_language_cookie_name
        if lang_cookie_name
          cookie_lang = cookies[lang_cookie_name]
          cookies[lang_cookie_name] = {
            value: new_locale,
            expires: 1.year.from_now
          } if cookie_lang != new_locale
        end
      end

      def definerails__get_user_locale
        available_langs = I18n.available_locales

        lang_cookie_name = self.ui_language_cookie_name
        lang_param_name = self.ui_language_param_name

        params_lang = params[lang_param_name] if lang_param_name
        cookie_lang = cookies[lang_cookie_name] if lang_cookie_name

        if params_lang and available_langs.include?(params_lang.to_sym)
          params_lang
        elsif cookie_lang and available_langs.include?(cookie_lang.to_sym)
          cookie_lang
        else
          http_accept_language.compatible_language_from available_langs
        end
      end

    end

  end
end

ActionController::Base.send :include, DefineRails::Internationalization
