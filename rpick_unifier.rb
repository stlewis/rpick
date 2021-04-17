output = ""

header = <<-EOL
=begin
    --------------------------------------------------------------------------------
    Title: Rpick
    Date: 04/12/2021
    Author: Slyverin

    About:
      Locksmithing script
      More information is available in the Setup UI.

    Use:
      Run ;rpick setup then look at the Help & About tab.

    Updates :
      - 04/12/2021 Released (alpha)
    --------------------------------------------------------------------------------
=end
  EOL

output << header

[
  'rpick_dictionary',
  'rpick_inventory_management',
  'rpick_picker',
  'rpick_ancillary_actions',
  'rpick_lock_handler',
  'rpick_trap_handler',
  'rpick_workflow',
  'rpick_workflow_customer_boxes',
  'rpick_workflow_ground_boxes',
  'rpick_workflow_locksmithpool_boxes',
  'rpick_workflow_own_boxes',
  'rpick_setup',
  'rpick'
].each do |file|
  path = "./#{file}.lic"

  contents = File.read(path)
  output << contents
  output << "\n\n"
end
path = File.expand_path(File.dirname(__FILE__) + '/../scripts/rpick.lic')
ui_path = File.expand_path(File.dirname(__FILE__) + '/../scripts/rpick.ui')
File.write(path, output)
File.write(ui_path, File.read('./Rpick.ui'))
