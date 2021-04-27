before_dying {
  %w(rpick_guild_info_parser_hook
     rpick_inventory_parser_hook
     rpick_toolkit_parser_hook
     rpick_broken_pick_parser_hook
     rpick_box_parser_hook).each do |h|
    DownstreamHook.remove(h)
  end

  if @picker && !@picker.settings[:speech_and_misc][:remove_armor].empty? && @armor_removed
    waitrt?
    fput "get ##{@picker.inventory[:worn_armor][:id]}"
    fput "wear ##{@picker.inventory[:worn_armor][:id]}"
  end
}

def kick_off_workflow(picker, script, ancillary)

  session_settings = {
    always_use_vaalin: script.vars.include?('v'),
    start_with_copper: script.vars.include?('c'),
    loot_from_ground: script.vars.include?('loot'),
    relock_boxes: script.vars.include?('relock'),
    disarm_only: script.vars.include?('disarm'),
    workflow: script.vars[1..-1].select{|v| %(worker other ground self).include?(v) }.first || 'self'
  }

  picker.session_settings = session_settings

  picker.clear_hands
  ancillary.preflight_check if picker.settings[:speech_and_misc][:perform_preflight_check]

  if picker.settings[:speech_and_misc][:remove_armor] && picker.inventory[:worn_armor].any?
    fput "remove ##{picker.inventory[:worn_armor][:id]}"
    waitrt?
    fput "stow ##{picker.inventory[:worn_armor][:id]}"
    @armor_removed = true
  end


  ancillary.calibrate_calipers if picker.settings[:lock_handling][:calibrate_calipers_on_start]

  workflow      = case session_settings[:workflow]
                  when 'worker'
                    Rpick::Workflows::LocksmithPoolBoxes.new(picker, script)
                  when 'other'
                    Rpick::Workflows::CustomerBoxes.new(picker, script)
                  when 'ground'
                    Rpick::Workflows::GroundBoxes.new(picker, script)
                  else
                    Rpick::Workflows::OwnBoxes.new(picker, script)
                  end

  workflow.run
end

# Entry point

if script.vars[1] == 'setup'
  Rpick::Setup.run
  exit
end

@picker = Rpick::Picker.new(UserVars.rpick)
@ancillary = Rpick::AncillaryActions.new(@picker, script)

case script.vars[1]
when 'buy'
  fput "stow all"
  @ancillary.refill_toolkit
when 'calibrate'
  fput "stow all"
  @ancillary.calibrate_calipers
when 'repair'
  fput "stow all"
  @ancillary.repair_lockpicks
when 'debug'
  @ancillary.pick_test
else
  fput "stow all"
  kick_off_workflow(@picker, script, @ancillary)
end
