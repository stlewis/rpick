output = ""
files = [
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
File.write('rpick_unified.lic', output)
