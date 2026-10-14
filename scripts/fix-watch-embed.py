from pathlib import Path
p = Path('TrafficVisionCompanion.xcodeproj/project.pbxproj')
s = p.read_text()
# XcodeGen prior to watchOS/Xcode 26 placement update: move only Watch embed phase to PlugIns.
import re
s = re.sub(r'(\/\* Embed Watch Content \*\/ = \{.*?dstPath = )"\$\(CONTENTS_FOLDER_PATH\)/Watch"(;.*?dstSubfolderSpec = )16;', r'\1""\2 13;', s, flags=re.S)
p.write_text(s)
