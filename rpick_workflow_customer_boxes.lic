module Rpick
  module Workflows
    class CustomerBoxes < Workflow
      def run
        @ancillary = AncillaryActions.new(@picker, @script)
        @picker.clear_hands
        @picker.say_ready_for_boxes
        while true do
          get_box
          if @current_box

            @picker.clear_hands([@current_box.id])

            handle_box ? return_open_box : return_locked_box

            if @picker.wild_measure_miss && @picker.settings[:lock_handling][:calibrate_on_wild_miss]
              echo "Badly mis-measured the last lock. Calibrating calipers"
              @ancillary.calibrate_calipers
            end
          end
        end
      end

      def get_box # obtain a box to work on
        echo "Waiting for customer box"
        res = dothistimeout "accept", 2, Dictionary.box_accepted_regex

        if res =~ Dictionary.box_accepted_regex
          @current_customer = GameObj.pcs.find{|c| c.name == $1 }
          @current_box = GameObj.left_hand && GameObj.left_hand.noun =~ /#{$2}/ ? GameObj.left_hand : GameObj.right_hand
          return true
        end

        while line = get
          if line =~ Dictionary.box_offered_regex
            fput "accept"
            @current_customer = GameObj.pcs.find{|c| c.name == $1 }
            @current_box = GameObj.left_hand && GameObj.left_hand.noun =~ /#{$2}/ ? GameObj.left_hand : GameObj.right_hand
            break
          end
        end
      end

      def return_open_box # return a succesfully handled box
        dothis "give ##{@current_box.id} to ##{@current_customer.id}", /has accepted your offer/
      end

      def return_locked_box # return a box that could not be successfully handled
        @picker.say_cant_open_box
        return_open_box
      end
    end
  end
end
