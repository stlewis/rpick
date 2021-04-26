module Rpick
  # This module contains the various picking workflows. Picking one's own boxes, picking for a customer, picking from the locksmith pool, picking an 'arbitrary'
  # box, etc.
  #
  # The primary difference with each workflow is how the picker obtains and returns boxes, but the LocksmithPool workflow also contains
  # logic for handling silver accumulation, low supplies, etc.
  # This class contains the various actions that the script is capable of performing that are not directly related to picking a box. Repairing picks,
  # calibrating calipers, creating wedges, refilling toolkits and so on.
  module Workflows
    class Workflow
      def initialize(picker, script)
        @picker = picker
        @script = script
      end

      def run
        raise "#{self.class.name} does not implement run"
      end

      def get_box # obtain a box to work on
        raise "#{self.class.name} does not implement get_box"
      end

      def handle_box
        trap_handler = TrapHandler.new(@current_box, @picker)
        lock_handler = LockHandler.new(@current_box, @picker, @box_info)

        if trap_handler.detect_and_disarm
          return true if @picker.session_settings[:disarm_only]

          pick_result = trap_handler.box_is_open? ? true : lock_handler.handle_lock
          return pick_result
        else
          return false
        end
      end


      def return_open_box # return a succesfully handled box
        raise "#{self.class.name} does not implement return_open_box"
      end

      def return_locked_box # return a box that could not be successfully handled
        raise "#{self.class.name} does not implement return_locked_box"
      end
    end
  end
end
