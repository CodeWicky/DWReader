Pod::Spec.new do |s|
s.name = 'DWReader'
s.version = '0.0.0.22'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = '尝试写一个阅读器核心。Try to build a reader core.'
s.homepage = 'https://github.com/CodeWicky/DWReader'
s.authors = { 'codeWicky' => 'codewicky@163.com' }
s.source = { :git => 'https://github.com/CodeWicky/DWReader.git', :tag => s.version.to_s }
s.requires_arc = true
s.ios.deployment_target = '7.0'
s.source_files = 'DWReader/*'
s.frameworks = 'UIKit'

end
