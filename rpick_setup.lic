module Rpick
  class Setup
    class << self
      def run
        UserVars.rpick ||= Hash.new
        window_action = nil

        Gtk.queue  {
          @builder = Gtk::Builder.new
          file = "#{$lich_dir}scripts#{File::Separator}#{File::Separator}rpick.ui"

          if !File.exist?(file)
            Script.run('repository', 'download rpick.ui')
            wait_while { running?('repository') }
          end

          @builder.add_from_file(file)

          about_buffer = @builder.get_object('about-text-buffer')
          markup = about_buffer.text
          about_buffer.text = ''
          about_buffer.insert_markup(about_buffer.start_iter, markup)

          window = @builder.get_object("rpick-settings-window")
          close_button = @builder.get_object('cancel-button')
          save_button = @builder.get_object('save-settings-button')

          close_button.signal_connect('clicked') do
            window_action = :closed
            window.destroy
          end

          save_button.signal_connect('clicked') do
            save_settings
            window_action = :saved
            window.destroy
            echo "rpick settings saved"
          end

          window.signal_connect('delete_event') do
            window_action = :closed
            window.destroy
          end

          load_settings_in_ui

          window.show_all
        }

        wait_while { window_action.nil? }
      end

      def load_settings_in_ui
        settings = UserVars.rpick
        # Load Lockpick settings
        @builder.get_object('use-store-bought-lockpicks').active = settings[:lockpicks][:use_store_bought_lockpicks]
        @builder.get_object('copper-lockpicks').text = settings[:lockpicks][:copper].join(', ')
        @builder.get_object('brass-lockpicks').text = settings[:lockpicks][:brass].join(', ')
        @builder.get_object('steel-lockpicks').text = settings[:lockpicks][:steel].join(', ')
        @builder.get_object('gold-lockpicks').text = settings[:lockpicks][:gold].join(', ')
        @builder.get_object('silver-lockpicks').text = settings[:lockpicks][:silver].join(', ')
        @builder.get_object('mithril-lockpicks').text = settings[:lockpicks][:mithril].join(', ')
        @builder.get_object('ora-lockpicks').text = settings[:lockpicks][:ora].join(', ')
        @builder.get_object('glaes-lockpicks').text = settings[:lockpicks][:glaes].join(', ')
        @builder.get_object('laje-lockpicks').text = settings[:lockpicks][:laje].join(', ')
        @builder.get_object('vultite-lockpicks').text = settings[:lockpicks][:vultite].join(', ')
        @builder.get_object('rolaren-lockpicks').text = settings[:lockpicks][:rolaren].join(', ')
        @builder.get_object('veniom-lockpicks').text = settings[:lockpicks][:veniom].join(', ')
        @builder.get_object('invar-lockpicks').text = settings[:lockpicks][:invar].join(', ')
        @builder.get_object('alum-lockpicks').text = settings[:lockpicks][:alum].join(', ')
        @builder.get_object('golvern-lockpicks').text = settings[:lockpicks][:golvern].join(', ')
        @builder.get_object('kelyn-lockpicks').text = settings[:lockpicks][:kelyn].join(', ')
        @builder.get_object('vaalin-lockpicks').text = settings[:lockpicks][:vaalin].join(', ')

        # Load Containers & Equipment Settings
        @builder.get_object('loot-container').text = settings[:containers_and_equipment][:loot_container].strip
        @builder.get_object('lockpick-container').text = settings[:containers_and_equipment][:lockpick_container].strip
        @builder.get_object('broken-lockpick-container').text = settings[:containers_and_equipment][:broken_lockpick_container].strip
        @builder.get_object('locksmith-container').text = settings[:containers_and_equipment][:locksmith_container].strip
        @builder.get_object('wedge-container').text = settings[:containers_and_equipment][:wedge_container].strip
        @builder.get_object('scarab-container').text = settings[:containers_and_equipment][:scarab_container].strip
        @builder.get_object('scale-trap-weapon-container').text = settings[:containers_and_equipment][:scale_trap_weapon_container].strip
        @builder.get_object('scale-trap-weapon').text = settings[:containers_and_equipment][:scale_trap_weapon].strip
        @builder.get_object('auto-bundle-vials').active = settings[:containers_and_equipment][:auto_bundle_vials]
        @builder.get_object('auto-refill-toolkit').active = settings[:containers_and_equipment][:auto_refill_toolkit]

        # Load Lock Handling Settings
        @builder.get_object('picking-trick').text = settings[:lock_handling][:picking_trick].strip
        @builder.get_object('max-lock').text = settings[:lock_handling][:max_lock].to_s
        @builder.get_object('lockpick-switch-roll').text = settings[:lock_handling][:lockpick_switch_roll].to_s
        @builder.get_object('vaalin-switch-roll').text = settings[:lock_handling][:vaalin_switch_roll].to_s
        @builder.get_object('403-threshold').text = settings[:lock_handling][:threshold_403].to_s
        @builder.get_object('unpickable-box-action').active = ['Return', 'Unlock (407)', 'Wedge'].index(settings[:lock_handling][:unpickable_box_action].strip).to_i
        @builder.get_object('use-vaalin-when-fried').active = settings[:lock_handling][:use_vaalin_when_fried]
        @builder.get_object('use-calipers').active = settings[:lock_handling][:use_calipers]
        @builder.get_object('calibrate-calipers-on-start').active = settings[:lock_handling][:calibrate_calipers_on_start]
        @builder.get_object('calibrate-after').text = settings[:lock_handling][:calibrate_after].to_s
        @builder.get_object('calibrate-on-wild-miss').active = settings[:lock_handling][:calibrate_on_wild_miss]
        @builder.get_object('use-403').active = ['Never', 'When Necessary', 'At Threshold', 'Always'].index(settings[:lock_handling][:use_403].strip).to_i
        @builder.get_object('cancel-403').active = settings[:lock_handling][:cancel_403]
        @builder.get_object('always-407').active = settings[:lock_handling][:always_407]
        @builder.get_object('always-wedge-locked').active = settings[:lock_handling][:always_wedge_locked]
        @builder.get_object('maintain-205').active = settings[:lock_handling][:maintain_205]
        @builder.get_object('maintain-506').active = settings[:lock_handling][:maintain_506]

        # Load Trap Handling Settings
        @builder.get_object('max-trap').text = settings[:trap_handling][:max_trap].to_s
        @builder.get_object('detect-count').text = settings[:trap_handling][:detect_count].to_s
        @builder.get_object('scarab-disarm-count').text = settings[:trap_handling][:scarab_disarm_count].to_s
        @builder.get_object('always-wedge-plated').active = settings[:trap_handling][:always_wedge_plated]
        @builder.get_object('use-404').active = ['Never', 'When Necessary', 'At Threshold', 'Always'].index(settings[:trap_handling][:use_404].strip).to_i
        @builder.get_object('404-threshold').text = settings[:trap_handling][:threshold_404].to_s
        @builder.get_object('cancel-404').active = settings[:trap_handling][:cancel_404]
        @builder.get_object('always-408').active = settings[:trap_handling][:always_408]
        @builder.get_object('only-408-safe').active = settings[:trap_handling][:only_408_safe]
        @builder.get_object('maintain-402').active = settings[:trap_handling][:maintain_402]
        @builder.get_object('maintain-613').active = settings[:trap_handling][:maintain_613]
        @builder.get_object('maintain-1006').active = settings[:trap_handling][:maintain_1006]

        # Load Speech & Miscellaneous Settings
        @builder.get_object('scarab-found-speech').text = settings[:speech_and_misc][:scarab_found_speech].join('; ').to_s
        @builder.get_object('scarab-on-ground-speech').text = settings[:speech_and_misc][:scarab_on_ground_speech].join('; ').to_s
        @builder.get_object('scarab-safe-speech').text = settings[:speech_and_misc][:scarab_safe_speech].join('; ').to_s
        @builder.get_object('ready-for-boxes-speech').text = settings[:speech_and_misc][:ready_for_boxes_speech].join('; ').to_s
        @builder.get_object('cant-open-box-speech').text = settings[:speech_and_misc][:cant_open_box_speech].join('; ').to_s
        @builder.get_object('perform-preflight-check').active = settings[:speech_and_misc][:perform_preflight_check]
        @builder.get_object('remove-armor').text = settings[:speech_and_misc][:remove_armor].to_s
        @builder.get_object('lockpick-repair-limit').text = settings[:speech_and_misc][:lockpick_repair_limit].to_s


        # Load Locksmith Pool Options
        @builder.get_object('tip-request').text = settings[:locksmith_pool][:tip_request].to_s
        @builder.get_object('tip-decrement').text = settings[:locksmith_pool][:tip_decrement].to_s
        @builder.get_object('minimum-tip').text = settings[:locksmith_pool][:minimum_tip].to_s
        @builder.get_object('max-critter-level').text = settings[:locksmith_pool][:max_critter_level].to_s
        @builder.get_object('lockpick-by-critter-level').active = settings[:locksmith_pool][:lockpick_by_critter_level]
        @builder.get_object('copper-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:copper][:min].to_s
        @builder.get_object('copper-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:copper][:max].to_s
        @builder.get_object('steel-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:steel][:min].to_s
        @builder.get_object('steel-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:steel][:max].to_s
        @builder.get_object('brass-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:brass][:min].to_s
        @builder.get_object('brass-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:brass][:max].to_s
        @builder.get_object('steel-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:steel][:min].to_s
        @builder.get_object('steel-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:steel][:max].to_s
        @builder.get_object('gold-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:gold][:min].to_s
        @builder.get_object('gold-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:gold][:max].to_s
        @builder.get_object('silver-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:silver][:min].to_s
        @builder.get_object('silver-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:silver][:max].to_s
        @builder.get_object('mithril-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:mithril][:min].to_s
        @builder.get_object('mithril-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:mithril][:max].to_s
        @builder.get_object('ora-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:ora][:min].to_s
        @builder.get_object('ora-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:ora][:max].to_s
        @builder.get_object('glaes-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:glaes][:min].to_s
        @builder.get_object('glaes-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:glaes][:max].to_s
        @builder.get_object('laje-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:laje][:min].to_s
        @builder.get_object('laje-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:laje][:max].to_s
        @builder.get_object('vultite-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:vultite][:min].to_s
        @builder.get_object('vultite-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:vultite][:max].to_s
        @builder.get_object('rolaren-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:rolaren][:min].to_s
        @builder.get_object('rolaren-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:rolaren][:max].to_s
        @builder.get_object('veniom-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:veniom][:min].to_s
        @builder.get_object('veniom-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:veniom][:max].to_s
        @builder.get_object('invar-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:invar][:min].to_s
        @builder.get_object('invar-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:invar][:max].to_s
        @builder.get_object('alum-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:alum][:min].to_s
        @builder.get_object('alum-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:alum][:max].to_s
        @builder.get_object('golvern-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:golvern][:min].to_s
        @builder.get_object('golvern-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:golvern][:max].to_s
        @builder.get_object('kelyn-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:kelyn][:min].to_s
        @builder.get_object('kelyn-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:kelyn][:max].to_s
        @builder.get_object('vaalin-min-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:vaalin][:min].to_s
        @builder.get_object('vaalin-max-critter-level').text = settings[:locksmith_pool][:lockpicks_by_critter_level][:vaalin][:max].to_s

        encumbrance_options = [
          'Never',
          'Light',
          'Somewhat',
          'Moderate',
          'Significant',
          'Heavy',
          'Very Heavy',
          'Extreme',
          'Overloaded'
        ]

        rest_at_options = [
          'Never',
          'Fresh and Clear',
          'Clear',
          'Muddled',
          'Becoming Numbed',
          'Numbed',
          'Must Rest'
        ]

        pick_at_options = [
          'Always',
          'Clear As A Bell',
          'Fresh And Clear',
          'Clear',
          'Muddled',
          'Becoming Numbed',
          'Numbed'
        ]
        @builder.get_object('deposit-silvers-when').active = encumbrance_options.index(settings[:locksmith_pool][:deposit_silvers_when]).to_i
        @builder.get_object('rest-at-state').active = rest_at_options.index(settings[:locksmith_pool][:rest_at_state]).to_i
        @builder.get_object('pick-at-state').active = pick_at_options.index(settings[:locksmith_pool][:pick_at_state]).to_i
      end

      def save_settings
        settings = UserVars.rpick
        settings[:lockpicks] ||= {}
        settings[:containers_and_equipment] ||= {}
        settings[:lock_handling] ||= {}
        settings[:trap_handling] ||= {}
        settings[:speech_and_misc] ||= {}
        settings[:locksmith_pool] ||= {}

        # Save Lockpicks settings
        settings[:lockpicks][:use_store_bought_lockpicks] = @builder.get_object('use-store-bought-lockpicks').active?
        settings[:lockpicks][:copper] = @builder.get_object('copper-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:brass] = @builder.get_object('brass-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:steel] = @builder.get_object('steel-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:gold] = @builder.get_object('gold-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:silver] = @builder.get_object('silver-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:mithril] = @builder.get_object('mithril-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:ora] = @builder.get_object('ora-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:glaes] = @builder.get_object('glaes-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:laje] = @builder.get_object('laje-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:vultite] = @builder.get_object('vultite-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:rolaren] = @builder.get_object('rolaren-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:veniom] = @builder.get_object('veniom-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:invar] = @builder.get_object('invar-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:alum] = @builder.get_object('alum-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:golvern] = @builder.get_object('golvern-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:kelyn] = @builder.get_object('kelyn-lockpicks').text.split(',').map(&:strip)
        settings[:lockpicks][:vaalin] = @builder.get_object('vaalin-lockpicks').text.split(',').map(&:strip)

        # Save Container & Equipment Settings
        settings[:containers_and_equipment][:loot_container] = @builder.get_object('loot-container').text.strip
        settings[:containers_and_equipment][:lockpick_container] = @builder.get_object('lockpick-container').text.strip
        settings[:containers_and_equipment][:broken_lockpick_container] = @builder.get_object('broken-lockpick-container').text.strip
        settings[:containers_and_equipment][:locksmith_container] = @builder.get_object('locksmith-container').text.strip
        settings[:containers_and_equipment][:wedge_container] = @builder.get_object('wedge-container').text.strip
        settings[:containers_and_equipment][:scarab_container] = @builder.get_object('scarab-container').text.strip
        settings[:containers_and_equipment][:scale_trap_weapon_container] = @builder.get_object('scale-trap-weapon-container').text.strip
        settings[:containers_and_equipment][:scale_trap_weapon] = @builder.get_object('scale-trap-weapon').text.strip
        settings[:containers_and_equipment][:auto_bundle_vials] = @builder.get_object('auto-bundle-vials').active?

        # Save Lock Handling Settings
        settings[:lock_handling][:picking_trick] = @builder.get_object('picking-trick').text.strip
        settings[:lock_handling][:max_lock] = @builder.get_object('max-lock').text.strip.to_i
        settings[:lock_handling][:lockpick_switch_roll] = @builder.get_object('lockpick-switch-roll').text.strip.to_i
        settings[:lock_handling][:vaalin_switch_roll] = @builder.get_object('vaalin-switch-roll').text.strip.to_i
        settings[:lock_handling][:threshold_403] = @builder.get_object('403-threshold').text.strip.to_i
        settings[:lock_handling][:unpickable_box_action] = @builder.get_object('unpickable-box-action').active_text
        settings[:lock_handling][:use_vaalin_when_fried] = @builder.get_object('use-vaalin-when-fried').active?
        settings[:lock_handling][:use_calipers] = @builder.get_object('use-calipers').active?
        settings[:lock_handling][:calibrate_calipers_on_start] = @builder.get_object('calibrate-calipers-on-start').active?
        settings[:lock_handling][:calibrate_after] = @builder.get_object('calibrate-after').text.strip.to_i
        settings[:lock_handling][:calibrate_on_wild_miss] = @builder.get_object('calibrate-on-wild-miss').active?
        settings[:lock_handling][:use_403] = @builder.get_object('use-403').active_text
        settings[:lock_handling][:cancel_403] = @builder.get_object('cancel-403').active?
        settings[:lock_handling][:always_407] = @builder.get_object('always-407').active?
        settings[:lock_handling][:always_wedge_locked] = @builder.get_object('always-wedge-locked').active?
        settings[:lock_handling][:maintain_205] = @builder.get_object('maintain-205').active?
        settings[:lock_handling][:maintain_506] = @builder.get_object('maintain-506').active?

        # Save Trap Handling Settings
        settings[:trap_handling][:max_trap] = @builder.get_object('max-trap').text.strip.to_i
        settings[:trap_handling][:detect_count] = @builder.get_object('detect-count').text.strip.to_i
        settings[:trap_handling][:scarab_disarm_count] = @builder.get_object('scarab-disarm-count').text.strip.to_i
        settings[:trap_handling][:always_wedge_plated] = @builder.get_object('always-wedge-plated').active?
        settings[:trap_handling][:use_404] = @builder.get_object('use-404').active_text
        settings[:trap_handling][:threshold_404] = @builder.get_object('404-threshold').text.strip.to_i
        settings[:trap_handling][:cancel_404] = @builder.get_object('cancel-404').active?
        settings[:trap_handling][:always_408] = @builder.get_object('always-408').active?
        settings[:trap_handling][:only_408_safe] = @builder.get_object('only-408-safe').active?
        settings[:trap_handling][:maintain_402] = @builder.get_object('maintain-402').active?
        settings[:trap_handling][:maintain_613] = @builder.get_object('maintain-613').active?
        settings[:trap_handling][:maintain_1006] = @builder.get_object('maintain-1006').active?

        # Save Speech & Miscellaneous Settings
        settings[:speech_and_misc][:scarab_found_speech] = @builder.get_object('scarab-found-speech').text.split(';').map(&:strip)
        settings[:speech_and_misc][:scarab_on_ground_speech] = @builder.get_object('scarab-on-ground-speech').text.split(';').map(&:strip)
        settings[:speech_and_misc][:scarab_safe_speech] = @builder.get_object('scarab-safe-speech').text.split(';').map(&:strip)
        settings[:speech_and_misc][:ready_for_boxes_speech] = @builder.get_object('ready-for-boxes-speech').text.split(';').map(&:strip)
        settings[:speech_and_misc][:cant_open_box_speech] = @builder.get_object('cant-open-box-speech').text.split(';').map(&:strip)
        settings[:speech_and_misc][:perform_preflight_check] = @builder.get_object('perform-preflight-check').active?
        settings[:speech_and_misc][:remove_armor] = @builder.get_object('remove-armor').text.strip
        settings[:speech_and_misc][:lockpick_repair_limit] = @builder.get_object('lockpick-repair-limit').text.strip.to_i

        # Locksmith Pool Settings

        settings[:locksmith_pool][:tip_request] = @builder.get_object('tip-request').text.to_i
        settings[:locksmith_pool][:tip_decrement] = @builder.get_object('tip-decrement').text.to_i
        settings[:locksmith_pool][:minimum_tip] = @builder.get_object('minimum-tip').text.to_i
        settings[:locksmith_pool][:max_critter_level] = @builder.get_object('max-critter-level').text.to_i

        settings[:locksmith_pool][:lockpick_by_critter_level] = @builder.get_object('lockpick-by-critter-level').active?
        settings[:locksmith_pool][:lockpicks_by_critter_level] = {
          copper: {},
          brass: {},
          steel: {},
          gold: {},
          silver: {},
          mithril: {},
          ora: {},
          glaes: {},
          laje: {},
          vultite: {},
          rolaren: {},
          veniom: {},
          invar: {},
          alum: {},
          golvern: {},
          kelyn: {},
          vaalin: {}
        }

        settings[:locksmith_pool][:lockpicks_by_critter_level][:copper][:min] = @builder.get_object('copper-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:copper][:max] = @builder.get_object('copper-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:brass][:min] = @builder.get_object('brass-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:brass][:max] = @builder.get_object('brass-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:steel][:min] = @builder.get_object('steel-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:steel][:max] = @builder.get_object('steel-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:gold][:min] = @builder.get_object('gold-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:gold][:max] = @builder.get_object('gold-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:silver][:min] = @builder.get_object('silver-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:silver][:max] = @builder.get_object('silver-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:mithril][:min] = @builder.get_object('mithril-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:mithril][:max] = @builder.get_object('mithril-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:ora][:min] = @builder.get_object('ora-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:ora][:max] = @builder.get_object('ora-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:glaes][:min] = @builder.get_object('glaes-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:glaes][:max] = @builder.get_object('glaes-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:laje][:min] = @builder.get_object('laje-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:laje][:max] = @builder.get_object('laje-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:vultite][:min] = @builder.get_object('vultite-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:vultite][:max] = @builder.get_object('vultite-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:rolaren][:min] = @builder.get_object('rolaren-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:rolaren][:max] = @builder.get_object('rolaren-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:veniom][:min] = @builder.get_object('veniom-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:veniom][:max] = @builder.get_object('veniom-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:invar][:min] = @builder.get_object('invar-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:invar][:max] = @builder.get_object('invar-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:alum][:min] = @builder.get_object('alum-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:alum][:max] = @builder.get_object('alum-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:golvern][:min] = @builder.get_object('golvern-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:golvern][:max] = @builder.get_object('golvern-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:kelyn][:min] = @builder.get_object('kelyn-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:kelyn][:max] = @builder.get_object('kelyn-max-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:vaalin][:min] = @builder.get_object('vaalin-min-critter-level').text.to_i
        settings[:locksmith_pool][:lockpicks_by_critter_level][:vaalin][:max] = @builder.get_object('vaalin-max-critter-level').text.to_i

        settings[:locksmith_pool][:deposit_silvers_when] = @builder.get_object('deposit-silvers-when').active_text
        settings[:locksmith_pool][:rest_at_state] = @builder.get_object('rest-at-state').active_text
        settings[:locksmith_pool][:pick_at_state] = @builder.get_object('pick-at-state').active_text
      end
    end
  end
end
