OpenProject::Application.configure do
  next unless OpenProject::Configuration.lookbook_enabled?

  config.lookbook.project_name = "OpenProject Lookbook"
  config.lookbook.project_logo = Rails.root.join('app/assets/images/icon_logo_white.svg').read
  config.lookbook.ui_favicon = Rails.root.join('app/assets/images/icon_logo.svg').read
  config.lookbook.page_paths = [Rails.root.join("spec/components/docs/").to_s]
  # Show notes first, all other panels next
  config.lookbook.component_paths << Primer::ViewComponents::Engine.root.join("app", "components").to_s
  config.view_component.preview_paths << Primer::ViewComponents::Engine.root.join("previews").to_s
  config.lookbook.preview_inspector.drawer_panels = [:notes, "*"]
  config.lookbook.ui_theme = "blue"

  SecureHeaders::Configuration.named_append(:lookbook) do
    {
      script_src: %w('unsafe-eval' 'unsafe-inline') # rubocop:disable Lint/PercentStringArray
    }
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  module LookbookCspExtender
    extend ActiveSupport::Concern

    included do
      before_action do
        use_content_security_policy_named_append :lookbook
      end
    end
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock

  Rails.application.reloader.to_prepare do
    [
      Lookbook::ApplicationController,
      Lookbook::PreviewController,
      Lookbook::PreviewsController,
      Lookbook::PageController,
      Lookbook::PagesController,
      Lookbook::InspectorController,
      Lookbook::EmbedsController
    ].each do |controller|
      controller.include LookbookCspExtender
    end
  end
end
