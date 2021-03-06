require 'pathname'

module Multilang
  class Import

    attr_accessor :path

    def initialize(path = nil, force = false)
      @force = force
      if path.present?
        pn    = Pathname.new(path)
        @path = pn.relative? ? pn.realpath : pn
      end
    end

    def run
      if @path.present?
        if @path.directory?
          @path.each_child do |file_path|
            process_file(file_path.realpath) if file_path.file?
          end
        else
          process_file(@path)
        end
      else
        I18n.load_path.each do |file_path|
          process_file(file_path)
        end
      end
    end

    class Redis < self
      def process_file(file_path)
        locale   = locale_by_file(file_path)
        hash = YAML::load_file(file_path)[locale]
        return if hash.nil?
        I18n.backend.store_translations(locale, hash)
      end
    end

    private

    def process_file(file_path)
      locale   = locale_by_file(file_path)
      language = Language.locale(locale).first
      return if language.blank?
      hash = parse(file_path, locale)
      hash.each do |key, value|
        next if value.is_a? Array
        translation_key = TranslationKey.key(key).first

        if translation_key.blank?
          translation_key = TranslationKey.create! key: key
          translation_key.create_translations
        end

        translation = Translation
          .where(multilang_language_id:        language.id,
                 multilang_translation_key_id: translation_key.id)
          .first

        if translation.value.blank? || @force
          translation.value        = value
          translation.is_completed = false
          translation.save!
        end
      end
    end

    def parse(file_path, locale)
      yml = YAML::load_file(file_path)
      convert_hash(yml[locale])
    end

    def convert_hash(hash, path='')
      hash.each_with_object({}) do |(k, v), ret|
        key = path + k

        if v.is_a? Hash
          ret.merge! convert_hash(v, key + '.')
        else
          ret[key] = v
        end
      end
    end

    def locale_by_file(file_path)
      locale = File.basename(file_path, '.yml')
      if locale.scan('.').present?
        locale = File.extname(locale).gsub('.', '')
      end
      locale
    end
  end
end
