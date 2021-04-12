output = ""
[
  'rpick_dictionary',
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

