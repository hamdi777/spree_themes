module Spree
  class Theme < Spree::Base

    DEFAULT_NAME = %w(default)
    DEFAULT_STATE = 'drafted'
    TEMPLATE_FILE_CONTENT_TYPE = 'application/zip'
    STATES = %w(drafted compiled published)
    THEMES_PATH = File.join(Rails.root, 'public', 'vinsol_spree_themes')
    CURRENT_THEME_PATH = File.join(THEMES_PATH, 'current')
    ASSET_CACHE_PATH = File.join(Rails.root, 'tmp', 'cache')

    has_one_attached :template_file, storage: :filesystem,
                                      path: 'public/system/spree/themes/:filename'

    ## VALIDATIONS ##
    validates_attachment :template_file, presence: true,
                                         content_type: { content_type: TEMPLATE_FILE_CONTENT_TYPE }
    do_not_validate_attachment_file_type :template_file

    validates :name, presence: true,
                     uniqueness: { case_sensitive: false }
    validates :state, inclusion: { in: STATES }

    # FIX_ME_PG:- check for atleast one published theme.
    # validate :ensure_atleast_one_published_theme, if: :state_changed?, unless: :published?

    ## ASSOCIATIONS ##
    has_many :themes_templates, dependent: :destroy

    ## CALLBACKS ##
    before_validation :set_name, if: :template_file?
    before_validation :set_state, unless: :state?
    after_commit :extract_template_zip_file, on: :create
    # before_destroy :ensure_not_published, prepend: true
    after_destroy :delete_from_file_system

    # FIX_ME_PG:- Need to have default state to compiled when uploading theme. Set state after zip file extraction.
    # after_create :set_state_to_compile

    ## SCOPES ##
    scope :published, -> { where(state: 'published') }
    scope :default, -> { where(name: DEFAULT_NAME) }

    alias_method :templates, :themes_templates

    self.whitelisted_ransackable_attributes = %w( name state )

    ## STATE MACHINES ##
    state_machine initial: :drafted do
      before_transition drafted: :compiled do |theme, transition|
        begin
          theme.assets_precompile
          theme.update_cache_timestamp
        rescue Exception => e
          theme.errors.add(:base, e)
        end
      end

      before_transition compiled: :published do |theme, transition|
        begin
          theme.remove_current_theme
          theme.apply_new_theme
          theme.remove_cache
          theme.update_cache_timestamp
        rescue Exception => e
          theme.errors.add(:base, e)
        end
      end

      event :draft do
        transition from: [:published, :compiled], to: :drafted
      end

      event :compile do
        transition from: :drafted, to: :compiled
      end

      event :publish do
        transition from: [:compiled, :drafted], to: :published
      end
    end

    def assets_precompile
      AssetsPrecompilerService.new(self).minify
    end

    def remove_current_theme
      Spree::Theme.published.each(&:draft)
      File.delete(CURRENT_THEME_PATH) if File.exist?(CURRENT_THEME_PATH)
    end

    def apply_new_theme
      source_path = File.join(THEMES_PATH, name)
      FileUtils.ln_sf(source_path, CURRENT_THEME_PATH)
      AssetsPrecompilerService.new(self).copy_assets
    end

    def open_preview
      precompile_assets = AssetsPrecompilerService.new(self)
      precompile_assets.minify
      precompile_assets.copy_preview_assets
      remove_cache
      # update_cache_timestamp
    end

    def close_preview
      remove_cache
      # update_cache_timestamp
    end

    def update_cache_timestamp
      Rails.cache.write(Spree::ThemesTemplate::CacheResolver.cache_key, Time.current)
    end

    def remove_cache
      FileUtils.remove_dir(ASSET_CACHE_PATH) if File.exists?(ASSET_CACHE_PATH)
    end

    private

      # def ensure_atleast_one_published_theme
      #   errors.add(:base, Spree.t('models.theme.minimum_active_error')) unless Spree::Theme.published.one?
      # end

      def set_name
        self.name = File.basename(template_file_file_name, File.extname(template_file_file_name))
      end

      def set_state
        self.state = DEFAULT_STATE
      end

      def extract_template_zip_file
        ZipFileExtractor.new(template_file.path, self).extract
      end

      def delete_from_file_system
        source_dir = File.join(THEMES_PATH, name)

        # This makes sure that the directory exists when deleting the theme.
        Dir.mkdir(source_dir) unless Dir.exists?(source_dir)
        FileUtils.remove_dir(source_dir)
      end

      def ensure_not_published
        if published?
          errors.add(:base, Spree.t('models.theme.no_destory_error'))
          throw(:abort)
        end
      end

      # def set_state_to_compile
      #   self.compile!
      # end

  end
end
