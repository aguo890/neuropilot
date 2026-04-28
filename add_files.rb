require 'xcodeproj'

project_path = 'NeuroPilotApp/NeuroPilot/NeuroPilot.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

group = project.main_group.find_subpath(File.join('NeuroPilot'), true)

files_to_add = [
  'NeuroPilotApp/NeuroPilot/NeuroPilot/Models.swift',
  'NeuroPilotApp/NeuroPilot/NeuroPilot/TelemetryClient.swift',
  'NeuroPilotApp/NeuroPilot/NeuroPilot/Pipeline.swift'
]

files_to_add.each do |file_path|
  file_ref = group.new_reference(File.basename(file_path))
  target.add_file_references([file_ref])
end

project.save
