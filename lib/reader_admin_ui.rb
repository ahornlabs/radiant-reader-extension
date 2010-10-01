module ReaderAdminUI

 def self.included(base)
   base.class_eval do

      attr_accessor :reader, :message, :reader_setting
      alias_method :readers, :reader
      alias_method :messages, :message
      alias_method :reader_settings, :reader_setting

      def load_reader_extension_regions
        reader = load_default_reader_regions
        message = load_default_message_regions
        reader_setting = load_default_reader_setting_regions
      end

      def load_default_regions_with_reader
        load_default_regions_without_reader
        load_reader_extension_regions
      end
      alias_method_chain :load_default_regions, :reader

    protected

      def load_default_reader_regions
        returning OpenStruct.new do |reader|
          reader.edit = Radiant::AdminUI::RegionSet.new do |edit|
            edit.main.concat %w{edit_header edit_form}
            edit.form.concat %w{edit_name edit_email edit_username edit_password edit_description edit_notes}
            edit.form_bottom.concat %w{edit_timestamp edit_buttons}
          end
          reader.index = Radiant::AdminUI::RegionSet.new do |index|
            index.thead.concat %w{title_header description_header modify_header}
            index.tbody.concat %w{title_cell description_cell modify_cell}
            index.bottom.concat %w{buttons}
          end
          reader.remove = reader.index
          reader.new = reader.edit
        end
      end

      def load_default_reader_setting_regions
        returning OpenStruct.new do |reader_settings|
          reader_settings.index = Radiant::AdminUI::RegionSet.new do |index|
            index.settings.concat %w{registration site sender}
            index.messages.concat %w{administration}
          end
        end
      end

      def load_default_message_regions
        returning OpenStruct.new do |message|
          message.edit = Radiant::AdminUI::RegionSet.new do |edit|
            edit.main.concat %w{edit_header edit_form edit_footer}
            edit.form.concat %w{edit_subject edit_body}
            edit.form_bottom.concat %w{edit_timestamp edit_buttons}
          end
          message.new = message.edit
        end
      end
    end
  end
end

