class Multilang::TranslationsController < Multilang::ApplicationController

  add_breadcrumb 'Translations', :translations_path
  before_action :set_searcher, only: [:index]

  def index
    @keys            = @searcher.translation_keys
    @translation_key = Multilang::TranslationKey.new
  end

  def update
    @translation = find_translation params[:id]
    @translation.update_attributes value:        params[:value],
                                   is_completed: true
    respond_to do |format|
      format.html { redirect_to translations_url }
      format.js
    end
  end

  def change_status
    @translation = find_translation(params[:id])
    @translation.change_status
    respond_to do |format|
      format.html { redirect_to translations_url }
      format.js
    end
  end
end